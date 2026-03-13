-- =============================================
-- OmniCart Seed Data
-- Run AFTER schema.sql
-- CS 2005: Database Systems | Spring 2026
-- =============================================

USE omnicart;

-- =============================================
-- 1. CUSTOMERS (10 records)
-- =============================================
INSERT INTO customers (name, email, password_hash, phone, address, dob) VALUES
('Ahmed Shah',    'ahmed@gmail.com',  'hashed_pw_1',  '0301-1234567', 'House 12, Block A, Islamabad',     '2000-05-15'),
('Sara Khan',     'sara@gmail.com',   'hashed_pw_2',  '0302-2345678', 'Flat 3, Gulshan, Karachi',          '1998-08-22'),
('Usman Ali',     'usman@gmail.com',  'hashed_pw_3',  '0303-3456789', 'Street 7, DHA, Lahore',             '1999-11-10'),
('Fatima Noor',   'fatima@gmail.com', 'hashed_pw_4',  '0304-4567890', 'House 5, F-7, Islamabad',           '2001-03-28'),
('Bilal Raza',    'bilal@gmail.com',  'hashed_pw_5',  '0305-5678901', 'Block 9, PECHS, Karachi',           '1997-07-14'),
('Zainab Mir',    'zainab@gmail.com', 'hashed_pw_6',  '0306-6789012', 'House 22, Model Town, Lahore',      '2002-01-05'),
('Hamza Sheikh',  'hamza@gmail.com',  'hashed_pw_7',  '0307-7890123', 'Sector G-11, Islamabad',            '1996-09-30'),
('Ayesha Butt',   'ayesha@gmail.com', 'hashed_pw_8',  '0308-8901234', 'House 8, Defence, Karachi',         '2000-12-18'),
('Talha Qureshi', 'talha@gmail.com',  'hashed_pw_9',  '0309-9012345', 'Street 3, Johar Town, Lahore',      '1998-04-25'),
('Maham Tariq',   'maham@gmail.com',  'hashed_pw_10', '0310-0123456', 'House 17, E-11, Islamabad',         '2001-06-08');

-- =============================================
-- 2. VENDORS (5 records)
-- =============================================
INSERT INTO vendors (name, email, password_hash, store_name, phone, is_approved) VALUES
('Rayyan Aamir',   'rayyan@vendor.com',  'hashed_vp_1', 'TechZone PK',  '0321-1111111', TRUE),
('Usaid Khan',     'usaid@vendor.com',   'hashed_vp_2', 'FashionHub',   '0322-2222222', TRUE),
('Nadia Malik',    'nadia@vendor.com',   'hashed_vp_3', 'HomeDecor PK', '0323-3333333', TRUE),
('Kamran Siddiq',  'kamran@vendor.com',  'hashed_vp_4', 'SportsWorld',  '0324-4444444', TRUE),
('Hina Baig',      'hina@vendor.com',    'hashed_vp_5', 'BookCorner',   '0325-5555555', FALSE);

-- =============================================
-- 3. CATEGORIES (8 records)
-- =============================================
INSERT INTO categories (name, description, parent_category_id) VALUES
('Electronics',    'All electronic devices and accessories',    NULL),
('Fashion',        'Clothing, shoes and accessories',           NULL),
('Home & Living',  'Furniture and home decor items',            NULL),
('Sports',         'Sports equipment and activewear',           NULL),
('Books',          'All kinds of books and stationery',         NULL),
('Mobile Phones',  'Smartphones and accessories',               1),
('Laptops',        'Laptops and computing devices',             1),
('Men Clothing',   'Men fashion and apparel',                   2);

-- =============================================
-- 4. PRODUCTS (12 records)
-- =============================================
INSERT INTO products (vendor_id, category_id, name, description, price, stock_qty, brand, rating) VALUES
(1, 6, 'Samsung Galaxy A55',    '6.6 inch display, 128GB storage, 50MP camera, 5000mAh battery',        85000.00,  50,  'Samsung',      4.5),
(1, 6, 'iPhone 15',             'A16 Bionic chip, 128GB, Dynamic Island, USB-C charging',               250000.00, 20,  'Apple',        4.8),
(1, 7, 'Dell Inspiron 15',      'Intel Core i5, 8GB RAM, 512GB SSD, Windows 11',                        120000.00, 15,  'Dell',         4.3),
(1, 7, 'HP Pavilion x360',      'AMD Ryzen 5, 8GB RAM, 256GB SSD, Touchscreen',                         105000.00, 10,  'HP',           4.2),
(2, 8, 'Men Casual Shirt',      '100% cotton, available in multiple colors, slim fit',                  2500.00,   200, 'Bonanza',      4.1),
(2, 8, 'Men Formal Trousers',   'Stretchable fabric, formal wear, multiple sizes',                      3500.00,   150, 'Alkaram',      4.0),
(2, 2, 'Women Lawn Suit',       '3-piece unstitched lawn suit, summer collection',                      4500.00,   100, 'Gul Ahmed',    4.6),
(3, 3, 'Wooden Coffee Table',   'Solid wood, modern design, 4x2 feet',                                  18000.00,  25,  'WoodCraft',    4.4),
(3, 3, 'LED Floor Lamp',        'Adjustable brightness, 3 color modes, touch control',                  6500.00,   40,  'Philips',      4.3),
(4, 4, 'Cricket Bat',           'English willow, full size, professional grade',                        8500.00,   30,  'Gray Nicolls', 4.7),
(4, 4, 'Football',              'FIFA approved, size 5, all weather',                                   3200.00,   60,  'Adidas',       4.5),
(5, 5, 'Clean Code',            'A handbook of agile software craftsmanship by Robert C. Martin',       2800.00,   35,  'Prentice Hall',4.9);

