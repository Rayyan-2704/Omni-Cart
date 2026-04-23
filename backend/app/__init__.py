from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
import os
from .extensions import db, jwt, bcrypt

load_dotenv()

def create_app():
    app = Flask(__name__)
    CORS(app)

    # Config
    app.config["SQLALCHEMY_DATABASE_URI"] = (
        f"mysql+pymysql://{os.getenv('DB_USER','root')}:"
        f"{os.getenv('DB_PASSWORD','')}@"
        f"{os.getenv('DB_HOST','localhost')}/"
        f"{os.getenv('DB_NAME','omnicart_db')}"
    )

    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "fallback-dev-secret")

    # Init extensions
    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)

    # Import models (IMPORTANT: after db init)
    from . import models

    # Routes (later you will add blueprints)
    @app.route("/")
    def index():
        return {"message": "OmniCart API is running"}

    return app