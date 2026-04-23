-- =============================================
-- OmniCart Database Schema
-- =============================================
CREATE DATABASE IF NOT EXISTS omnicart_db;
USE omnicart_db;

-- =============================================
-- TABLES
-- =============================================

-- 1. Customers
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) CHECK (phone REGEXP '^03[0-9]{2}-[0-9]{7}$'),
    address TEXT,
    date_of_birth DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Vendors
CREATE TABLE vendors (
    vendor_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    password_hash VARCHAR(255) NOT NULL,
    store_name VARCHAR(150),
    phone VARCHAR(20) CHECK (phone REGEXP '^03[0-9]{2}-[0-9]{7}$'),
    is_approved BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_category_id INT DEFAULT NULL,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
		ON DELETE SET NULL
		ON UPDATE CASCADE
);

-- 4. Products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_qty INT DEFAULT 0,
    brand VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
		ON DELETE RESTRICT
        ON UPDATE CASCADE,
    INDEX idx_vendor (vendor_id),
    INDEX idx_category (category_id)
);

-- 5. Orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    status ENUM('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_customer (customer_id)
);

-- 6. Order Items
CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
		ON DELETE RESTRICT
        ON UPDATE CASCADE,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
);

-- 7. Payments
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    method ENUM('credit_card', 'debit_card', 'cash_on_delivery', 'bank_transfer') NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    amount DECIMAL(10, 2) NOT NULL,
    paid_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

-- 8. Reviews
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    sentiment_score DECIMAL(3, 2) DEFAULT NULL CHECK (sentiment_score BETWEEN 0.00 AND 1.00),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY unique_review (customer_id, product_id),
    INDEX idx_product (product_id)
);

-- 9. Recommendations
CREATE TABLE recommendations (
    rec_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    score DECIMAL(5, 4) NOT NULL CHECK (score BETWEEN 0.0000 AND 1.0000),
    explanation TEXT,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_customer (customer_id),
    UNIQUE KEY unique_recommendation (customer_id, product_id)
);

-- 10. Cart
CREATE TABLE cart (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY unique_cart_item (customer_id, product_id),
    INDEX idx_customer (customer_id)
);

-- 11. Admin
CREATE TABLE admins (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- VIEWS
-- =============================================

-- 1. Customer Order History
CREATE VIEW CustomerOrderHistory AS
SELECT c.name AS customer_name, c.email, o.order_id, p.name AS product_name, oi.quantity, oi.unit_price, 
	  (oi.quantity * oi.unit_price) AS subtotal, o.status, o.placed_at
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;

--  2. Top Rated Products
CREATE VIEW TopRatedProducts AS
SELECT p.product_id, p.name AS product_name, p.brand, c.name AS category, ROUND(AVG(r.rating), 1) AS avg_rating,
       COUNT(r.review_id) AS total_reviews, p.price, p.stock_qty
FROM products p
JOIN reviews r ON p.product_id = r.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY p.product_id
HAVING avg_rating >= 3.5
ORDER BY avg_rating DESC;

-- 3. Vendor Sales Summary
CREATE VIEW VendorSalesSummary AS
SELECT v.vendor_id, v.store_name, p.name AS product_name, COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
	   COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue, COALESCE(ROUND(AVG(r.rating), 1), 0.0) AS avg_product_rating
FROM vendors v
JOIN products p ON v.vendor_id = p.vendor_id
LEFT JOIN order_items oi ON p.product_id  = oi.product_id
LEFT JOIN reviews r ON p.product_id  = r.product_id
GROUP BY v.vendor_id, p.product_id;

SHOW tables;