-- =============================================
-- 5. ORDERS (8 records)
-- =============================================
INSERT INTO orders (customer_id, total_amount, status, placed_at) VALUES
(1, 85000.00,  'delivered', '2026-01-10 10:30:00'),
(2, 253500.00, 'delivered', '2026-01-15 14:20:00'),
(3, 120000.00, 'shipped',   '2026-02-01 09:15:00'),
(4, 6000.00,   'confirmed', '2026-02-10 16:45:00'),
(5, 18000.00,  'delivered', '2026-02-14 11:00:00'),
(1, 8500.00,   'pending',   '2026-03-01 13:30:00'),
(6, 4500.00,   'confirmed', '2026-03-05 15:00:00'),
(7, 11700.00,  'shipped',   '2026-03-08 10:00:00');

-- =============================================
-- 6. ORDER ITEMS (12 records)
-- =============================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1,  1, 85000.00),
(2, 2,  1, 250000.00),
(2, 5,  1, 2500.00),
(2, 6,  1, 3500.00),
(3, 3,  1, 120000.00),
(4, 5,  1, 2500.00),
(4, 6,  1, 3500.00),
(5, 8,  1, 18000.00),
(6, 10, 1, 8500.00),
(7, 7,  1, 4500.00),
(8, 9,  1, 6500.00),
(8, 11, 1, 3200.00);

-- =============================================
-- 7. PAYMENTS (8 records)
-- =============================================
INSERT INTO payments (order_id, method, status, amount, paid_at) VALUES
(1, 'card',          'completed', 85000.00,  '2026-01-10 10:35:00'),
(2, 'bank_transfer', 'completed', 253500.00, '2026-01-15 14:25:00'),
(3, 'card',          'completed', 120000.00, '2026-02-01 09:20:00'),
(4, 'cash',          'pending',   6000.00,   NULL),
(5, 'card',          'completed', 18000.00,  '2026-02-14 11:05:00'),
(6, 'wallet',        'pending',   8500.00,   NULL),
(7, 'cash',          'completed', 4500.00,   '2026-03-05 15:10:00'),
(8, 'card',          'completed', 11700.00,  '2026-03-08 10:05:00');

-- =============================================
-- 8. REVIEWS (10 records)
-- =============================================
INSERT INTO reviews (customer_id, product_id, rating, comment, sentiment_score) VALUES
(1,  1,  5, 'Amazing phone! Battery life is outstanding and camera quality is superb.',          0.950),
(2,  2,  5, 'Best iPhone yet. The Dynamic Island feature is incredibly useful.',                 0.980),
(3,  3,  4, 'Good laptop for the price. Performance is solid for everyday tasks.',              0.750),
(4,  5,  4, 'Nice quality shirt. Fabric is comfortable and fitting is perfect.',                0.780),
(5,  8,  5, 'Beautiful coffee table. Solid build and looks great in my living room.',           0.920),
(6,  7,  5, 'Gorgeous lawn suit. Colors are vibrant and fabric quality is excellent.',          0.960),
(7,  9,  4, 'Great lamp with useful features. Easy to set up and looks stylish.',               0.800),
(8,  10, 5, 'Professional grade bat. Excellent balance and great pickup weight.',               0.940),
(9,  11, 4, 'Good quality football. Holds air well and feels great on the ground.',             0.760),
(10, 12, 5, 'Must read for every developer. Changed the way I write code completely.',          0.990);

-- =============================================
-- 9. RECOMMENDATIONS (8 records)
-- =============================================
INSERT INTO recommendations (customer_id, product_id, score, reason) VALUES
(1, 2,  0.9210, 'You recently purchased a Samsung Galaxy A55. You may love the iPhone 15 for its superior performance and camera quality.'),
(1, 10, 0.8750, 'Based on your order history, we think you would enjoy the Cricket Bat given your interest in premium products.'),
(2, 3,  0.8900, 'Customers who bought the iPhone 15 frequently also purchased laptops. The Dell Inspiron 15 is highly rated in your price range.'),
(3, 4,  0.8600, 'You recently purchased the Dell Inspiron 15. The HP Pavilion x360 is a great complement with its touchscreen versatility.'),
(4, 7,  0.9100, 'Based on your purchase of Men Casual Shirt, you may love the Women Lawn Suit for gifting or personal use.'),
(5, 9,  0.8400, 'You purchased a Wooden Coffee Table. The LED Floor Lamp pairs beautifully with modern furniture setups.'),
(6, 8,  0.8750, 'Customers who bought the Women Lawn Suit frequently also explore home decor. The Wooden Coffee Table is a top pick.'),
(7, 12, 0.9500, 'Based on your browsing in electronics, Clean Code by Robert Martin is a highly rated book among tech enthusiasts.');

-- =============================================
-- VERIFY ALL TABLES
-- =============================================
SELECT 'customers'       AS table_name, COUNT(*) AS records FROM customers       UNION ALL
SELECT 'vendors',                        COUNT(*)            FROM vendors                  UNION ALL
SELECT 'categories',                     COUNT(*)            FROM categories               UNION ALL
SELECT 'products',                       COUNT(*)            FROM products                 UNION ALL
SELECT 'orders',                         COUNT(*)            FROM orders                   UNION ALL
SELECT 'order_items',                    COUNT(*)            FROM order_items              UNION ALL
SELECT 'payments',                       COUNT(*)            FROM payments                 UNION ALL
SELECT 'reviews',                        COUNT(*)            FROM reviews                  UNION ALL
SELECT 'recommendations',                COUNT(*)            FROM recommendations;
