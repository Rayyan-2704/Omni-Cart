-- =============================================
-- OmniCart Seed Data
-- Equivalent of seed.py for project evaluation
-- Safe to run on a fresh omnicart_db
-- =============================================

USE omnicart_db;

-- =============================================
-- 1. Admins
-- =============================================
INSERT IGNORE INTO admins (name, email, password_hash) VALUES
('Super Admin',   'admin@omnicart.com',         '$2b$12$placeholderHashSuperAdmin111'),
('Ops Admin',     'ops.admin@omnicart.com',      '$2b$12$placeholderHashOpsAdmin1111'),
('Support Admin', 'support.admin@omnicart.com',  '$2b$12$placeholderHashSuppAdmin111');

-- =============================================
-- 2. Vendors
-- =============================================
INSERT IGNORE INTO vendors (name, email, password_hash, store_name, phone, is_approved, is_active) VALUES
('Ali Raza',      'techzone@omnicart.com',    '$2b$12$placeholderHashVendor11111', 'TechZone Store',  '0321-1234567', TRUE, TRUE),
('Sara Qureshi',  'audioworld@omnicart.com',  '$2b$12$placeholderHashVendor11111', 'AudioWorld',      '0322-2345678', TRUE, TRUE),
('Hamza Butt',    'gadgethub@omnicart.com',   '$2b$12$placeholderHashVendor11111', 'GadgetHub',       '0333-3456789', TRUE, TRUE),
('Nadia Farooq',  'mobilezone@omnicart.com',  '$2b$12$placeholderHashVendor11111', 'MobileZone PK',   '0344-4567890', TRUE, TRUE),
('Kamran Sheikh', 'laptopcity@omnicart.com',  '$2b$12$placeholderHashVendor11111', 'Laptop City',     '0355-5678901', TRUE, TRUE);

-- =============================================
-- 3. Categories
-- =============================================

-- Parent
INSERT IGNORE INTO categories (name, description, parent_category_id) VALUES
('Electronics', 'All electronic gadgets and devices', NULL);

-- Sub-categories (parent = Electronics = 1)
INSERT IGNORE INTO categories (name, description, parent_category_id) VALUES
('Audio',        'Headphones, speakers, and audio gear',  1),
('Mobiles',      'Smartphones and accessories',           1),
('Laptops',      'Laptops and notebooks',                 1),
('Accessories',  'Cables, cases, and peripherals',        1);

-- category_id mapping (used by products below):
--   1 = Electronics
--   2 = Audio
--   3 = Mobiles
--   4 = Laptops
--   5 = Accessories

-- =============================================
-- 4. Products
-- vendor_id mapping: TechZone=1, AudioWorld=2, GadgetHub=3, MobileZone=4, LaptopCity=5
-- =============================================

-- Audio (category_id = 2)
INSERT IGNORE INTO products (vendor_id, category_id, name, description, price, stock_qty, brand, is_active) VALUES
(1, 2, 'Sony WH-1000XM5',      'Industry-leading noise cancelling headphones',                49999.00, 30, 'Sony',    TRUE),
(1, 2, 'JBL Tune 760NC',       'Wireless over-ear ANC headphones',                            18999.00, 45, 'JBL',     TRUE),
(2, 2, 'Bose QuietComfort 45', 'Premium wireless headphones with world-class ANC',            62999.00, 20, 'Bose',    TRUE),
(2, 2, 'Sony SRS-XB43',        'Powerful EXTRA BASS Bluetooth wireless speaker',              22999.00, 35, 'Sony',    TRUE),
(3, 2, 'JBL Flip 6',           'Portable waterproof speaker with bold JBL Pro Sound',         14999.00, 50, 'JBL',     TRUE);

-- Mobiles (category_id = 3)
INSERT IGNORE INTO products (vendor_id, category_id, name, description, price, stock_qty, brand, is_active) VALUES
(1, 3, 'Samsung Galaxy S24',   '2024 flagship Android smartphone with AI features',          159999.00, 25, 'Samsung', TRUE),
(1, 3, 'iPhone 15 Pro',        'Apple flagship with titanium design and A17 Pro chip',       289999.00, 15, 'Apple',   TRUE),
(4, 3, 'Xiaomi 14',            'Leica-tuned camera flagship with Snapdragon 8 Gen 3',        119999.00, 30, 'Xiaomi',  TRUE),
(4, 3, 'OnePlus 12',           'Flagship killer with Hasselblad camera system',              109999.00, 20, 'OnePlus', TRUE),
(4, 3, 'Google Pixel 8',       'Pure Android with best-in-class AI camera',                  129999.00, 18, 'Google',  TRUE);

