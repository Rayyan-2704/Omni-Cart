from app import db
from datetime import datetime

class Customer(db.Model):
    __tablename__ = "customers"
    customer_id    = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name           = db.Column(db.String(100), nullable=False)
    email          = db.Column(db.String(100), unique=True, nullable=False)
    password_hash  = db.Column(db.String(255), nullable=False)
    phone          = db.Column(db.String(20))
    address        = db.Column(db.Text)
    date_of_birth  = db.Column(db.Date)
    is_active      = db.Column(db.Boolean, default=True)
    created_at     = db.Column(db.DateTime, default=datetime.utcnow)

    orders          = db.relationship("Order",          back_populates="customer")
    reviews         = db.relationship("Review",         back_populates="customer")
    recommendations = db.relationship("Recommendation", back_populates="customer")
    cart_items      = db.relationship("Cart",           back_populates="customer")

    def to_dict(self):
        return {
            "customer_id":   self.customer_id,
            "name":          self.name,
            "email":         self.email,
            "phone":         self.phone,
            "address":       self.address,
            "date_of_birth": str(self.date_of_birth) if self.date_of_birth else None,
            "is_active":     self.is_active,
            "created_at":    self.created_at.isoformat()
        }
