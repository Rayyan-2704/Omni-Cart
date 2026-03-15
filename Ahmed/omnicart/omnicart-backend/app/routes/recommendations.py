from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.models.recommendation import Recommendation
from app.models.product import Product
from app.models.review import Review
from app.models.order import Order
from app.models.order_item import OrderItem
from app.middleware.role_required import role_required

recommendations_bp = Blueprint("recommendations", __name__)


# ─────────────────────────────────────────────
# GET /api/recommendations
# Customer only — get their recommendations
# ─────────────────────────────────────────────
@recommendations_bp.route("/", methods=["GET"])
@jwt_required()
@role_required("customer")
def get_recommendations():
    customer_id = int(get_jwt_identity())

    recs = Recommendation.query.filter_by(customer_id=customer_id)\
                               .order_by(Recommendation.score.desc()).all()

    data = []
    for r in recs:
        d = r.to_dict()
        d["product"] = r.product.to_dict() if r.product else None
        data.append(d)

    # If no stored recommendations, return top-rated products as fallback
    if not data:
        top_products = Product.query.filter_by(is_active=True)\
                                    .order_by(Product.rating.desc()).limit(5).all()
        return jsonify({
            "recommendations": [],
            "fallback":        [p.to_dict() for p in top_products],
            "message":         "No personalized recommendations yet. Showing top rated products."
        }), 200

    return jsonify({
        "recommendations": data,
        "total":           len(data)
    }), 200


# ─────────────────────────────────────────────
# GET /api/recommendations/trending
# Public — trending products based on orders + ratings
# ─────────────────────────────────────────────
@recommendations_bp.route("/trending", methods=["GET"])
def get_trending():
    # Most ordered products
    from sqlalchemy import func
    trending = db.session.query(
        Product,
        func.sum(OrderItem.quantity).label("total_sold")
    ).join(OrderItem, Product.product_id == OrderItem.product_id)\
     .filter(Product.is_active == True)\
     .group_by(Product.product_id)\
     .order_by(func.sum(OrderItem.quantity).desc())\
     .limit(10).all()

    data = []
    for product, total_sold in trending:
        d = product.to_dict()
        d["total_sold"] = int(total_sold)
        data.append(d)

    return jsonify({"trending": data, "total": len(data)}), 200


# ─────────────────────────────────────────────
# GET /api/recommendations/similar/<product_id>
# Public — similar products (same category, similar price)
# ─────────────────────────────────────────────
@recommendations_bp.route("/similar/<int:product_id>", methods=["GET"])
def get_similar(product_id):
    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    price_range = float(product.price) * 0.4  # ±40% price range

    similar = Product.query.filter(
        Product.category_id == product.category_id,
        Product.product_id  != product_id,
        Product.is_active   == True,
        Product.price.between(
            float(product.price) - price_range,
            float(product.price) + price_range
        )
    ).order_by(Product.rating.desc()).limit(5).all()

    return jsonify({
        "product_id": product_id,
        "similar":    [p.to_dict() for p in similar],
        "total":      len(similar)
    }), 200


# ─────────────────────────────────────────────
# POST /api/recommendations
# Admin only — manually add a recommendation
# Body: { customer_id, product_id, score, reason }
# ─────────────────────────────────────────────
@recommendations_bp.route("/", methods=["POST"])
@jwt_required()
@role_required("admin")
def add_recommendation():
    data = request.get_json()

    required = ["customer_id", "product_id", "score"]
    missing  = [f for f in required if data.get(f) is None]
    if missing:
        return jsonify({"error": f"Missing: {', '.join(missing)}"}), 400

    rec = Recommendation(
        customer_id = data["customer_id"],
        product_id  = data["product_id"],
        score       = data["score"],
        reason      = data.get("reason", "Recommended by admin")
    )
    db.session.add(rec)
    db.session.commit()

    return jsonify({
        "message":        "Recommendation added",
        "recommendation": rec.to_dict()
    }), 201


# ─────────────────────────────────────────────
# POST /api/recommendations/explain
# Customer only — GPT-4 explains a recommendation
# Body: { product_id }
# ─────────────────────────────────────────────
@recommendations_bp.route("/explain", methods=["POST"])
@jwt_required()
@role_required("customer")
def explain_recommendation():
    from app.models.customer import Customer
    from app.services.openai_service import generate_recommendation_reason

    customer_id = int(get_jwt_identity())
    data        = request.get_json()
    product_id  = data.get("product_id")

    if not product_id:
        return jsonify({"error": "product_id is required"}), 400

    customer = Customer.query.get(customer_id)
    product  = Product.query.get(product_id)

    if not product:
        return jsonify({"error": "Product not found"}), 404

    reason = generate_recommendation_reason(
        customer_name=customer.name,
        product_name=product.name,
        category=product.category.name if product.category else "General"
    )

    # Save to recommendations table
    rec = Recommendation(
        customer_id=customer_id,
        product_id=product_id,
        score=0.85,
        reason=reason
    )
    db.session.add(rec)
    db.session.commit()

    return jsonify({
        "product":      product.to_dict(),
        "reason":       reason,
        "generated_by": "GPT-4"
    }), 200
