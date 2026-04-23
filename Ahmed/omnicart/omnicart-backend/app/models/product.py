from app import db
from datetime import datetime

class Product(db.Model):
    __tablename__ = "products"
    product_id  = db.Column(db.Integer, primary_key=True, autoincrement=True)
    vendor_id   = db.Column(db.Integer, db.ForeignKey("vendors.vendor_id"), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey("categories.category_id"), nullable=False)
    name        = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    price       = db.Column(db.Numeric(10, 2), nullable=False)
    stock_qty   = db.Column(db.Integer, default=0)
    brand       = db.Column(db.String(100))
    is_active   = db.Column(db.Boolean, default=True)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

    vendor   = db.relationship("Vendor",   back_populates="products")
    category = db.relationship("Category", back_populates="products")
    reviews  = db.relationship("Review",   back_populates="product")

    def to_dict(self):
        return {
            "product_id":  self.product_id,
            "vendor_id":   self.vendor_id,
            "category_id": self.category_id,
            "name":        self.name,
            "description": self.description,
            "price":       float(self.price),
            "stock_qty":   self.stock_qty,
            "brand":       self.brand,
            "is_active":   self.is_active,
            "created_at":  self.created_at.isoformat()
        }