-- Laptops (category_id = 4)
INSERT IGNORE INTO products (vendor_id, category_id, name, description, price, stock_qty, brand, is_active) VALUES
(5, 4, 'Dell XPS 15',                 '15-inch premium laptop with OLED and Intel Core Ultra',  249999.00, 10, 'Dell',    TRUE),
(5, 4, 'Apple MacBook Pro M3',        '16-inch MacBook Pro with M3 Pro chip',                   369999.00,  8, 'Apple',   TRUE),
(5, 4, 'Lenovo ThinkPad X1 Carbon',   'Business ultrabook with military-grade durability',       219999.00, 12, 'Lenovo',  TRUE),
(5, 4, 'ASUS ROG Zephyrus G16',       'Gaming laptop with RTX 4080 and 240Hz OLED display',     319999.00,  7, 'ASUS',    TRUE),
(5, 4, 'HP Spectre x360',             '2-in-1 premium laptop with 4K OLED touch display',       199999.00, 10, 'HP',      TRUE);

-- Accessories (category_id = 5)
INSERT IGNORE INTO products (vendor_id, category_id, name, description, price, stock_qty, brand, is_active) VALUES
(3, 5, 'Anker USB-C Hub 7-in-1',       'Multiport hub with HDMI, USB-A, SD card reader',          3999.00, 100, 'Anker',    TRUE),
(1, 5, 'Spigen iPhone 15 Case',         'Military-grade protection case for iPhone 15',             1999.00,  80, 'Spigen',   TRUE),
(2, 5, 'Logitech MX Master 3S',         'Advanced wireless mouse with MagSpeed scrolling',         17999.00,  40, 'Logitech', TRUE),
(3, 5, 'Samsung 45W USB-C Charger',     'Super-fast USB-C wall charger with cable',                2999.00,  60, 'Samsung',  TRUE),
(1, 5, 'Baseus 20000mAh Power Bank',    'High-capacity power bank with 65W fast charging',         7999.00,  55, 'Baseus',   TRUE);

-- product_id mapping (insertion order, assuming fresh DB):
--  1=Sony WH-1000XM5        2=JBL Tune 760NC          3=Bose QuietComfort 45
--  4=Sony SRS-XB43          5=JBL Flip 6              6=Samsung Galaxy S24
--  7=iPhone 15 Pro          8=Xiaomi 14               9=OnePlus 12
-- 10=Google Pixel 8        11=Dell XPS 15            12=Apple MacBook Pro M3
-- 13=Lenovo ThinkPad X1    14=ASUS ROG Zephyrus G16  15=HP Spectre x360
-- 16=Anker USB-C Hub       17=Spigen iPhone 15 Case  18=Logitech MX Master 3S
-- 19=Samsung 45W Charger   20=Baseus Power Bank

-- =============================================
-- 5. Customers
-- =============================================
INSERT IGNORE INTO customers (name, email, password_hash, phone, address, date_of_birth, is_active) VALUES
('Rayyan Aamir',      'rayyan.aamir@gmail.com',  '$2b$12$placeholderHashCustomer1111', '0311-1111111', 'House 5, Block A, Karachi',         '1995-01-15', TRUE),
('Ahmed Rashdi',      'ahmed.rashdi@gmail.com',  '$2b$12$placeholderHashCustomer1111', '0312-2222222', 'Flat 3B, DHA Phase 6, Lahore',       '1995-01-15', TRUE),
('Usaid Khan',        'usaid.khan@gmail.com',    '$2b$12$placeholderHashCustomer1111', '0313-3333333', 'Plot 12, G-9/2, Islamabad',          '1995-01-15', TRUE),
('Ayesha Malik',      'ayesha.malik@gmail.com',  '$2b$12$placeholderHashCustomer1111', '0314-4444444', 'House 88, Clifton, Karachi',         '1995-01-15', TRUE),
('Bilal Ahmed',       'bilal.ahmed@gmail.com',   '$2b$12$placeholderHashCustomer1111', '0315-5555555', 'Street 4, Model Town, Lahore',       '1995-01-15', TRUE),
('Zara Khan',         'zara.khan@gmail.com',     '$2b$12$placeholderHashCustomer1111', '0316-6666666', 'Block C, Bahria Town, Rawalpindi',   '1995-01-15', TRUE),
('Hassan Ali',        'hassan.ali@gmail.com',    '$2b$12$placeholderHashCustomer1111', '0317-7777777', 'House 2, F-7, Islamabad',            '1995-01-15', TRUE),
('Mahnoor Siddiqui',  'mahnoor.s@gmail.com',     '$2b$12$placeholderHashCustomer1111', '0318-8888888', 'Flat 5A, Sea View, Karachi',         '1995-01-15', TRUE),
('Raza Shah',         'raza.shah@gmail.com',     '$2b$12$placeholderHashCustomer1111', '0319-9999999', 'Lane 7, Gulberg III, Lahore',        '1995-01-15', TRUE),
('Sana Iqbal',        'sana.iqbal@gmail.com',    '$2b$12$placeholderHashCustomer1111', '0321-0000001', 'House 45, I-8/4, Islamabad',         '1995-01-15', TRUE);

