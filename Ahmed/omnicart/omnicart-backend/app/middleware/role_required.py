from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt

def role_required(*roles):
    """Decorator: restrict endpoint to specific roles (customer, vendor, admin)."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            if claims.get("role") not in roles:
                return jsonify({"error": "Forbidden: insufficient permissions"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator
