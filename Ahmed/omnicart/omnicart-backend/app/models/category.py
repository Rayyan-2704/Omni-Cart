from app import db

class Category(db.Model):
    __tablename__ = "categories"
    category_id        = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name               = db.Column(db.String(100), nullable=False)
    description        = db.Column(db.Text)
    parent_category_id = db.Column(db.Integer, db.ForeignKey("categories.category_id"), nullable=True)

    products = db.relationship("Product", back_populates="category")
    children = db.relationship("Category", backref=db.backref("parent", remote_side=[category_id]))

    def to_dict(self):
        return {
            "category_id": self.category_id, "name": self.name,
            "description": self.description,
            "parent_category_id": self.parent_category_id
        }
