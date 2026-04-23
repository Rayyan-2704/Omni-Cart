from app import db
from datetime import datetime

class Order(db.Model):
    __tablename__ = "orders"
    order_id     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    customer_id  = db.Column(db.Integer, db.ForeignKey("customers.customer_id"), nullable=False)
    status       = db.Column(
        db.Enum("pending", "confirmed", "shipped", "delivered", "cancelled"),
        default="pending"
    )
    total_amount = db.Column(db.Numeric(10, 2), nullable=False)
    placed_at    = db.Column(db.DateTime, default=datetime.utcnow)

    customer    = db.relationship("Customer",  back_populates="orders")
    order_items = db.relationship("OrderItem", back_populates="order")
    payment     = db.relationship("Payment",   back_populates="order", uselist=False)

    def to_dict(self):
        return {
            "order_id":     self.order_id,
            "customer_id":  self.customer_id,
            "total_amount": float(self.total_amount),
            "status":       self.status,
            "placed_at":    self.placed_at.isoformat()
        }
