from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, jwt_required, get_jwt_identity, get_jwt
)
from app import db
from app.models.customer import Customer
from app.models.vendor import Vendor
from app.services.auth_service import hash_password, verify_password
from datetime import datetime

auth_bp = Blueprint("auth", __name__)


# ─────────────────────────────────────────────
# POST /api/auth/register
# Body: { name, email, password, role, phone?, address?, store_name? }
# ─────────────────────────────────────────────
@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()

    # Validate required fields
    required = ["name", "email", "password", "role"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    role     = data["role"].lower()
    name     = data["name"].strip()
    email    = data["email"].strip().lower()
    password = data["password"]

    if role not in ["customer", "vendor"]:
        return jsonify({"error": "Role must be 'customer' or 'vendor'"}), 400

    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400

    # Check duplicate email across both tables
    if Customer.query.filter_by(email=email).first() or \
       Vendor.query.filter_by(email=email).first():
        return jsonify({"error": "Email already registered"}), 409

    if role == "customer":
        user = Customer(
            name=name,
            email=email,
            password_hash=hash_password(password),
            phone=data.get("phone"),
            address=data.get("address"),
        )
        db.session.add(user)
        db.session.commit()
        token = create_access_token(
            identity=str(user.customer_id),
            additional_claims={"role": "customer", "name": user.name}
        )
        return jsonify({
            "message": "Customer registered successfully",
            "token": token,
            "user": user.to_dict()
        }), 201

    else:  # vendor
        user = Vendor(
            name=name,
            email=email,
            password_hash=hash_password(password),
            phone=data.get("phone"),
            store_name=data.get("store_name", f"{name}'s Store"),
            is_approved=False
        )
        db.session.add(user)
        db.session.commit()
        token = create_access_token(
            identity=str(user.vendor_id),
            additional_claims={"role": "vendor", "name": user.name}
        )
        return jsonify({
            "message": "Vendor registered successfully. Await admin approval.",
            "token": token,
            "user": user.to_dict()
        }), 201


# ─────────────────────────────────────────────
# POST /api/auth/login
# Body: { email, password, role }
# ─────────────────────────────────────────────
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()

    required = ["email", "password", "role"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    role  = data["role"].lower()
    email = data["email"].strip().lower()
    password = data["password"]

    if role not in ["customer", "vendor", "admin"]:
        return jsonify({"error": "Invalid role"}), 400

    # Admin hardcoded (no DB table for admin in schema)
    if role == "admin":
        import os
        admin_email = os.getenv("ADMIN_EMAIL", "admin@omnicart.pk")
        admin_pass  = os.getenv("ADMIN_PASSWORD", "admin123")
        if email != admin_email or password != admin_pass:
            return jsonify({"error": "Invalid admin credentials"}), 401
        token = create_access_token(
            identity="admin",
            additional_claims={"role": "admin", "name": "Admin"}
        )
        return jsonify({
            "message": "Admin login successful",
            "token": token,
            "user": {"email": admin_email, "role": "admin", "name": "Admin"}
        }), 200

    # Customer login
    if role == "customer":
        user = Customer.query.filter_by(email=email).first()
        if not user or not verify_password(password, user.password_hash):
            return jsonify({"error": "Invalid email or password"}), 401
        if not user.is_active:
            return jsonify({"error": "Account is deactivated"}), 403
        token = create_access_token(
            identity=str(user.customer_id),
            additional_claims={"role": "customer", "name": user.name}
        )
        return jsonify({
            "message": "Login successful",
            "token": token,
            "user": user.to_dict()
        }), 200

    # Vendor login
    if role == "vendor":
        user = Vendor.query.filter_by(email=email).first()
        if not user or not verify_password(password, user.password_hash):
            return jsonify({"error": "Invalid email or password"}), 401
        if not user.is_approved:
            return jsonify({"error": "Vendor account pending admin approval"}), 403
        token = create_access_token(
            identity=str(user.vendor_id),
            additional_claims={"role": "vendor", "name": user.name}
        )
        return jsonify({
            "message": "Login successful",
            "token": token,
            "user": user.to_dict()
        }), 200


# ─────────────────────────────────────────────
# GET /api/auth/me
# Header: Authorization: Bearer <token>
# ─────────────────────────────────────────────
@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = get_jwt_identity()

    if role == "customer":
        user = Customer.query.get(int(user_id))
        if not user:
            return jsonify({"error": "User not found"}), 404
        return jsonify({"role": "customer", "user": user.to_dict()}), 200

    elif role == "vendor":
        user = Vendor.query.get(int(user_id))
        if not user:
            return jsonify({"error": "Vendor not found"}), 404
        return jsonify({"role": "vendor", "user": user.to_dict()}), 200

    elif role == "admin":
        return jsonify({"role": "admin", "user": {"name": "Admin", "email": claims.get("sub")}}), 200

    return jsonify({"error": "Invalid token"}), 401


# ─────────────────────────────────────────────
# PUT /api/auth/profile
# Update logged-in user's profile
# ─────────────────────────────────────────────
@auth_bp.route("/profile", methods=["PUT"])
@jwt_required()
def update_profile():
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = get_jwt_identity()
    data    = request.get_json()

    if role == "customer":
        user = Customer.query.get(int(user_id))
        if not user:
            return jsonify({"error": "User not found"}), 404
        user.name    = data.get("name",    user.name)
        user.phone   = data.get("phone",   user.phone)
        user.address = data.get("address", user.address)
        db.session.commit()
        return jsonify({"message": "Profile updated", "user": user.to_dict()}), 200

    elif role == "vendor":
        user = Vendor.query.get(int(user_id))
        if not user:
            return jsonify({"error": "Vendor not found"}), 404
        user.name       = data.get("name",       user.name)
        user.phone      = data.get("phone",      user.phone)
        user.store_name = data.get("store_name", user.store_name)
        db.session.commit()
        return jsonify({"message": "Profile updated", "user": user.to_dict()}), 200

    return jsonify({"error": "Admins cannot update profile via this endpoint"}), 403


# ─────────────────────────────────────────────
# PUT /api/auth/change-password
# ─────────────────────────────────────────────
@auth_bp.route("/change-password", methods=["PUT"])
@jwt_required()
def change_password():
    claims      = get_jwt()
    role        = claims.get("role")
    user_id     = get_jwt_identity()
    data        = request.get_json()

    old_password = data.get("old_password")
    new_password = data.get("new_password")

    if not old_password or not new_password:
        return jsonify({"error": "Both old_password and new_password are required"}), 400

    if len(new_password) < 6:
        return jsonify({"error": "New password must be at least 6 characters"}), 400

    if role == "customer":
        user = Customer.query.get(int(user_id))
    elif role == "vendor":
        user = Vendor.query.get(int(user_id))
    else:
        return jsonify({"error": "Admins cannot change password via this endpoint"}), 403

    if not user or not verify_password(old_password, user.password_hash):
        return jsonify({"error": "Old password is incorrect"}), 401

    user.password_hash = hash_password(new_password)
    db.session.commit()
    return jsonify({"message": "Password changed successfully"}), 200
