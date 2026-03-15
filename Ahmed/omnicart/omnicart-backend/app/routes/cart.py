from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.product import Product
from app.middleware.role_required import role_required

cart_bp = Blueprint("cart", __name__)

# In-memory cart (Phase 5 will use DB or Redis)
_carts = {}

@cart_bp.route("/", methods=["GET"])
@jwt_required()
@role_required("customer")
def get_cart():
    customer_id = str(get_jwt_identity())
    cart = _carts.get(customer_id, [])
    total = sum(item["price"] * item["quantity"] for item in cart)
    return jsonify({"cart": cart, "total": round(total, 2), "count": len(cart)}), 200

@cart_bp.route("/add", methods=["POST"])
@jwt_required()
@role_required("customer")
def add_to_cart():
    customer_id = str(get_jwt_identity())
    data        = request.get_json()
    product_id  = data.get("product_id")
    quantity    = data.get("quantity", 1)

    product = Product.query.get(product_id)
    if not product or not product.is_active:
        return jsonify({"error": "Product not found"}), 404

    cart = _carts.setdefault(customer_id, [])
    for item in cart:
        if item["product_id"] == product_id:
            item["quantity"] += quantity
            return jsonify({"message": "Cart updated", "cart": cart}), 200

    cart.append({
        "product_id": product_id,
        "name":       product.name,
        "price":      float(product.price),
        "quantity":   quantity
    })
    return jsonify({"message": "Added to cart", "cart": cart}), 200

@cart_bp.route("/remove/<int:product_id>", methods=["DELETE"])
@jwt_required()
@role_required("customer")
def remove_from_cart(product_id):
    customer_id = str(get_jwt_identity())
    cart = _carts.get(customer_id, [])
    _carts[customer_id] = [i for i in cart if i["product_id"] != product_id]
    return jsonify({"message": "Item removed", "cart": _carts[customer_id]}), 200

@cart_bp.route("/clear", methods=["DELETE"])
@jwt_required()
@role_required("customer")
def clear_cart():
    customer_id = str(get_jwt_identity())
    _carts[customer_id] = []
    return jsonify({"message": "Cart cleared"}), 200
