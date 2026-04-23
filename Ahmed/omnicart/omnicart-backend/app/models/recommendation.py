from app import db
from datetime import datetime

class Recommendation(db.Model):
    __tablename__ = "recommendations"
    rec_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id  = db.Column(db.Integer, db.ForeignKey("customers.customer_id"), nullable=False)
    product_id   = db.Column(db.Integer, db.ForeignKey("products.product_id"), nullable=False)
    score        = db.Column(db.Numeric(5, 4), nullable=False)
    explanation  = db.Column(db.Text)
    generated_at = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", back_populates="recommendations")
    product  = db.relationship("Product")

    def to_dict(self):
        return {
            "rec_id":       self.rec_id,
            "customer_id":  self.customer_id,
            "product_id":   self.product_id,
            "score":        float(self.score),
            "explanation":  self.explanation,
            "generated_at": self.generated_at.isoformat()
        }
