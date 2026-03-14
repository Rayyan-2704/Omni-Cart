-- =============================================
-- OmniCart Role-Based Queries
-- CS 2005: Database Systems | Spring 2026
-- Includes: JOINs, Aggregate Functions,
--           Built-in SQL Functions, Dynamic Input
-- =============================================

USE omnicart;

-- =============================================
-- CUSTOMER QUERIES
-- =============================================

-- Query C1: Full order history with product details
-- Uses: JOIN (4 tables), DATE_FORMAT, dynamic input
SELECT
    c.name                                  AS customer_name,
    o.order_id,
    p.name                                  AS product_name,
    p.brand,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price)           AS subtotal,
    o.status,
    DATE_FORMAT(o.placed_at, '%d %M %Y')   AS order_date
FROM customers   c
JOIN orders      o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products    p  ON oi.product_id = p.product_id
WHERE c.customer_id = 1          -- dynamic: replace with logged-in customer_id
ORDER BY o.placed_at DESC;


-- Query C2: Search products by keyword and category
-- Uses: JOIN, LIKE, WHERE with dynamic input, ORDER BY
SELECT
    p.product_id,
    p.name                                  AS product_name,
    p.brand,
    p.price,
    p.stock_qty,
    p.rating,
    c.name                                  AS category
FROM products    p
JOIN categories  c ON p.category_id = c.category_id
WHERE p.name LIKE '%Samsung%'       -- dynamic: replace with search keyword
  AND p.is_active = TRUE
ORDER BY p.rating DESC;


-- Query C3: View AI recommendations with product details
-- Uses: JOIN, ORDER BY, DATE_FORMAT, dynamic input
SELECT
    r.rec_id,
    p.name                                  AS recommended_product,
    p.brand,
    p.price,
    p.rating,
    r.score                                 AS confidence_score,
    r.reason                                AS ai_explanation,
    DATE_FORMAT(r.generated_at, '%d %M %Y') AS recommended_on
FROM recommendations r
JOIN products        p ON r.product_id = p.product_id
WHERE r.customer_id = 1             -- dynamic: replace with logged-in customer_id
ORDER BY r.score DESC;


-- Query C4: Payment status for all customer orders
-- Uses: JOIN, ENUM status display, DATE_FORMAT, dynamic input
SELECT
    o.order_id,
    o.total_amount,
    o.status                                AS order_status,
    pay.method                              AS payment_method,
    pay.status                              AS payment_status,
    DATE_FORMAT(pay.paid_at, '%d %M %Y %H:%i') AS paid_on
FROM orders   o
JOIN payments pay ON o.order_id = pay.order_id
WHERE o.customer_id = 2             -- dynamic: replace with logged-in customer_id
ORDER BY o.placed_at DESC;


-- =============================================
-- VENDOR / SELLER QUERIES
-- =============================================

-- Query V1: Sales summary — revenue and units sold per product
-- Uses: JOIN (4 tables), SUM, COUNT, AVG, GROUP BY, HAVING
SELECT
    p.product_id,
    p.name                                  AS product_name,
    p.brand,
    SUM(oi.quantity)                        AS total_units_sold,
    SUM(oi.quantity * oi.unit_price)        AS total_revenue,
    AVG(r.rating)                           AS avg_rating,
    COUNT(r.review_id)                      AS total_reviews
FROM products    p
JOIN order_items oi ON p.product_id  = oi.product_id
JOIN orders      o  ON oi.order_id   = o.order_id
LEFT JOIN reviews r ON p.product_id  = r.product_id
WHERE p.vendor_id = 1               -- dynamic: replace with logged-in vendor_id
  AND o.status != 'cancelled'
GROUP BY p.product_id
ORDER BY total_revenue DESC;


-- Query V2: Low stock alert with CASE statement
-- Uses: JOIN, CASE, WHERE, ORDER BY, dynamic input
SELECT
    p.product_id,
    p.name                                  AS product_name,
    p.brand,
    c.name                                  AS category,
    p.stock_qty,
    p.price,
    CASE
        WHEN p.stock_qty = 0  THEN 'OUT OF STOCK'
        WHEN p.stock_qty < 5  THEN 'CRITICAL'
        WHEN p.stock_qty < 15 THEN 'LOW'
        ELSE 'OK'
    END                                     AS stock_status
FROM products   p
JOIN categories c ON p.category_id = c.category_id
WHERE p.vendor_id  = 1             -- dynamic: replace with logged-in vendor_id
  AND p.stock_qty  < 15
ORDER BY p.stock_qty ASC;


