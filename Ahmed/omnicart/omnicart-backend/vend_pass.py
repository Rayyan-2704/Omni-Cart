
from app import create_app, db
from app.models.vendor import Vendor
from app.services.auth_service import hash_password
app = create_app()
with app.app_context():
    vendors = Vendor.query.all()
    for v in vendors:
        if not v.password_hash.startswith('\$2b\$'):
            v.password_hash = hash_password('vendor123')
            print(f'Fixed: {v.email}')
    db.session.commit()
    print('Done!')
