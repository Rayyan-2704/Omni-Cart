from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app import db
from app.models.customer import Customer
from app.models.vendor import Vendor
from app.models.product import Product
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.review import Review
from app.middleware.role_required import role_required
from sqlalchemy import func

admin_bp = Blueprint("admin", __name__)


# ─────────────────────────────────────────────
# GET /api/admin/stats
# Admin only — dashboard analytics
# ─────────────────────────────────────────────
@admin_bp.route("/stats", methods=["GET"])
@jwt_required()
@role_required("admin")
def get_stats():
    total_customers = Customer.query.filter_by(is_active=True).count()
    total_vendors   = Vendor.query.count()
    total_products  = Product.query.filter_by(is_active=True).count()
    total_orders    = Order.query.count()
    total_reviews   = Review.query.count()

    # Revenue from delivered orders
    delivered = Order.query.filter_by(status="delivered").all()
    total_revenue = sum(float(o.total_amount) for o in delivered)

    # Orders by status
    statuses      = ["pending", "confirmed", "shipped", "delivered", "cancelled"]
    orders_by_status = {}
    for s in statuses:
        orders_by_status[s] = Order.query.filter_by(status=s).count()

    # Top 5 products by order volume
    top_products = db.session.query(
        Product.name,
        func.sum(OrderItem.quantity).label("total_sold")
    ).join(OrderItem, Product.product_id == OrderItem.product_id)\
     .group_by(Product.product_id)\
     .order_by(func.sum(OrderItem.quantity).desc())\
     .limit(5).all()

    return jsonify({
        "summary": {
            "total_customers": total_customers,
            "total_vendors":   total_vendors,
            "total_products":  total_products,
            "total_orders":    total_orders,
            "total_reviews":   total_reviews,
            "total_revenue":   round(total_revenue, 2)
        },
        "orders_by_status": orders_by_status,
        "top_products": [
            {"name": name, "total_sold": int(sold)}
            for name, sold in top_products
        ]
    }), 200


# ─────────────────────────────────────────────
# GET /api/admin/customers
# Admin only — all customers
# ─────────────────────────────────────────────
@admin_bp.route("/customers", methods=["GET"])
@jwt_required()
@role_required("admin")
def get_customers():
    customers = Customer.query.order_by(Customer.created_at.desc()).all()
    return jsonify({
        "customers": [c.to_dict() for c in customers],
        "total":     len(customers)
    }), 200


# ─────────────────────────────────────────────
# PUT /api/admin/customers/<id>/toggle
# Admin only — activate/deactivate customer
# ─────────────────────────────────────────────
@admin_bp.route("/customers/<int:customer_id>/toggle", methods=["PUT"])
@jwt_required()
@role_required("admin")
def toggle_customer(customer_id):
    customer = Customer.query.get(customer_id)
    if not customer:
        return jsonify({"error": "Customer not found"}), 404
    customer.is_active = not customer.is_active
    db.session.commit()
    status = "activated" if customer.is_active else "deactivated"
    return jsonify({"message": f"Customer {status}", "customer": customer.to_dict()}), 200


# ─────────────────────────────────────────────
# GET /api/admin/vendors
# Admin only — all vendors
# ─────────────────────────────────────────────
@admin_bp.route("/vendors", methods=["GET"])
@jwt_required()
@role_required("admin")
def get_vendors():
    vendors = Vendor.query.order_by(Vendor.created_at.desc()).all()
    return jsonify({
        "vendors": [v.to_dict() for v in vendors],
        "total":   len(vendors)
    }), 200


# ─────────────────────────────────────────────
# PUT /api/admin/vendors/<id>/approve
# Admin only — approve or reject vendor
# ─────────────────────────────────────────────
@admin_bp.route("/vendors/<int:vendor_id>/approve", methods=["PUT"])
@jwt_required()
@role_required("admin")
def approve_vendor(vendor_id):
    vendor = Vendor.query.get(vendor_id)
    if not vendor:
        return jsonify({"error": "Vendor not found"}), 404
    vendor.is_approved = not vendor.is_approved
    db.session.commit()
    status = "approved" if vendor.is_approved else "revoked"
    return jsonify({"message": f"Vendor {status}", "vendor": vendor.to_dict()}), 200


# ─────────────────────────────────────────────
# GET /api/admin/orders
# Admin only — all orders with filters
# ─────────────────────────────────────────────
@admin_bp.route("/orders", methods=["GET"])
@jwt_required()
@role_required("admin")
def get_all_orders():
    status = request.args.get("status")
    query  = Order.query
    if status:
        query = query.filter_by(status=status)
    orders = query.order_by(Order.placed_at.desc()).all()
    result = []
    for o in orders:
        d = o.to_dict()
        d["customer_name"] = o.customer.name if o.customer else None
        d["item_count"]    = len(o.order_items)
        result.append(d)
    return jsonify({"orders": result, "total": len(result)}), 200


# ─────────────────────────────────────────────
# DELETE /api/admin/reviews/<id>
# Admin only — remove inappropriate review
# ─────────────────────────────────────────────
@admin_bp.route("/reviews/<int:review_id>", methods=["DELETE"])
@jwt_required()
@role_required("admin")
def delete_review(review_id):
    review = Review.query.get(review_id)
    if not review:
        return jsonify({"error": "Review not found"}), 404
    db.session.delete(review)
    db.session.commit()
    return jsonify({"message": "Review removed"}), 200