-- Query V3: Product performance with sentiment analysis scores
-- Uses: LEFT JOIN, AVG, MAX, MIN, COUNT, GROUP BY
SELECT
    p.name                                  AS product_name,
    COUNT(r.review_id)                      AS total_reviews,
    ROUND(AVG(r.rating), 2)                 AS avg_star_rating,
    ROUND(AVG(r.sentiment_score), 3)        AS avg_sentiment,
    MAX(r.sentiment_score)                  AS best_review_score,
    MIN(r.sentiment_score)                  AS worst_review_score
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
WHERE p.vendor_id = 1               -- dynamic: replace with logged-in vendor_id
GROUP BY p.product_id
ORDER BY avg_sentiment DESC;


-- Query V4: Pending order fulfillment list
-- Uses: JOIN (4 tables), IN clause, ORDER BY, dynamic input
SELECT
    o.order_id,
    c.name                                  AS customer_name,
    c.phone,
    c.address,
    p.name                                  AS product_name,
    oi.quantity,
    o.status,
    DATE_FORMAT(o.placed_at, '%d %M %Y')   AS order_date
FROM orders      o
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products    p  ON oi.product_id = p.product_id
JOIN customers   c  ON o.customer_id = c.customer_id
WHERE p.vendor_id = 1               -- dynamic: replace with logged-in vendor_id
  AND o.status IN ('pending', 'confirmed', 'shipped')
ORDER BY o.placed_at ASC;


-- =============================================
-- ADMINISTRATOR QUERIES
-- =============================================

-- Query A1: Platform revenue report by month
-- Uses: DATE_FORMAT, COUNT DISTINCT, SUM, AVG, GROUP BY, ORDER BY
SELECT
    DATE_FORMAT(o.placed_at, '%M %Y')       AS month,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    COUNT(DISTINCT o.customer_id)           AS unique_customers,
    SUM(o.total_amount)                     AS total_revenue,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY DATE_FORMAT(o.placed_at, '%M %Y'),
         DATE_FORMAT(o.placed_at, '%Y-%m')
ORDER BY DATE_FORMAT(o.placed_at, '%Y-%m') DESC;


-- Query A2: Top rated products (uses TopRatedProducts VIEW)
-- Uses: VIEW, LIMIT
SELECT * FROM TopRatedProducts
LIMIT 10;


-- Query A3: Customer activity report with tier classification
-- Uses: LEFT JOIN, COUNT, SUM, MAX, CASE, GROUP BY, HAVING, ORDER BY
SELECT
    c.customer_id,
    c.name                                  AS customer_name,
    c.email,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    COALESCE(SUM(o.total_amount), 0)        AS total_spent,
    MAX(DATE_FORMAT(o.placed_at, '%d %M %Y')) AS last_order_date,
    CASE
        WHEN COUNT(o.order_id) >= 5 THEN 'VIP'
        WHEN COUNT(o.order_id) >= 2 THEN 'Regular'
        ELSE 'New'
    END                                     AS customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id
HAVING total_orders > 0
ORDER BY total_spent DESC;


-- Query A4: Full vendor performance overview
-- Uses: JOIN (4 tables), LEFT JOIN, COUNT DISTINCT, SUM, AVG, GROUP BY
SELECT
    v.store_name,
    v.email                                 AS vendor_email,
    COUNT(DISTINCT p.product_id)            AS total_products,
    SUM(oi.quantity)                        AS total_units_sold,
    SUM(oi.quantity * oi.unit_price)        AS total_revenue,
    ROUND(AVG(r.rating), 2)                 AS avg_product_rating,
    ROUND(AVG(r.sentiment_score), 3)        AS avg_sentiment_score
FROM vendors     v
JOIN products    p  ON v.vendor_id   = p.vendor_id
JOIN order_items oi ON p.product_id  = oi.product_id
JOIN orders      o  ON oi.order_id   = o.order_id
LEFT JOIN reviews r ON p.product_id  = r.product_id
WHERE o.status     != 'cancelled'
  AND v.is_approved = TRUE
GROUP BY v.vendor_id
ORDER BY total_revenue DESC;


-- Query A5: Platform-wide orders overview with filters
-- Uses: JOIN (3 tables), DATE_FORMAT, WHERE with dynamic date range
SELECT
    o.order_id,
    c.name                                  AS customer_name,
    c.email,
    o.total_amount,
    o.status,
    pay.method                              AS payment_method,
    pay.status                              AS payment_status,
    DATE_FORMAT(o.placed_at, '%d %M %Y')   AS order_date
FROM orders   o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN payments  pay ON o.order_id    = pay.order_id
WHERE o.placed_at BETWEEN '2026-01-01' AND '2026-12-31'  -- dynamic date range
ORDER BY o.placed_at DESC;


-- Query A6: Vendor Sales Summary (uses VendorSalesSummary VIEW)
SELECT * FROM VendorSalesSummary
ORDER BY total_revenue DESC;
