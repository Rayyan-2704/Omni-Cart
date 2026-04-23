# Importing every model here ensures Flask-SQLAlchemy's db.create_all()
# can see every table. Import this module once in app.py.

from backend.models.customer import Customer
from backend.models.vendor import Vendor
from backend.models.category import Category
from backend.models.product import Product
from backend.models.order import Order, OrderItem
from backend.models.payment import Payment
from backend.models.review import Review
from backend.models.recommendation import Recommendation
from backend.models.cart import Cart
from backend.models.admin import Admin

__all__ = [
    "Customer", "Vendor", "Category", "Product",
    "Order", "OrderItem", "Payment", "Review",
    "Recommendation", "Cart", "Admin"
]