-- customer_id mapping:
--  1=Rayyan  2=Ahmed  3=Usaid  4=Ayesha  5=Bilal
--  6=Zara    7=Hassan 8=Mahnoor 9=Raza  10=Sana

-- =============================================
-- 6. Orders
-- placed_at uses NOW() - INTERVAL n DAY to mirror days_ago
-- =============================================
INSERT INTO orders (customer_id, status, total_amount, placed_at) VALUES
( 1, 'delivered', (49999.00 + 1999.00),   NOW() - INTERVAL 15 DAY),   -- Rayyan: Sony XM5 + Spigen case
( 1, 'confirmed', 159999.00,              NOW() - INTERVAL 14 DAY),   -- Rayyan: Galaxy S24
( 2, 'delivered', (62999.00 + 17999.00),  NOW() - INTERVAL 13 DAY),   -- Ahmed: Bose QC45 + Logitech mouse
( 2, 'confirmed', 249999.00,              NOW() - INTERVAL 12 DAY),   -- Ahmed: Dell XPS 15
( 3, 'delivered', (22999.00 + 14999.00),  NOW() - INTERVAL 11 DAY),   -- Usaid: Sony speaker + JBL Flip
( 3, 'pending',   319999.00,              NOW() - INTERVAL 10 DAY),   -- Usaid: ASUS ROG
( 4, 'delivered', 289999.00,              NOW() - INTERVAL  9 DAY),   -- Ayesha: iPhone 15 Pro
( 4, 'confirmed', (3999.00*2 + 2999.00),  NOW() - INTERVAL  8 DAY),   -- Ayesha: 2x Anker hub + Samsung charger
( 5, 'delivered', (119999.00 + 7999.00),  NOW() - INTERVAL  7 DAY),   -- Bilal: Xiaomi 14 + power bank
( 5, 'pending',   369999.00,              NOW() - INTERVAL  6 DAY),   -- Bilal: MacBook Pro M3
( 6, 'delivered', (18999.00 + 17999.00),  NOW() - INTERVAL  5 DAY),   -- Zara: JBL Tune + Logitech mouse
( 7, 'confirmed', 109999.00,              NOW() - INTERVAL  4 DAY),   -- Hassan: OnePlus 12
( 8, 'delivered', 199999.00,              NOW() - INTERVAL  3 DAY),   -- Mahnoor: HP Spectre
( 9, 'delivered', (129999.00 + 3999.00),  NOW() - INTERVAL  2 DAY),   -- Raza: Pixel 8 + Anker hub
(10, 'confirmed', 219999.00,              NOW() - INTERVAL  1 DAY);   -- Sana: ThinkPad X1

-- order_id mapping (insertion order):
--  1=Rayyan-o1  2=Rayyan-o2  3=Ahmed-o1   4=Ahmed-o2   5=Usaid-o1
--  6=Usaid-o2   7=Ayesha-o1  8=Ayesha-o2  9=Bilal-o1  10=Bilal-o2
-- 11=Zara-o1   12=Hassan-o1 13=Mahnoor-o1 14=Raza-o1  15=Sana-o1

