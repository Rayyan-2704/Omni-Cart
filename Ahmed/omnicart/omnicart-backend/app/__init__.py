from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import config

db = SQLAlchemy()
jwt = JWTManager()

def create_app(env="default"):
    app = Flask(__name__)
    app.config.from_object(config[env])

    # Extensions
    db.init_app(app)
    jwt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    from app.routes.orders import orders_bp
    from app.routes.cart import cart_bp
    from app.routes.reviews import reviews_bp
    from app.routes.recommendations import recommendations_bp
    from app.routes.admin import admin_bp

    app.register_blueprint(auth_bp,            url_prefix="/api/auth")
    app.register_blueprint(products_bp,        url_prefix="/api/products")
    app.register_blueprint(orders_bp,          url_prefix="/api/orders")
    app.register_blueprint(cart_bp,            url_prefix="/api/cart")
    app.register_blueprint(reviews_bp,         url_prefix="/api/reviews")
    app.register_blueprint(recommendations_bp, url_prefix="/api/recommendations")
    app.register_blueprint(admin_bp,           url_prefix="/api/admin")

    return app
