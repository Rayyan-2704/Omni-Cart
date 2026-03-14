-- =============================================
-- OmniCart Database Schema
-- CS 2005: Database Systems | Spring 2026
-- Namal University
-- Group: Rayyan Aamir | Ahmed Shah | Usaid Khan
-- =============================================

CREATE DATABASE IF NOT EXISTS omnicart;
USE omnicart;

-- =============================================
-- TABLE 1: customers
-- =============================================
CREATE TABLE customers (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    phone         VARCHAR(20),
    address       TEXT,
    dob           DATE,
    is_active     BOOLEAN       DEFAULT TRUE,
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 2: vendors
-- =============================================
CREATE TABLE vendors (
    vendor_id     INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    store_name    VARCHAR(150),
    phone         VARCHAR(20),
    is_approved   BOOLEAN       DEFAULT FALSE,
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLE 3: categories
-- =============================================
CREATE TABLE categories (
    category_id        INT AUTO_INCREMENT PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    description        TEXT,
    parent_category_id INT          DEFAULT NULL,
    FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
);

-- =============================================
-- TABLE 4: products
-- =============================================
CREATE TABLE products (
    product_id  INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id   INT            NOT NULL,
    category_id INT            NOT NULL,
    name        VARCHAR(200)   NOT NULL,
    description TEXT,
    price       DECIMAL(10,2)  NOT NULL,
    stock_qty   INT            DEFAULT 0,
    brand       VARCHAR(100),
    rating      DECIMAL(3,2)   DEFAULT 0.00,
    is_active   BOOLEAN        DEFAULT TRUE,
    created_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id)
        REFERENCES vendors(vendor_id)
        ON DELETE CASCADE,
    FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
);

-- =============================================
-- TABLE 5: orders
-- =============================================
CREATE TABLE orders (
    order_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT           NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status       ENUM('pending','confirmed','shipped','delivered','cancelled')
                               DEFAULT 'pending',
    placed_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
);

-- =============================================
-- TABLE 6: order_items
-- =============================================
CREATE TABLE order_items (
    item_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT           NOT NULL,
    product_id INT           NOT NULL,
    quantity   INT           NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
);

-- =============================================
-- TABLE 7: payments
-- =============================================
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT           NOT NULL,
    method     ENUM('cash','card','bank_transfer','wallet') NOT NULL,
    status     ENUM('pending','completed','failed','refunded')
                             DEFAULT 'pending',
    amount     DECIMAL(10,2) NOT NULL,
    paid_at    TIMESTAMP     NULL,
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
);

-- =============================================
-- TABLE 8: reviews
-- =============================================
CREATE TABLE reviews (
    review_id       INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT           NOT NULL,
    product_id      INT           NOT NULL,
    rating          INT           NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    sentiment_score DECIMAL(4,3)  DEFAULT NULL,
    created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);

-- =============================================
-- TABLE 9: recommendations
-- =============================================
CREATE TABLE recommendations (
    rec_id       INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT           NOT NULL,
    product_id   INT           NOT NULL,
    score        DECIMAL(5,4)  NOT NULL,
    reason       TEXT,
    generated_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);

-- =============================================
-- VIEWS
-- =============================================

-- View 1: Customer Order History
CREATE VIEW CustomerOrderHistory AS
SELECT
    c.name                              AS customer_name,
    c.email,
    o.order_id,
    p.name                              AS product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price)       AS subtotal,
    o.status,
    o.placed_at
FROM customers c
JOIN orders      o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products    p  ON oi.product_id = p.product_id;

-- View 2: Top Rated Products
CREATE VIEW TopRatedProducts AS
SELECT
    p.product_id,
    p.name                              AS product_name,
    p.brand,
    c.name                              AS category,
    AVG(r.rating)                       AS avg_rating,
    COUNT(r.review_id)                  AS total_reviews,
    p.price,
    p.stock_qty
FROM products   p
JOIN reviews    r ON p.product_id   = r.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY p.product_id
HAVING avg_rating >= 4.0
ORDER BY avg_rating DESC;

-- View 3: Vendor Sales Summary
CREATE VIEW VendorSalesSummary AS
SELECT
    v.vendor_id,
    v.store_name,
    p.name                              AS product_name,
    SUM(oi.quantity)                    AS total_units_sold,
    SUM(oi.quantity * oi.unit_price)    AS total_revenue,
    AVG(r.rating)                       AS avg_product_rating
FROM vendors     v
JOIN products    p  ON v.vendor_id   = p.vendor_id
JOIN order_items oi ON p.product_id  = oi.product_id
LEFT JOIN reviews r ON p.product_id  = r.product_id
GROUP BY v.vendor_id, p.product_id;

-- =============================================
-- VERIFY
-- =============================================
SHOW TABLES;
