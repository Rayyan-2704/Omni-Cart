from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.models.product import Product
from app.models.category import Category
from app.models.vendor import Vendor
from app.middleware.role_required import role_required

products_bp = Blueprint("products", __name__)


# ─────────────────────────────────────────────
# GET /api/products
# Public — list all active products
# Query params: ?category_id=&vendor_id=&min_price=&max_price=&search=&sort=&page=&per_page=
# ─────────────────────────────────────────────
@products_bp.route("/", methods=["GET"])
def get_products():
    query = Product.query.filter_by(is_active=True)

    # Filters
    category_id = request.args.get("category_id", type=int)
    vendor_id   = request.args.get("vendor_id",   type=int)
    min_price   = request.args.get("min_price",   type=float)
    max_price   = request.args.get("max_price",   type=float)
    search      = request.args.get("search",      type=str)
    sort        = request.args.get("sort",        type=str, default="newest")

    if category_id:
        query = query.filter_by(category_id=category_id)
    if vendor_id:
        query = query.filter_by(vendor_id=vendor_id)
    if min_price is not None:
        query = query.filter(Product.price >= min_price)
    if max_price is not None:
        query = query.filter(Product.price <= max_price)
    if search:
        query = query.filter(
            Product.name.ilike(f"%{search}%") |
            Product.description.ilike(f"%{search}%") |
            Product.brand.ilike(f"%{search}%")
        )

    # Sorting
    if sort == "price_asc":
        query = query.order_by(Product.price.asc())
    elif sort == "price_desc":
        query = query.order_by(Product.price.desc())
    elif sort == "rating":
        query = query.order_by(Product.rating.desc())
    else:  # newest
        query = query.order_by(Product.created_at.desc())

    # Pagination
    page     = request.args.get("page",     type=int, default=1)
    per_page = request.args.get("per_page", type=int, default=12)
    per_page = min(per_page, 50)  # cap at 50

    paginated = query.paginate(page=page, per_page=per_page, error_out=False)

    return jsonify({
        "products":    [p.to_dict() for p in paginated.items],
        "total":       paginated.total,
        "page":        paginated.page,
        "per_page":    paginated.per_page,
        "total_pages": paginated.pages
    }), 200


# ─────────────────────────────────────────────
# GET /api/products/my
# Vendor only — get their own products
# ─────────────────────────────────────────────
@products_bp.route("/my", methods=["GET"])
@jwt_required()
@role_required("vendor")
def get_my_products():
    vendor_id = int(get_jwt_identity())
    products  = Product.query.filter_by(vendor_id=vendor_id).all()
    return jsonify({"products": [p.to_dict() for p in products]}), 200


# ─────────────────────────────────────────────
# GET /api/products/<id>
# Public — single product detail
# ─────────────────────────────────────────────
@products_bp.route("/<int:product_id>", methods=["GET"])
def get_product(product_id):
    product = Product.query.get(product_id)
    if not product or not product.is_active:
        return jsonify({"error": "Product not found"}), 404

    data = product.to_dict()
    # Include vendor and category info
    data["vendor"]   = product.vendor.to_dict()   if product.vendor   else None
    data["category"] = product.category.to_dict() if product.category else None
    # Include reviews summary
    reviews = product.reviews
    if reviews:
        data["avg_rating"]    = round(sum(r.rating for r in reviews) / len(reviews), 2)
        data["review_count"]  = len(reviews)
    else:
        data["avg_rating"]   = 0
        data["review_count"] = 0

    return jsonify({"product": data}), 200


# ─────────────────────────────────────────────
# GET /api/products/category/<id>
# Public — products by category
# ─────────────────────────────────────────────
@products_bp.route("/category/<int:category_id>", methods=["GET"])
def get_by_category(category_id):
    category = Category.query.get(category_id)
    if not category:
        return jsonify({"error": "Category not found"}), 404

    products = Product.query.filter_by(
        category_id=category_id, is_active=True
    ).order_by(Product.rating.desc()).all()

    return jsonify({
        "category": category.to_dict(),
        "products": [p.to_dict() for p in products],
        "total":    len(products)
    }), 200


