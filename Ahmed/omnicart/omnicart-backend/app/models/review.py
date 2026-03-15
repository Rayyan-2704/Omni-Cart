from app import db
from datetime import datetime

class Review(db.Model):
    __tablename__ = "reviews"
    review_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id     = db.Column(db.Integer, db.ForeignKey("customers.customer_id"), nullable=False)
    product_id      = db.Column(db.Integer, db.ForeignKey("products.product_id"), nullable=False)
    rating          = db.Column(db.Integer, nullable=False)
    comment         = db.Column(db.Text)
    sentiment_score = db.Column(db.Float, default=0.0)
    created_at      = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", back_populates="reviews")
    product  = db.relationship("Product",  back_populates="reviews")

    def to_dict(self):
        return {
            "review_id": self.review_id, "customer_id": self.customer_id,
            "product_id": self.product_id, "rating": self.rating,
            "comment": self.comment, "sentiment_score": self.sentiment_score,
            "created_at": self.created_at.isoformat()
        }
