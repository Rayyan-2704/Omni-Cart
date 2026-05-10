-- =============================================
-- OmniCart - Complex SQL Queries
-- Equivalent of queries.py for project evaluation
-- =============================================

USE omnicart_db;


-- =============================================================
-- Query 1: Customer Full Order History
-- JOIN: customers => orders => order_items => products
-- Used by: Customer portal order history page
-- =============================================================

SELECT
    o.order_id,
    o.status,
    o.placed_at,
    p.name AS product_name,
    p.brand,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS subtotal,
    o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE c.customer_id = 1          -- replace with target customer_id
ORDER BY o.placed_at DESC;


-- =============================================================
-- Query 2: Platform Revenue Report by Month
-- Aggregates: SUM, COUNT, AVG, DATE_FORMAT (built-in)
-- =============================================================

SELECT
    DATE_FORMAT(o.placed_at, '%Y-%m') AS month,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY DATE_FORMAT(o.placed_at, '%Y-%m')
ORDER BY DATE_FORMAT(o.placed_at, '%Y-%m') DESC
LIMIT 12;


-- =============================================================
-- Query 3: Top Customers by Spend
-- JOIN + Aggregate + HAVING + correlated subquery
-- =============================================================

SELECT
    c.customer_id,
    c.name,
    c.email,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_spent,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    (
        SELECT COUNT(*)
        FROM reviews r
        WHERE r.customer_id = c.customer_id
    ) AS review_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status != 'cancelled'
GROUP BY c.customer_id, c.name, c.email
HAVING COUNT(DISTINCT o.order_id) >= 1  -- replace with target min_orders
ORDER BY total_spent DESC
LIMIT 20;


-- =============================================================
-- Query 4: Vendor Sales Performance
-- Multi-table LEFT JOIN + aggregates + COALESCE
-- =============================================================

SELECT
    v.vendor_id,
    v.store_name,
    v.name AS vendor_name,
    v.is_approved,
    COUNT(DISTINCT p.product_id) AS product_count,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(ROUND(SUM(oi.quantity * oi.unit_price), 2), 0) AS total_revenue,
    COALESCE(ROUND(AVG(r.rating), 1), 0.0) AS avg_rating,
    COALESCE(COUNT(DISTINCT r.review_id), 0) AS total_reviews
FROM vendors v
LEFT JOIN products p ON v.vendor_id = p.vendor_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id  = r.product_id
WHERE v.is_active = TRUE
GROUP BY v.vendor_id, v.store_name, v.name, v.is_approved
ORDER BY total_revenue DESC;


-- ====================================================================
-- Query 5: Category Sentiment & Rating Analysis
-- Multi-level JOIN + AVG aggregate + correlated subquery + GROUP BY
-- ====================================================================

SELECT
    c.category_id,
    c.name AS category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    COALESCE(ROUND(AVG(r.rating), 2), 0.0) AS avg_rating,
    COALESCE(ROUND(AVG(r.sentiment_score), 2), 0.0) AS avg_sentiment,
    (
        SELECT COUNT(DISTINCT p2.product_id)
        FROM products p2
        JOIN reviews r2 ON p2.product_id = r2.product_id
        WHERE p2.category_id = c.category_id
          AND r2.sentiment_score >= 0.7
    ) AS positive_products
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN reviews r ON p.product_id = r.product_id
WHERE p.is_active = TRUE
GROUP BY c.category_id, c.name
ORDER BY avg_sentiment DESC;