-- =============================================
-- 7. Order Items
-- =============================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1: Rayyan — Sony XM5 + Spigen case
( 1,  1, 1, 49999.00),
( 1, 17, 1,  1999.00),
-- Order 2: Rayyan — Galaxy S24
( 2,  6, 1, 159999.00),
-- Order 3: Ahmed — Bose QC45 + Logitech mouse
( 3,  3, 1, 62999.00),
( 3, 18, 1, 17999.00),
-- Order 4: Ahmed — Dell XPS 15
( 4, 11, 1, 249999.00),
-- Order 5: Usaid — Sony SRS-XB43 + JBL Flip 6
( 5,  4, 1, 22999.00),
( 5,  5, 1, 14999.00),
-- Order 6: Usaid — ASUS ROG
( 6, 14, 1, 319999.00),
-- Order 7: Ayesha — iPhone 15 Pro
( 7,  7, 1, 289999.00),
-- Order 8: Ayesha — 2x Anker hub + Samsung charger
( 8, 16, 2,  3999.00),
( 8, 19, 1,  2999.00),
-- Order 9: Bilal — Xiaomi 14 + power bank
( 9,  8, 1, 119999.00),
( 9, 20, 1,   7999.00),
-- Order 10: Bilal — MacBook Pro M3
(10, 12, 1, 369999.00),
-- Order 11: Zara — JBL Tune 760NC + Logitech mouse
(11,  2, 1, 18999.00),
(11, 18, 1, 17999.00),
-- Order 12: Hassan — OnePlus 12
(12,  9, 1, 109999.00),
-- Order 13: Mahnoor — HP Spectre x360
(13, 15, 1, 199999.00),
-- Order 14: Raza — Google Pixel 8 + Anker hub
(14, 10, 1, 129999.00),
(14, 16, 1,   3999.00),
-- Order 15: Sana — ThinkPad X1 Carbon
(15, 13, 1, 219999.00);

-- =============================================
-- 8. Payments (only confirmed/delivered orders)
-- =============================================
INSERT IGNORE INTO payments (order_id, method, status, amount, paid_at) VALUES
( 1, 'credit_card',       'completed', (49999.00 + 1999.00),   NOW() - INTERVAL 15 DAY + INTERVAL 10 MINUTE),
( 2, 'debit_card',        'completed', 159999.00,              NOW() - INTERVAL 14 DAY + INTERVAL 10 MINUTE),
( 3, 'bank_transfer',     'completed', (62999.00 + 17999.00),  NOW() - INTERVAL 13 DAY + INTERVAL 10 MINUTE),
( 4, 'cash_on_delivery',  'completed', 249999.00,              NOW() - INTERVAL 12 DAY + INTERVAL 10 MINUTE),
( 5, 'credit_card',       'completed', (22999.00 + 14999.00),  NOW() - INTERVAL 11 DAY + INTERVAL 10 MINUTE),
( 7, 'bank_transfer',     'completed', 289999.00,              NOW() - INTERVAL  9 DAY + INTERVAL 10 MINUTE),
( 8, 'cash_on_delivery',  'completed', (3999.00*2 + 2999.00),  NOW() - INTERVAL  8 DAY + INTERVAL 10 MINUTE),
( 9, 'credit_card',       'completed', (119999.00 + 7999.00),  NOW() - INTERVAL  7 DAY + INTERVAL 10 MINUTE),
(11, 'debit_card',        'completed', (18999.00 + 17999.00),  NOW() - INTERVAL  5 DAY + INTERVAL 10 MINUTE),
(12, 'bank_transfer',     'completed', 109999.00,              NOW() - INTERVAL  4 DAY + INTERVAL 10 MINUTE),
(13, 'cash_on_delivery',  'completed', 199999.00,              NOW() - INTERVAL  3 DAY + INTERVAL 10 MINUTE),
(14, 'credit_card',       'completed', (129999.00 + 3999.00),  NOW() - INTERVAL  2 DAY + INTERVAL 10 MINUTE),
(15, 'debit_card',        'completed', 219999.00,              NOW() - INTERVAL  1 DAY + INTERVAL 10 MINUTE);

