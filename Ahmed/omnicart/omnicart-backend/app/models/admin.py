from app import db
from datetime import datetime

class Admin(db.Model):
    __tablename__ = "admins"
    admin_id      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name          = db.Column(db.String(100), nullable=False)
    email         = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at    = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "admin_id":   self.admin_id,
            "name":       self.name,
            "email":      self.email,
            "created_at": self.created_at.isoformat()
        }
