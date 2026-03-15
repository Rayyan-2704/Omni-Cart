"""
Role-based access control middleware for OmniCart.
Usage:
    @jwt_required()
    @role_required("admin")
    def admin_only_route(): ...
"""
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt

def role_required(*roles):
    """Decorator — restrict endpoint to one or more roles."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            user_role = claims.get("role")
            if user_role not in roles:
                return jsonify({"error": f"Access denied. Required role(s): {', '.join(roles)}"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator
