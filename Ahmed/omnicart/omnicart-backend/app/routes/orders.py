from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product
from app.models.payment import Payment
from app.middleware.role_required import role_required

orders_bp = Blueprint("orders", __name__)


# ─────────────────────────────────────────────
# POST /api/orders
# Customer only — place a new order
# Body: { items: [{product_id, quantity}], payment_method }
# ─────────────────────────────────────────────
@orders_bp.route("/", methods=["POST"])
@jwt_required()
@role_required("customer")
def place_order():
    customer_id = int(get_jwt_identity())
    data        = request.get_json()

    items          = data.get("items", [])
    payment_method = data.get("payment_method", "cash")

    if not items:
        return jsonify({"error": "Order must have at least one item"}), 400

    if payment_method not in ["cash", "card", "bank_transfer", "wallet"]:
        return jsonify({"error": "Invalid payment method"}), 400

    total = 0
    order_items_to_create = []

    # Validate all items first before touching DB
    for item in items:
        product_id = item.get("product_id")
        quantity   = item.get("quantity", 1)

        if not product_id or quantity < 1:
            return jsonify({"error": "Each item needs product_id and quantity >= 1"}), 400

        product = Product.query.get(product_id)
        if not product or not product.is_active:
            return jsonify({"error": f"Product {product_id} not found or inactive"}), 404
        if product.stock_qty < quantity:
            return jsonify({"error": f"Insufficient stock for '{product.name}'. Available: {product.stock_qty}"}), 400

        subtotal = float(product.price) * quantity
        total   += subtotal
        order_items_to_create.append((product, quantity))

    # Create order
    order = Order(
        customer_id  = customer_id,
        total_amount = round(total, 2),
        status       = "pending"
    )
    db.session.add(order)
    db.session.flush()

    # Create order items + deduct stock
    for product, quantity in order_items_to_create:
        item = OrderItem(
            order_id   = order.order_id,
            product_id = product.product_id,
            quantity   = quantity,
            unit_price = product.price
        )
        db.session.add(item)
        product.stock_qty -= quantity  # deduct stock

    # Create payment record
    payment = Payment(
        order_id = order.order_id,
        amount   = round(total, 2),
        method   = payment_method,
        status   = "pending"
    )
    db.session.add(payment)
    db.session.commit()

    return jsonify({
        "message":  "Order placed successfully",
        "order_id": order.order_id,
        "total":    round(total, 2),
        "status":   order.status,
        "payment":  payment.to_dict()
    }), 201


# ─────────────────────────────────────────────
# GET /api/orders
# Customer — their own orders
# Admin — all orders
# ─────────────────────────────────────────────
@orders_bp.route("/", methods=["GET"])
@jwt_required()
def get_orders():
    claims = get_jwt()
    role   = claims.get("role")

    if role == "admin":
        orders = Order.query.order_by(Order.placed_at.desc()).all()
    elif role == "customer":
        customer_id = int(get_jwt_identity())
        orders = Order.query.filter_by(customer_id=customer_id)\
                            .order_by(Order.placed_at.desc()).all()
    else:
        return jsonify({"error": "Vendors cannot view orders this way"}), 403

    result = []
    for order in orders:
        o = order.to_dict()
        o["items"] = [item.to_dict() for item in order.order_items]
        result.append(o)

    return jsonify({"orders": result, "total": len(result)}), 200


# ─────────────────────────────────────────────
# GET /api/orders/<id>
# Customer (own) or Admin
# ─────────────────────────────────────────────
@orders_bp.route("/<int:order_id>", methods=["GET"])
@jwt_required()
def get_order(order_id):
    claims = get_jwt()
    role   = claims.get("role")
    order  = Order.query.get(order_id)

    if not order:
        return jsonify({"error": "Order not found"}), 404

    # Customers can only see their own orders
    if role == "customer" and order.customer_id != int(get_jwt_identity()):
        return jsonify({"error": "Access denied"}), 403

    if role == "vendor":
        return jsonify({"error": "Vendors cannot access this endpoint"}), 403

    data          = order.to_dict()
    data["items"] = []
    for item in order.order_items:
        i = item.to_dict()
        i["product_name"] = item.product.name if item.product else None
        data["items"].append(i)
    data["payment"]   = order.payment.to_dict() if order.payment else None
    data["customer"]  = order.customer.to_dict() if order.customer else None

    return jsonify({"order": data}), 200


# ─────────────────────────────────────────────
# PUT /api/orders/<id>/status
# Admin only — update order status
# Body: { status: "confirmed"|"shipped"|"delivered"|"cancelled" }
# ─────────────────────────────────────────────
@orders_bp.route("/<int:order_id>/status", methods=["PUT"])
@jwt_required()
@role_required("admin")
def update_order_status(order_id):
    order = Order.query.get(order_id)
    if not order:
        return jsonify({"error": "Order not found"}), 404

    data       = request.get_json()
    new_status = data.get("status")
    valid      = ["pending", "confirmed", "shipped", "delivered", "cancelled"]

    if new_status not in valid:
        return jsonify({"error": f"Status must be one of: {', '.join(valid)}"}), 400

    # If cancelling, restore stock
    if new_status == "cancelled" and order.status != "cancelled":
        for item in order.order_items:
            if item.product:
                item.product.stock_qty += item.quantity
        # Mark payment as failed
        if order.payment:
            order.payment.status = "failed"

    # If delivered, mark payment completed
    if new_status == "delivered" and order.payment:
        order.payment.status = "completed"
        from datetime import datetime
        order.payment.paid_at = datetime.utcnow()

    order.status = new_status
    db.session.commit()

    return jsonify({
        "message": f"Order status updated to '{new_status}'",
        "order":   order.to_dict()
    }), 200


# ─────────────────────────────────────────────
# GET /api/orders/vendor
# Vendor only — orders containing their products
# ─────────────────────────────────────────────
@orders_bp.route("/vendor", methods=["GET"])
@jwt_required()
@role_required("vendor")
def get_vendor_orders():
    vendor_id = int(get_jwt_identity())

    # Get all order items where the product belongs to this vendor
    items = OrderItem.query.join(Product)\
                    .filter(Product.vendor_id == vendor_id).all()

    # Group by order
    orders_map = {}
    for item in items:
        oid = item.order_id
        if oid not in orders_map:
            orders_map[oid] = {
                "order_id":    item.order.order_id,
                "status":      item.order.status,
                "placed_at":   item.order.placed_at.isoformat(),
                "items":       []
            }
        orders_map[oid]["items"].append({
            "product_name": item.product.name,
            "quantity":     item.quantity,
            "unit_price":   float(item.unit_price),
            "subtotal":     float(item.unit_price) * item.quantity
        })

    return jsonify({
        "orders": list(orders_map.values()),
        "total":  len(orders_map)
    }), 200
