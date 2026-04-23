from app import db
from datetime import datetime

class Cart(db.Model):
    __tablename__ = "cart"
    cart_id     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.customer_id"), nullable=False)
    product_id  = db.Column(db.Integer, db.ForeignKey("products.product_id"), nullable=False)
    quantity    = db.Column(db.Integer, nullable=False, default=1)
    added_at    = db.Column(db.DateTime, default=datetime.utcnow)

    customer = db.relationship("Customer", back_populates="cart_items")
    product  = db.relationship("Product")

    def to_dict(self):
        return {
            "cart_id":    self.cart_id,
            "customer_id":self.customer_id,
            "product_id": self.product_id,
            "quantity":   self.quantity,
            "added_at":   self.added_at.isoformat()
        }