# ─────────────────────────────────────────────
# POST /api/products
# Vendor only — create a product
# ─────────────────────────────────────────────
@products_bp.route("/", methods=["POST"])
@jwt_required()
@role_required("vendor")
def create_product():
    vendor_id = int(get_jwt_identity())
    data      = request.get_json()

    required = ["name", "price", "category_id"]
    missing  = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    if float(data["price"]) <= 0:
        return jsonify({"error": "Price must be greater than 0"}), 400

    category = Category.query.get(data["category_id"])
    if not category:
        return jsonify({"error": "Category not found"}), 404

    product = Product(
        vendor_id   = vendor_id,
        category_id = data["category_id"],
        name        = data["name"].strip(),
        description = data.get("description"),
        price       = data["price"],
        stock_qty   = data.get("stock_qty", 0),
        brand       = data.get("brand"),
        is_active   = True
    )
    db.session.add(product)
    db.session.commit()

    return jsonify({
        "message": "Product created successfully",
        "product": product.to_dict()
    }), 201


# ─────────────────────────────────────────────
# PUT /api/products/<id>
# Vendor only — update their own product
# ─────────────────────────────────────────────
@products_bp.route("/<int:product_id>", methods=["PUT"])
@jwt_required()
@role_required("vendor")
def update_product(product_id):
    vendor_id = int(get_jwt_identity())
    product   = Product.query.get(product_id)

    if not product:
        return jsonify({"error": "Product not found"}), 404
    if product.vendor_id != vendor_id:
        return jsonify({"error": "You can only edit your own products"}), 403

    data = request.get_json()
    product.name        = data.get("name",        product.name)
    product.description = data.get("description", product.description)
    product.price       = data.get("price",       product.price)
    product.stock_qty   = data.get("stock_qty",   product.stock_qty)
    product.brand       = data.get("brand",       product.brand)
    product.category_id = data.get("category_id", product.category_id)
    product.is_active   = data.get("is_active",   product.is_active)

    db.session.commit()
    return jsonify({
        "message": "Product updated successfully",
        "product": product.to_dict()
    }), 200


# ─────────────────────────────────────────────
# DELETE /api/products/<id>
# Vendor only — soft delete (deactivate)
# ─────────────────────────────────────────────
@products_bp.route("/<int:product_id>", methods=["DELETE"])
@jwt_required()
@role_required("vendor")
def delete_product(product_id):
    vendor_id = int(get_jwt_identity())
    product   = Product.query.get(product_id)

    if not product:
        return jsonify({"error": "Product not found"}), 404
    if product.vendor_id != vendor_id:
        return jsonify({"error": "You can only delete your own products"}), 403

    product.is_active = False  # soft delete
    db.session.commit()
    return jsonify({"message": "Product deactivated successfully"}), 200


# ─────────────────────────────────────────────
# POST /api/products/generate-description
# Vendor only — GPT-4 auto-generates product description
# Body: { name, category_id, price, brand }
# ─────────────────────────────────────────────
@products_bp.route("/generate-description", methods=["POST"])
@jwt_required()
@role_required("vendor")
def generate_description():
    data        = request.get_json()
    name        = data.get("name")
    category_id = data.get("category_id")
    price       = data.get("price", 0)
    brand       = data.get("brand", "")

    if not name or not category_id:
        return jsonify({"error": "name and category_id are required"}), 400

    category = Category.query.get(category_id)
    if not category:
        return jsonify({"error": "Category not found"}), 404

    from app.services.openai_service import generate_product_description
    description = generate_product_description(
        product_name=name,
        category=category.name,
        price=float(price),
        brand=brand
    )

    return jsonify({
        "description": description,
        "generated_by": "GPT-4"
    }), 200
