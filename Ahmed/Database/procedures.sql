-- =============================================
-- OmniCart Stored Procedures
-- Run AFTER schema.sql and seed.sql
-- CS 2005: Database Systems | Spring 2026
-- =============================================

USE omnicart;

-- =============================================
-- PROCEDURE 1: CUSTOMER ROLE
-- PlaceOrder — atomic order placement
-- Usage: CALL PlaceOrder(customer_id, product_id, quantity, unit_price);
-- =============================================
DROP PROCEDURE IF EXISTS PlaceOrder;

DELIMITER $$

CREATE PROCEDURE PlaceOrder(
    IN p_customer_id INT,
    IN p_product_id  INT,
    IN p_quantity    INT,
    IN p_unit_price  DECIMAL(10,2)
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_stock    INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order placement failed. Transaction rolled back.';
    END;

    -- Step 1: Check stock availability
    SELECT stock_qty INTO v_stock
    FROM products
    WHERE product_id = p_product_id;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock. Order cannot be placed.';
    END IF;

    START TRANSACTION;

        -- Step 2: Insert new order record
        INSERT INTO orders (customer_id, total_amount, status)
        VALUES (p_customer_id, (p_quantity * p_unit_price), 'confirmed');

        SET v_order_id = LAST_INSERT_ID();

        -- Step 3: Insert order item record
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, p_product_id, p_quantity, p_unit_price);

        -- Step 4: Deduct stock from products table
        UPDATE products
        SET stock_qty = stock_qty - p_quantity
        WHERE product_id = p_product_id;

    COMMIT;

    -- Return result
    SELECT
        v_order_id              AS new_order_id,
        p_customer_id           AS customer_id,
        p_product_id            AS product_id,
        p_quantity              AS quantity_ordered,
        (p_quantity*p_unit_price) AS total_amount,
        'confirmed'             AS status,
        'Order placed successfully!' AS message;

END$$

DELIMITER ;


-- =============================================
-- PROCEDURE 2: VENDOR / SELLER ROLE
-- UpdateProductInventory — safe stock + price update
-- Usage: CALL UpdateProductInventory(product_id, vendor_id, new_stock, new_price);
-- =============================================
DROP PROCEDURE IF EXISTS UpdateProductInventory;

DELIMITER $$

CREATE PROCEDURE UpdateProductInventory(
    IN p_product_id INT,
    IN p_vendor_id  INT,
    IN p_new_stock  INT,
    IN p_new_price  DECIMAL(10,2)
)
BEGIN
    DECLARE v_owner_id INT;

    -- Step 1: Verify product belongs to this vendor
    SELECT vendor_id INTO v_owner_id
    FROM products
    WHERE product_id = p_product_id;

    IF v_owner_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product not found.';
    END IF;

    IF v_owner_id != p_vendor_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access denied. This product does not belong to your store.';
    END IF;

    -- Step 2: Validate inputs
    IF p_new_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock quantity cannot be negative.';
    END IF;

    IF p_new_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Price must be greater than zero.';
    END IF;

    -- Step 3: Apply the update
    UPDATE products
    SET stock_qty = p_new_stock,
        price     = p_new_price
    WHERE product_id = p_product_id;

    -- Return result
    SELECT
        p_product_id            AS product_id,
        p_new_stock             AS updated_stock,
        p_new_price             AS updated_price,
        'Inventory updated successfully!' AS message;

END$$

DELIMITER ;


-- =============================================
-- PROCEDURE 3: ADMINISTRATOR ROLE
-- DeactivateUser — deactivate account + cancel pending orders
-- Usage: CALL DeactivateUser(customer_id, reason);
-- =============================================
DROP PROCEDURE IF EXISTS DeactivateUser;

DELIMITER $$

CREATE PROCEDURE DeactivateUser(
    IN p_customer_id INT,
    IN p_reason      VARCHAR(255)
)
BEGIN
    DECLARE v_count           INT;
    DECLARE v_cancelled_orders INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Deactivation failed. Transaction rolled back.';
    END;

    -- Step 1: Check customer exists and is currently active
    SELECT COUNT(*) INTO v_count
    FROM customers
    WHERE customer_id = p_customer_id
      AND is_active   = TRUE;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Customer not found or already inactive.';
    END IF;

    START TRANSACTION;

        -- Step 2: Deactivate the customer account
        UPDATE customers
        SET is_active = FALSE
        WHERE customer_id = p_customer_id;

        -- Step 3: Cancel all pending/confirmed orders
        UPDATE orders
        SET status = 'cancelled'
        WHERE customer_id = p_customer_id
          AND status IN ('pending', 'confirmed');

        -- Count how many orders were cancelled
        SET v_cancelled_orders = ROW_COUNT();

    COMMIT;

    -- Return result
    SELECT
        p_customer_id           AS deactivated_customer_id,
        p_reason                AS reason,
        v_cancelled_orders      AS orders_cancelled,
        'Customer account deactivated and pending orders cancelled successfully.' AS message;

END$$

DELIMITER ;


-- =============================================
-- TEST ALL 3 PROCEDURES
-- =============================================

-- Test 1: Customer places an order
-- Customer 3 buys product 5 (Men Casual Shirt), qty 1 at 2500
CALL PlaceOrder(3, 5, 1, 2500.00);

-- Test 2: Vendor updates product inventory
-- Vendor 1 updates product 1 (Samsung Galaxy A55): stock=45, price=87000
CALL UpdateProductInventory(1, 1, 45, 87000.00);

-- Test 3: Admin deactivates a customer
-- Deactivate customer 10 (Maham Tariq)
CALL DeactivateUser(10, 'Suspicious activity detected on account.');
