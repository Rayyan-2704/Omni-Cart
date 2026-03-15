from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.models.review import Review
from app.models.product import Product
from app.models.order import Order
from app.models.order_item import OrderItem
from app.middleware.role_required import role_required

reviews_bp = Blueprint("reviews", __name__)


# ─────────────────────────────────────────────
# GET /api/reviews/product/<id>
# Public — all reviews for a product
# ─────────────────────────────────────────────
@reviews_bp.route("/product/<int:product_id>", methods=["GET"])
def get_product_reviews(product_id):
    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    reviews = Review.query.filter_by(product_id=product_id)\
                          .order_by(Review.created_at.desc()).all()

    data = []
    for r in reviews:
        d = r.to_dict()
        d["customer_name"] = r.customer.name if r.customer else "Anonymous"
        data.append(d)

    avg = round(sum(r.rating for r in reviews) / len(reviews), 2) if reviews else 0

    return jsonify({
        "product_id":   product_id,
        "product_name": product.name,
        "reviews":      data,
        "total":        len(data),
        "avg_rating":   avg
    }), 200


# ─────────────────────────────────────────────
# POST /api/reviews
# Customer only — leave a review
# Body: { product_id, rating, comment }
# ─────────────────────────────────────────────
@reviews_bp.route("/", methods=["POST"])
@jwt_required()
@role_required("customer")
def create_review():
    customer_id = int(get_jwt_identity())
    data        = request.get_json()

    product_id = data.get("product_id")
    rating     = data.get("rating")
    comment    = data.get("comment", "")

    if not product_id or rating is None:
        return jsonify({"error": "product_id and rating are required"}), 400

    if not (1 <= int(rating) <= 5):
        return jsonify({"error": "Rating must be between 1 and 5"}), 400

    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    # Check if already reviewed
    existing = Review.query.filter_by(
        customer_id=customer_id, product_id=product_id
    ).first()
    if existing:
        return jsonify({"error": "You have already reviewed this product"}), 409

    # Simple sentiment score based on rating (Phase 3 will use TextBlob)
    sentiment_map = {5: 0.95, 4: 0.75, 3: 0.50, 2: 0.25, 1: 0.05}
    sentiment_score = sentiment_map.get(int(rating), 0.50)

    review = Review(
        customer_id     = customer_id,
        product_id      = product_id,
        rating          = int(rating),
        comment         = comment,
        sentiment_score = sentiment_score
    )
    db.session.add(review)

    # Update product avg rating
    all_reviews = Review.query.filter_by(product_id=product_id).all()
    all_ratings = [r.rating for r in all_reviews] + [int(rating)]
    product.rating = round(sum(all_ratings) / len(all_ratings), 2)

    db.session.commit()

    return jsonify({
        "message": "Review submitted successfully",
        "review":  review.to_dict()
    }), 201


# ─────────────────────────────────────────────
# PUT /api/reviews/<id>
# Customer only — edit their own review
# ─────────────────────────────────────────────
@reviews_bp.route("/<int:review_id>", methods=["PUT"])
@jwt_required()
@role_required("customer")
def update_review(review_id):
    customer_id = int(get_jwt_identity())
    review      = Review.query.get(review_id)

    if not review:
        return jsonify({"error": "Review not found"}), 404
    if review.customer_id != customer_id:
        return jsonify({"error": "You can only edit your own reviews"}), 403

    data   = request.get_json()
    rating = data.get("rating", review.rating)

    if not (1 <= int(rating) <= 5):
        return jsonify({"error": "Rating must be between 1 and 5"}), 400

    review.rating  = int(rating)
    review.comment = data.get("comment", review.comment)
    sentiment_map  = {5: 0.95, 4: 0.75, 3: 0.50, 2: 0.25, 1: 0.05}
    review.sentiment_score = sentiment_map.get(int(rating), 0.50)

    db.session.commit()
    return jsonify({"message": "Review updated", "review": review.to_dict()}), 200


# ─────────────────────────────────────────────
# DELETE /api/reviews/<id>
# Customer (own) or Admin
# ─────────────────────────────────────────────
@reviews_bp.route("/<int:review_id>", methods=["DELETE"])
@jwt_required()
def delete_review(review_id):
    claims      = get_jwt()
    role        = claims.get("role")
    review      = Review.query.get(review_id)

    if not review:
        return jsonify({"error": "Review not found"}), 404

    if role == "customer" and review.customer_id != int(get_jwt_identity()):
        return jsonify({"error": "You can only delete your own reviews"}), 403

    if role == "vendor":
        return jsonify({"error": "Vendors cannot delete reviews"}), 403

    db.session.delete(review)
    db.session.commit()
    return jsonify({"message": "Review deleted"}), 200


# ─────────────────────────────────────────────
# GET /api/reviews/my
# Customer only — their own reviews
# ─────────────────────────────────────────────
@reviews_bp.route("/my", methods=["GET"])
@jwt_required()
@role_required("customer")
def get_my_reviews():
    customer_id = int(get_jwt_identity())
    reviews     = Review.query.filter_by(customer_id=customer_id)\
                              .order_by(Review.created_at.desc()).all()
    data = []
    for r in reviews:
        d = r.to_dict()
        d["product_name"] = r.product.name if r.product else None
        data.append(d)
    return jsonify({"reviews": data, "total": len(data)}), 200
