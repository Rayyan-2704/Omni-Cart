from app import db

class OrderItem(db.Model):
    __tablename__ = "order_items"
    item_id    = db.Column(db.Integer, primary_key=True, autoincrement=True)
    order_id   = db.Column(db.Integer, db.ForeignKey("orders.order_id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.product_id"), nullable=False)
    quantity   = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2), nullable=False)

    order   = db.relationship("Order",   back_populates="order_items")
    product = db.relationship("Product")

    def to_dict(self):
        return {
            "item_id":    self.item_id,
            "order_id":   self.order_id,
            "product_id": self.product_id,
            "quantity":   self.quantity,
            "unit_price": float(self.unit_price)
        }
