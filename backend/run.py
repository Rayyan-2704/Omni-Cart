from backend.app import create_app
from backend.app.extensions import db
from sqlalchemy import text

app = create_app()

if __name__ == "__main__":
    with app.app_context():
        from sqlalchemy import text
        result = db.session.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result]
        print(f"✅ Connected to DB. Tables found: {tables}")

    app.run(debug=True)