-- =============================================
-- 9. Reviews
-- =============================================
INSERT IGNORE INTO reviews (customer_id, product_id, rating, comment, sentiment_score) VALUES
( 1,  1, 5, 'Absolutely incredible noise cancellation, worth every rupee!',          0.92),
( 1, 17, 4, 'Good case, fits perfectly and feels sturdy.',                            0.75),
( 1,  6, 5, 'Samsung Galaxy S24 is a beast! Camera is outstanding.',                 0.90),
( 2,  3, 5, 'Bose never disappoints. Premium sound and comfort.',                    0.88),
( 2, 18, 4, 'Smooth scrolling, ergonomic design. Great for work.',                   0.78),
( 2, 11, 5, 'Dell XPS 15 OLED display is absolutely stunning.',                      0.91),
( 3,  4, 4, 'Sony speaker has great bass. Good for outdoor use.',                    0.72),
( 3,  5, 5, 'JBL Flip 6 is perfect for pool parties. Waterproof works!',             0.85),
( 4,  7, 5, 'iPhone 15 Pro is gorgeous. Titanium build feels premium.',              0.93),
( 4, 16, 4, 'Anker hub works flawlessly with my MacBook.',                           0.76),
( 4, 19, 3, 'Charger works but cable feels a bit flimsy.',                           0.50),
( 5,  8, 5, 'Xiaomi 14 camera is insane for this price. Leica magic.',               0.89),
( 5, 20, 4, '65W charging is so fast. Saved me multiple times.',                     0.80),
( 6,  2, 4, 'JBL Tune 760NC has decent ANC at this price.',                          0.70),
( 6, 18, 5, 'Best mouse I have ever used. MagSpeed scroll is addictive.',            0.95),
( 7,  9, 4, 'OnePlus 12 is incredibly fast. OxygenOS is clean.',                     0.82),
( 8, 15, 5, 'HP Spectre x360 is beautiful and powerful. Love the OLED.',             0.90),
( 9, 10, 4, 'Pixel 8 camera AI features are genuinely impressive.',                  0.83),
( 9, 16, 5, 'Anker hub saved my laptop workflow completely.',                         0.87),
(10, 13, 5, 'ThinkPad build quality is unmatched. Business laptop king.',            0.91),
( 1,  5, 3, 'JBL Flip 6 bass is okay but expected more loudness.',                   0.48),
( 2, 20, 5, 'Baseus power bank charges my laptop. Incredible value.',                0.88),
( 3,  7, 4, 'iPhone 15 Pro is great but very expensive for Pakistan.',               0.65),
( 4,  8, 5, 'Xiaomi 14 exceeded all my expectations. Flagship killer!',              0.92),
( 5, 11, 4, 'Dell XPS runs cool and silent under load.',                             0.78),
( 6,  9, 3, 'OnePlus 12 gets warm during gaming. Otherwise great.',                  0.52),
( 7,  1, 5, 'Sony WH-1000XM5 is the gold standard of headphones.',                   0.96),
( 8,  6, 4, 'Galaxy S24 AI features useful but gimmicky at times.',                  0.68),
( 9, 12, 5, 'MacBook Pro M3 performance is otherworldly. Best laptop.',              0.94),
(10, 14, 4, 'ASUS ROG thermal performance impressive. Gaming beast.',                0.79);

-- =============================================
-- 10. Cart
-- =============================================
INSERT IGNORE INTO cart (customer_id, product_id, quantity) VALUES
( 1,  8, 1),
( 1, 20, 2),
( 2,  5, 1),
( 2, 19, 1),
( 3,  7, 1),
( 4, 10, 1),
( 5, 15, 1),
( 6, 12, 1),
( 7, 18, 1),
( 8,  1, 1),
( 9,  6, 1),
(10, 14, 1);

