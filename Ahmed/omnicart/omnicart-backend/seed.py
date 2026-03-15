"""
OmniCart Seed Script v2
Run: python seed.py
Safe to run multiple times — skips existing records.
Matches actual DB schema exactly.
"""

from app import create_app, db
from app.models.customer import Customer
from app.models.vendor import Vendor
from app.models.category import Category
from app.models.product import Product
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.payment import Payment
from app.models.review import Review
from app.models.recommendation import Recommendation
import bcrypt
from datetime import datetime, timedelta, date
import random

app = create_app()

def hash_pw(plain):
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()

def seed():
    with app.app_context():

        # ─────────────────────────────────────────────
        # 1. CATEGORIES (5 new — skipping existing 8)
        # ─────────────────────────────────────────────
        # Your DB already has: Electronics, Fashion, Home & Living,
        # Sports, Books, Mobile Phones, Laptops, Men Clothing
        # We add 5 subcategories not yet present
        categories_data = [
            ("Women Clothing",  "Women fashion and apparel",           2),   # parent: Fashion
            ("Kitchen",         "Cookware, appliances and utensils",   3),   # parent: Home & Living
            ("Fitness",         "Gym equipment and fitness gear",       4),   # parent: Sports
            ("Accessories",     "Bags, belts, watches and more",       2),   # parent: Fashion
            ("Stationery",      "Notebooks, pens and office supplies",  5),   # parent: Books
        ]

        categories = []
        # Load all existing categories first
        all_cats = Category.query.all()
        for c in all_cats:
            categories.append(c)

        for name, desc, parent_id in categories_data:
            existing = Category.query.filter_by(name=name).first()
            if existing:
                categories.append(existing)
                print(f"  [skip] Category '{name}' already exists")
            else:
                c = Category(name=name, description=desc, parent_category_id=parent_id)
                db.session.add(c)
                db.session.flush()
                categories.append(c)
                print(f"  [add]  Category '{name}'")

        db.session.commit()
        print(f"✅ Categories done\n")

        # ─────────────────────────────────────────────
        # 2. VENDORS (3 new — skipping existing 5)
        # ─────────────────────────────────────────────
        # Existing: rayyan@vendor.com, usaid@vendor.com, nadia@vendor.com,
        #           kamran@vendor.com, hina@vendor.com
        vendors_data = [
            ("Bilal Chaudhry",  "bilal@gadgetworld.pk",  "GadgetWorld",    "0326-6666666", True),
            ("Amna Sheikh",     "amna@stylestore.pk",    "StyleStore",     "0327-7777777", True),
            ("Zaid Hussain",    "zaid@homepro.pk",       "HomePro PK",     "0328-8888888", True),
        ]

        vendors = []
        # Load existing vendors
        all_vendors = Vendor.query.all()
        for v in all_vendors:
            vendors.append(v)

        for name, email, store, phone, approved in vendors_data:
            existing = Vendor.query.filter_by(email=email).first()
            if existing:
                vendors.append(existing)
                print(f"  [skip] Vendor '{email}' already exists")
            else:
                v = Vendor(name=name, email=email,
                           password_hash=hash_pw("vendor123"),
                           store_name=store, phone=phone, is_approved=approved)
                db.session.add(v)
                db.session.flush()
                vendors.append(v)
                print(f"  [add]  Vendor '{store}'")

        db.session.commit()
        print(f"✅ Vendors done\n")

        # ─────────────────────────────────────────────
        # 3. PRODUCTS (20 new — skipping existing 12)
        # ─────────────────────────────────────────────
        # Existing vendor IDs: 1=TechZone, 2=FashionHub, 3=HomeDecor,
        #                      4=SportsWorld, 5=BookCorner
        # New vendor IDs: 6=GadgetWorld, 7=StyleStore, 8=HomePro
        # Existing category IDs: 1=Electronics,2=Fashion,3=Home&Living,
        #   4=Sports,5=Books,6=Mobile Phones,7=Laptops,8=Men Clothing
        # New category IDs will be 9=Women Clothing,10=Kitchen,11=Fitness,
        #   12=Accessories,13=Stationery

        # Fetch fresh vendor/category maps by name
        v = {vn.store_name: vn for vn in Vendor.query.all()}
        c = {cn.name: cn for cn in Category.query.all()}

        products_data = [
            # Mobile Phones (2) — GadgetWorld
            ("OnePlus 12R",             "6.78 AMOLED, Snapdragon 8 Gen 2, 5000mAh",         89999.00, 25,  4.4, "OnePlus",    v.get("GadgetWorld"), c.get("Mobile Phones")),
            ("Google Pixel 8a",         "6.1 OLED, Google Tensor G3, 4500mAh, 64MP",        99999.00, 18,  4.6, "Google",     v.get("GadgetWorld"), c.get("Mobile Phones")),

            # Laptops (2) — GadgetWorld
            ("Lenovo IdeaPad Slim 5",   "Ryzen 7, 16GB RAM, 512GB SSD, 14-inch FHD",        115000.00,12,  4.3, "Lenovo",     v.get("GadgetWorld"), c.get("Laptops")),
            ("ASUS VivoBook 15",        "Intel i5-12th Gen, 8GB, 512GB, Win11",              98000.00, 10,  4.2, "ASUS",       v.get("GadgetWorld"), c.get("Laptops")),

            # Electronics (2) — GadgetWorld
            ("JBL Flip 6 Speaker",      "Waterproof Bluetooth speaker, 12hr battery",        18500.00, 35,  4.5, "JBL",        v.get("GadgetWorld"), c.get("Electronics")),
            ("Xiaomi Smart Band 8",     "1.62 AMOLED, 16 day battery, SpO2 monitor",         8999.00,  50,  4.3, "Xiaomi",     v.get("GadgetWorld"), c.get("Electronics")),

            # Women Clothing (3) — StyleStore
            ("Khaadi Lawn Kurta",       "Printed lawn kurta, summer 2026 collection",         3200.00, 120, 4.5, "Khaadi",     v.get("StyleStore"),  c.get("Women Clothing")),
            ("Limelight Printed Dupatta","Chiffon dupatta with embroidered borders",           1800.00, 200, 4.3, "Limelight",  v.get("StyleStore"),  c.get("Women Clothing")),
            ("Sapphire Midi Dress",     "Floral midi dress, polyester blend",                  4500.00, 80,  4.6, "Sapphire",   v.get("StyleStore"),  c.get("Women Clothing")),

            # Accessories (2) — StyleStore
            ("Fossil Gen 6 Watch",      "Stainless steel smartwatch, Wear OS",                35000.00, 20,  4.4, "Fossil",     v.get("StyleStore"),  c.get("Accessories")),
            ("Leather Crossbody Bag",   "Genuine leather, multiple compartments, brown",       7500.00,  45,  4.2, "Stylo",      v.get("StyleStore"),  c.get("Accessories")),

            # Kitchen (3) — HomePro
            ("Dawlance Microwave 25L",  "25L solo microwave, 900W, 5 power levels",           18500.00, 22,  4.1, "Dawlance",   v.get("HomePro PK"), c.get("Kitchen")),
            ("Prestige Pressure Cooker","5L aluminium pressure cooker with safety valve",      4200.00,  60,  4.3, "Prestige",   v.get("HomePro PK"), c.get("Kitchen")),
            ("Bosch Hand Blender",      "600W immersion blender, 2-speed, detachable shaft",   9800.00,  30,  4.5, "Bosch",      v.get("HomePro PK"), c.get("Kitchen")),

            # Fitness (3) — SportsWorld
            ("Fitness Skipping Rope",   "PVC jump rope with foam handles, adjustable length",   850.00, 150, 4.0, "Decathlon",  v.get("SportsWorld"), c.get("Fitness")),
            ("Yoga Mat 6mm",            "Non-slip TPE yoga mat, 183x61cm, with carry strap",   2500.00, 100, 4.4, "Strauss",    v.get("SportsWorld"), c.get("Fitness")),
            ("Resistance Bands Set",    "5-piece latex bands, light to extra heavy",            1800.00, 120, 4.3, "Boldfit",    v.get("SportsWorld"), c.get("Fitness")),

            # Books (2) — BookCorner
            ("Deep Work by Cal Newport","Rules for focused success in a distracted world",      1999.00, 80,  4.8, "Grand Central",v.get("BookCorner"), c.get("Books")),
            ("Ikigai by Hector Garcia", "The Japanese secret to a long and happy life",         1599.00, 100, 4.7, "Penguin",    v.get("BookCorner"), c.get("Books")),

            # Stationery (2) — BookCorner
            ("Moleskine Classic Notebook","Hard cover, 240 pages, ruled, A5 size",             2800.00, 60,  4.6, "Moleskine",  v.get("BookCorner"), c.get("Stationery")),
            ("Staedtler Mars Pencils",  "Box of 12 graphite pencils, HB to 6B",                1200.00, 90,  4.5, "Staedtler",  v.get("BookCorner"), c.get("Stationery")),
        ]

        products = []
        # Load existing products
        all_products = Product.query.all()
        for p in all_products:
            products.append(p)

        for name, desc, price, stock, rating, brand, vendor, category in products_data:
            if vendor is None or category is None:
                print(f"  [warn] Skipping '{name}' — vendor or category not found")
                continue
            existing = Product.query.filter_by(name=name).first()
            if existing:
                products.append(existing)
                print(f"  [skip] Product '{name}' already exists")
            else:
                p = Product(name=name, description=desc, price=price,
                            stock_qty=stock, rating=rating, brand=brand,
                            vendor_id=vendor.vendor_id,
                            category_id=category.category_id, is_active=True)
                db.session.add(p)
                db.session.flush()
                products.append(p)
                print(f"  [add]  Product '{name}' — Rs.{price:,.0f}")

        db.session.commit()
        print(f"✅ Products: {Product.query.count()} total\n")

        # ─────────────────────────────────────────────
        # 4. CUSTOMERS (10 new — skipping existing 10)
        # ─────────────────────────────────────────────
        # Existing emails: ahmed, sara, usman, fatima, bilal,
        #                  zainab, hamza, ayesha, talha, maham @gmail.com
        customers_data = [
            ("Noor Fatima",     "noor.fatima@gmail.com",    "0311-1111111", "House 4, Bahria Town, Lahore",      date(2000, 3, 12)),
            ("Asad Mehmood",    "asad.mehmood@gmail.com",   "0312-2222222", "Flat 7, Gulshan-e-Iqbal, Karachi",  date(1998, 7, 25)),
            ("Hira Baig",       "hira.baig@outlook.com",    "0313-3333333", "Street 9, I-8, Islamabad",          date(2001, 11, 3)),
            ("Faisal Nawaz",    "faisal.nawaz@yahoo.com",   "0314-4444444", "House 20, DHA Phase 6, Lahore",     date(1997, 5, 18)),
            ("Sobia Akhtar",    "sobia.akhtar@gmail.com",   "0315-5555555", "Flat 3B, Clifton, Karachi",         date(2002, 9, 7)),
            ("Imran Qureshi",   "imran.q@hotmail.com",      "0316-6666666", "Sector F-11, Islamabad",            date(1996, 2, 14)),
            ("Rabia Malik",     "rabia.malik@gmail.com",    "0317-7777777", "House 11, Johar Town, Lahore",      date(1999, 8, 30)),
            ("Danyal Shah",     "danyal.shah@gmail.com",    "0318-8888888", "Street 5, Hayatabad, Peshawar",     date(2000, 12, 22)),
            ("Mehwish Tariq",   "mehwish.t@gmail.com",      "0319-9999999", "House 6, G-9/4, Islamabad",         date(2001, 4, 15)),
            ("Saad Ullah",      "saad.ullah@gmail.com",     "0310-1010101", "Flat 12, North Nazimabad, Karachi", date(1998, 6, 11)),
        ]

        customers = []
        all_customers = Customer.query.all()
        for cu in all_customers:
            customers.append(cu)

        for name, email, phone, address, dob in customers_data:
            existing = Customer.query.filter_by(email=email).first()
            if existing:
                customers.append(existing)
                print(f"  [skip] Customer '{email}' already exists")
            else:
                cu = Customer(name=name, email=email,
                              password_hash=hash_pw("customer123"),
                              phone=phone, address=address,
                              dob=dob, is_active=True)
                db.session.add(cu)
                db.session.flush()
                customers.append(cu)
                print(f"  [add]  Customer '{name}'")

        db.session.commit()
        print(f"✅ Customers: {Customer.query.count()} total\n")

        # ─────────────────────────────────────────────
        # 5. ORDERS + ORDER ITEMS + PAYMENTS (15 new)
        # ─────────────────────────────────────────────
        # Use customers index 10-19 (our new customers)
        # Use products index 12-31 (our new products)
        # Existing orders had IDs 1-8, statuses: delivered/shipped/confirmed/pending

        order_plans = [
            # (cust_idx, [(prod_idx, qty)], status, pay_method)
            (10, [(12, 1)],           "delivered",  "card"),
            (11, [(13, 1), (14, 1)],  "delivered",  "bank_transfer"),
            (12, [(15, 2)],           "shipped",    "card"),
            (13, [(16, 1)],           "confirmed",  "cash"),
            (14, [(17, 1), (18, 1)],  "delivered",  "card"),
            (15, [(19, 1)],           "pending",    "wallet"),
            (16, [(20, 1), (21, 1)],  "delivered",  "card"),
            (17, [(22, 3)],           "shipped",    "bank_transfer"),
            (18, [(23, 1), (24, 1)],  "delivered",  "card"),
            (19, [(25, 1)],           "confirmed",  "cash"),
            (10, [(26, 2)],           "delivered",  "card"),
            (11, [(27, 1), (28, 1)],  "cancelled",  "wallet"),
            (12, [(29, 1)],           "delivered",  "card"),
            (13, [(30, 2), (31, 1)],  "shipped",    "bank_transfer"),
            (14, [(12, 1), (13, 1)],  "delivered",  "card"),
        ]

        orders_added = 0
        for i, (cust_idx, items, status, pay_method) in enumerate(order_plans):
            # Guard: if product index out of range, skip
            valid = all(pidx < len(products) for pidx, _ in items)
            if not valid or cust_idx >= len(customers):
                print(f"  [warn] Order #{i+1} skipped — index out of range")
                continue

            customer = customers[cust_idx]
            total = sum(float(products[pidx].price) * qty for pidx, qty in items)

            existing = Order.query.filter_by(
                customer_id=customer.customer_id,
                total_amount=total
            ).first()
            if existing:
                print(f"  [skip] Order #{i+1} already exists")
                continue

            placed_at = datetime.utcnow() - timedelta(days=random.randint(1, 60))

            order = Order(
                customer_id=customer.customer_id,
                total_amount=total,
                status=status,
                placed_at=placed_at
            )
            db.session.add(order)
            db.session.flush()

            for pidx, qty in items:
                product = products[pidx]
                item = OrderItem(
                    order_id=order.order_id,
                    product_id=product.product_id,
                    quantity=qty,
                    unit_price=product.price
                )
                db.session.add(item)

            pay_status = "completed" if status in ["delivered", "shipped"] else \
                         "failed"   if status == "cancelled" else "pending"
            paid_at = placed_at + timedelta(minutes=10) if pay_status == "completed" else None

            payment = Payment(
                order_id=order.order_id,
                amount=total,
                method=pay_method,
                status=pay_status,
                paid_at=paid_at
            )
            db.session.add(payment)
            orders_added += 1
            print(f"  [add]  Order #{i+1} — {customer.name} — Rs.{total:,.0f} — {status}")

        db.session.commit()
        print(f"✅ Orders + Payments: {orders_added} added\n")

        # ─────────────────────────────────────────────
        # 6. REVIEWS (30 new)
        # ─────────────────────────────────────────────
        # Use new customers (idx 10-19) reviewing new products (idx 12-31)
        # sentiment_score is float 0.0-1.0 (not enum)
        reviews_data = [
            (10, 12, 5, "OnePlus 12R is blazing fast! Best value flagship right now.",         0.96),
            (11, 12, 4, "Great phone but gets warm under load. Camera is excellent though.",   0.74),
            (12, 13, 5, "Pixel 8a camera is insane. Google's AI features are genuinely useful.",0.97),
            (13, 14, 4, "Lenovo runs cool and quiet. Perfect for university work.",             0.78),
            (14, 14, 3, "Average battery life but performance is solid. Build feels cheap.",   0.45),
            (15, 15, 5, "ASUS VivoBook is perfect for students. Fast and lightweight.",        0.93),
            (16, 16, 5, "JBL Flip 6 sound is incredibly loud for its size. Waterproof works!",0.95),
            (17, 17, 4, "Xiaomi band tracks sleep and steps accurately. Great value.",         0.80),
            (18, 18, 5, "Khaadi kurta fabric is premium quality. Fits perfectly.",             0.94),
            (19, 18, 4, "Nice design but color faded slightly after first wash.",              0.65),
            (10, 19, 5, "Beautiful dupatta. Exactly as shown in the picture.",                 0.92),
            (11, 20, 5, "Sapphire dress is gorgeous. Got so many compliments.",                0.97),
            (12, 21, 4, "Fossil watch looks premium. Battery lasts about 1.5 days.",           0.76),
            (13, 22, 3, "Bag is decent but stitching came loose after 2 weeks.",               0.38),
            (14, 23, 4, "Dawlance microwave heats evenly. Easy to clean inside.",              0.77),
            (15, 24, 5, "Prestige cooker is a kitchen essential. Cooks dal perfectly.",        0.91),
            (16, 25, 5, "Bosch blender is powerful and quiet. Smoothies are perfect.",         0.94),
            (17, 26, 4, "Good skipping rope but handle grip could be better.",                 0.72),
            (18, 27, 5, "Yoga mat is thick and grippy. Does not slip at all during hot yoga.", 0.95),
            (19, 28, 5, "Resistance bands are great quality. Good range of resistance.",       0.93),
            (10, 29, 5, "Deep Work changed how I study. Cal Newport is brilliant.",            0.98),
            (11, 29, 4, "Excellent book but some chapters are repetitive. Still a must read.", 0.75),
            (12, 30, 5, "Ikigai is a short but profound read. Finished it in one sitting.",    0.96),
            (13, 31, 5, "Moleskine notebook quality is unmatched. Worth every rupee.",         0.94),
            (14, 31, 4, "Pages are slightly thin but overall a beautiful notebook.",           0.71),
            (15, 32, 5, "Staedtler pencils are smooth and consistent. Great for sketching.",   0.92),
            (16, 13, 4, "Pixel 8a is solid but I wish it had a bigger screen.",               0.70),
            (17, 15, 3, "ASUS battery drains faster than expected. Otherwise decent.",         0.42),
            (18, 16, 5, "JBL speaker is a party starter. Bass is deep and clear.",             0.96),
            (19, 30, 4, "Ikigai is inspiring. A gentle reminder to slow down and live.",       0.82),
        ]

        reviews_added = 0
        for cust_idx, prod_idx, rating, comment, sentiment_score in reviews_data:
            if cust_idx >= len(customers) or prod_idx >= len(products) + 1:
                print(f"  [warn] Review skipped — index out of range")
                continue

            # prod_idx in reviews_data is 1-based product list index
            actual_prod_idx = prod_idx - 1
            if actual_prod_idx >= len(products):
                continue

            customer = customers[cust_idx]
            product  = products[actual_prod_idx]

            existing = Review.query.filter_by(
                customer_id=customer.customer_id,
                product_id=product.product_id
            ).first()
            if existing:
                print(f"  [skip] Review by {customer.name} on '{product.name}' exists")
                continue

            r = Review(
                customer_id=customer.customer_id,
                product_id=product.product_id,
                rating=rating,
                comment=comment,
                sentiment_score=sentiment_score,
                created_at=datetime.utcnow() - timedelta(days=random.randint(1, 30))
            )
            db.session.add(r)
            reviews_added += 1

        db.session.commit()
        print(f"✅ Reviews: {reviews_added} added\n")

        # ─────────────────────────────────────────────
        # SUMMARY
        # ─────────────────────────────────────────────
        print("=" * 50)
        print("📦 SEED COMPLETE — Final counts:")
        print(f"   Categories : {Category.query.count()}")
        print(f"   Vendors    : {Vendor.query.count()}")
        print(f"   Products   : {Product.query.count()}")
        print(f"   Customers  : {Customer.query.count()}")
        print(f"   Orders     : {Order.query.count()}")
        print(f"   Order Items: {OrderItem.query.count()}")
        print(f"   Payments   : {Payment.query.count()}")
        print(f"   Reviews    : {Review.query.count()}")
        print("=" * 50)

if __name__ == "__main__":
    seed()
