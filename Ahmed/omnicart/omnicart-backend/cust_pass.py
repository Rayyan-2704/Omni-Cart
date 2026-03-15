from app import create_app, db
from app.models.customer import Customer
from app.services.auth_service import hash_password
app = create_app()
with app.app_context():
    customers = Customer.query.all()
    for c in customers:
        if not c.password_hash.startswith('\$2b\$'):
            c.password_hash = hash_password('customer123')
            print(f'Fixed: {c.email}')
    db.session.commit()
    print('Done!')