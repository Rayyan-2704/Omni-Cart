from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
CORS(app)

app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY")

@app.route("/")
def index():
    return {"message": "OmniCart API is running"}

if __name__ == "__main__":
    app.run(debug=True)