-- =============================================
-- 11. Recommendations (5 per customer)
-- =============================================
INSERT IGNORE INTO recommendations (customer_id, product_id, score, explanation) VALUES
-- Rayyan (1)
( 1,  8, 0.9120, 'Based on your Sony headphones purchase, you may love Xiaomi 14s audio features.'),
( 1, 12, 0.8850, 'You purchased a Dell laptop — the MacBook Pro M3 is a premium alternative worth considering.'),
( 1, 20, 0.8640, 'Customers who bought Sony XM5 frequently pair it with the Baseus power bank.'),
( 1,  4, 0.8310, 'Your interest in audio gear makes the Sony SRS-XB43 speaker a strong match.'),
( 1, 16, 0.8100, 'The Anker hub complements your existing tech purchases perfectly.'),
-- Ahmed (2)
( 2, 10, 0.9230, 'Based on your Xiaomi 14 interest, Google Pixel 8 offers a pure Android alternative.'),
( 2, 15, 0.8970, 'You own a Dell XPS — the HP Spectre x360 offers a versatile 2-in-1 experience.'),
( 2,  2, 0.8550, 'Customers who bought Bose QC45 also enjoy JBL Tune 760NC as a portable option.'),
( 2, 20, 0.8200, 'The Baseus power bank is highly rated by customers who own multiple devices.'),
( 2, 17, 0.7980, 'A Spigen case is a popular pairing with your iPhone interest.'),
-- Usaid (3)
( 3,  7, 0.9410, 'You browsed mobiles frequently — iPhone 15 Pro is your top match.'),
( 3, 11, 0.8800, 'Customers in your category love the Dell XPS 15 for productivity.'),
( 3, 18, 0.8620, 'The Logitech MX Master 3S is top-rated by power users like you.'),
( 3, 13, 0.8300, 'ThinkPad X1 Carbon suits your interest in durable, professional devices.'),
( 3, 20, 0.8050, 'The Baseus power bank is frequently bought with mobile accessories.'),
-- Ayesha (4)
( 4,  9, 0.9300, 'Based on your iPhone purchase, OnePlus 12 is a popular alternative in your price range.'),
( 4, 12, 0.8760, 'MacBook Pro M3 is a natural next step for iPhone 15 Pro owners.'),
( 4,  1, 0.8540, 'Sony WH-1000XM5 is highly recommended for iPhone users seeking premium audio.'),
( 4, 18, 0.8210, 'Logitech MX Master 3S pairs beautifully with your MacBook ecosystem.'),
( 4, 14, 0.7990, 'ASUS ROG is a popular pick among customers who own high-end mobile devices.'),
-- Bilal (5)
( 5, 10, 0.9180, 'Based on your Xiaomi 14 purchase, Google Pixel 8 is a complementary choice.'),
( 5, 15, 0.8830, 'HP Spectre x360 is a top pick for customers who own flagship smartphones.'),
( 5,  1, 0.8610, 'Sony WH-1000XM5 is frequently paired with mobile flagship purchases.'),
( 5, 16, 0.8290, 'Anker hub is a must-have accessory for multi-device users.'),
( 5, 19, 0.8070, 'Samsung charger is highly compatible with your existing devices.'),
-- Zara (6)
( 6,  3, 0.9050, 'Customers who own JBL Tune 760NC often upgrade to Bose QuietComfort 45.'),
( 6, 11, 0.8720, 'Dell XPS 15 is a top recommendation for users who own wireless mice.'),
( 6,  7, 0.8490, 'iPhone 15 Pro is popular among customers in your browsing category.'),
( 6, 20, 0.8150, 'Power bank is a top buy for customers with multiple wireless accessories.'),
( 6, 17, 0.7930, 'Spigen case is a popular companion for mobile-focused shoppers.'),
-- Hassan (7)
( 7,  8, 0.9270, 'Based on your OnePlus 12 purchase, Xiaomi 14 is a Leica-camera alternative.'),
( 7,  2, 0.8810, 'JBL Tune 760NC is a popular wireless headphone choice for OnePlus users.'),
( 7, 16, 0.8560, 'Anker USB-C hub is highly recommended for Android phone owners.'),
( 7, 19, 0.8220, 'Samsung 45W charger is compatible with your OnePlus and charges faster.'),
( 7, 20, 0.8010, 'Power bank complements your on-the-go mobile usage perfectly.'),
-- Mahnoor (8)
( 8,  6, 0.9120, 'Customers who own HP Spectre often pair it with Galaxy S24 for mobile productivity.'),
( 8,  3, 0.8780, 'Bose QC45 is a premium audio upgrade recommended for laptop owners.'),
( 8, 16, 0.8530, 'Anker hub expands your HP Spectre connectivity significantly.'),
( 8, 18, 0.8190, 'Logitech MX Master 3S is the top mouse choice for HP Spectre users.'),
( 8, 13, 0.7980, 'ThinkPad X1 Carbon is a business-oriented alternative to your HP Spectre.'),
-- Raza (9)
( 9, 11, 0.9340, 'Based on your Pixel 8 purchase, Dell XPS 15 is a top laptop recommendation.'),
( 9,  1, 0.8870, 'Sony WH-1000XM5 is highly rated by Google Pixel users for audio quality.'),
( 9,  8, 0.8640, 'Xiaomi 14 is a popular upgrade for customers who enjoy camera-focused phones.'),
( 9, 18, 0.8280, 'Logitech MX Master 3S is a productivity essential for multi-device users.'),
( 9, 14, 0.8020, 'ASUS ROG is a popular choice among tech-savvy customers like you.'),
-- Sana (10)
(10,  7, 0.9250, 'Based on your ThinkPad interest, iPhone 15 Pro rounds out a premium ecosystem.'),
(10, 12, 0.8890, 'MacBook Pro M3 is a natural companion to your ThinkPad for cross-platform work.'),
(10,  1, 0.8610, 'Sony WH-1000XM5 is the go-to headphone for professionals who own ThinkPads.'),
(10, 18, 0.8300, 'Logitech MX Master 3S is the most popular mouse among ThinkPad users.'),
(10, 16, 0.8080, 'Anker hub is essential for expanding your ThinkPad USB-C ports.');