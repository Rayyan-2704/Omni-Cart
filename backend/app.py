from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
CORS(app)

# Database Config
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "omnicart_db")

app.config["SQLALCHEMY_DATABASE_URI"] = (
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "fallback-dev-secret")

# Extensions
db  = SQLAlchemy(app)
jwt = JWTManager(app)
bcrypt = Bcrypt(app)

# Register models (so db.create_all sees all tables)
from backend.models import *  # noqa: E402, F401, F403

# Register blueprints (add more here as phases progress)
# from backend.routes.auth import auth_bp
# app.register_blueprint(auth_bp, url_prefix="/api/auth")

@app.route("/")
def index():
    return {"message": "OmniCart API is running"}


if __name__ == "__main__":
    with app.app_context():
        from sqlalchemy import text
        result = db.session.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result]
        print(f"✅ Connected to DB. Tables found: {tables}")
    app.run(debug=True)