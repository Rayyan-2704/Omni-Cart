-- =============================================
-- OmniCart Database Procedures
-- =============================================
USE omnicart_db;

-- =============================================================================================
-- Procedure 1: PlaceOrder --> Customer Role
-- Atomic Order Placement
-- Usage: CALL PlaceOrder(customer_id, cart_items_json);
-- Example: CALL PlaceOrder(1, '[{"product_id":1,"quantity":2},{"product_id":3,"quantity":1}]');
-- =============================================================================================
DROP PROCEDURE IF EXISTS PlaceOrder;

DELIMITER $$

CREATE PROCEDURE PlaceOrder(
    IN p_customer_id INT,
    IN p_cart_items JSON
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE v_idx INT DEFAULT 0;
    DECLARE v_count INT;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    DECLARE v_active BOOLEAN;

    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- If customer does not exist
    IF NOT EXISTS (
        SELECT 1 FROM customers WHERE customer_id = p_customer_id AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid customer!';
    END IF;

    -- Check for empty cart
    SET v_count = JSON_LENGTH(p_cart_items);
    IF p_cart_items IS NULL OR JSON_LENGTH(p_cart_items) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cart is empty!';
    END IF;
    

    START TRANSACTION;

    -- Insert a new order (total_amount currently 0; it will be updated later after calculation)
    INSERT INTO orders (customer_id, total_amount, status)
    VALUES (p_customer_id, 0.0, 'pending');
    SET v_order_id = LAST_INSERT_ID();

    -- Checking for each item's availability and then inserting a new order item for each item in cart
    WHILE v_idx < v_count DO
        SET v_product_id = CAST(JSON_EXTRACT(p_cart_items, CONCAT('$[', v_idx, '].product_id')) AS UNSIGNED);
        SET v_quantity = CAST(JSON_EXTRACT(p_cart_items, CONCAT('$[', v_idx, '].quantity')) AS UNSIGNED);

        IF v_product_id IS NULL OR v_quantity IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid cart data!';
        END IF;

        -- Get product info and lock row
        SELECT price, stock_qty, is_active INTO v_price, v_stock, v_active
        FROM products WHERE product_id = v_product_id
        FOR UPDATE;

        -- Check for availability
        IF v_active = FALSE THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product is inactive!';
        END IF;

        -- Check for stock
        IF v_stock < v_quantity THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock!';
        END IF;

        -- Add to total amount
        SET v_total = v_total + (v_price * v_quantity);

        -- Insert order item (after order is created)
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_product_id, v_quantity, v_price);

        -- Deduct stock
        UPDATE products SET stock_qty = stock_qty - v_quantity
        WHERE product_id = v_product_id;

        SET v_idx = v_idx + 1;
    END WHILE;

    -- Updating the order's total_amount
    UPDATE orders SET total_amount = v_total
    WHERE order_id = v_order_id;

    -- Clear cart
    DELETE FROM cart WHERE customer_id = p_customer_id;

    COMMIT;
    SELECT v_order_id AS order_id, v_total AS total_amount;
END$$

DELIMITER ;

-- =============================================================================================
-- Procedure 2: UpdateProductInventory --> Vendor Role
-- Secure Product Update
-- Usage: CALL UpdateProductInventory(product_id, vendor_id, new_stock, new_price);
-- Example: CALL UpdateProductInventory(101, 5, 50, 1999.99);
-- =============================================================================================
DROP PROCEDURE IF EXISTS UpdateProductInventory;

DELIMITER $$

CREATE PROCEDURE UpdateProductInventory(
    IN p_product_id INT,
    IN p_vendor_id INT,
    IN p_new_stock INT,
    IN p_new_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_owner INT;

    SELECT vendor_id INTO v_owner
    FROM products WHERE product_id = p_product_id;

    IF v_owner IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found!';
    END IF;

    IF v_owner != p_vendor_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unauthorized: product belongs to another vendor!';
    END IF;

    IF p_new_stock < 0 OR p_new_price < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid stock or price';
    END IF;

    UPDATE products
    SET stock_qty = p_new_stock, price = p_new_price
    WHERE product_id = p_product_id;

    SELECT ROW_COUNT() AS rows_updated;
END$$

DELIMITER ;

-- =============================================================================================
-- Procedure 3: DeactivateUser --> Admin Role
-- System-Wide User Deactivation
-- Usage: CALL DeactivateUser(user_id, user_type, reason);
-- Example: CALL DeactivateUser(5, 'vendor', 'Account closed by admin');
--          CALL DeactivateUser(12, 'customer', 'Violation of terms');
-- =============================================================================================
DROP PROCEDURE IF EXISTS DeactivateUser;

DELIMITER $$

CREATE PROCEDURE DeactivateUser(
    IN p_admin_id INT,
    IN p_user_id INT,
    IN p_user_type VARCHAR(20),
    IN p_reason VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- If admin does not exist
    IF NOT EXISTS (
        SELECT 1 FROM admins WHERE admin_id = p_admin_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unauthorized. Admin not found!';
    END IF;

    IF p_user_type = 'customer' THEN
        -- if customer does not exist or inactive
        IF NOT EXISTS (
            SELECT 1 FROM customers WHERE customer_id = p_user_id AND is_active = TRUE
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found or already inactive!';
        END IF;

        -- Deactivate the customer and set their pending orders to cancelled
        UPDATE customers SET is_active = FALSE 
        WHERE customer_id = p_user_id;
        UPDATE orders SET status = 'cancelled'
        WHERE customer_id = p_user_id AND status = 'pending';

    ELSEIF p_user_type = 'vendor' THEN
        -- If vendor does not exist or inactive
        IF NOT EXISTS (
            SELECT 1 FROM vendors WHERE vendor_id = p_user_id AND is_active = TRUE
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vendor not found or already inactive!';
        END IF;

        -- Deactivate the vendor along with all their products
        UPDATE vendors SET is_active = FALSE 
        WHERE vendor_id = p_user_id;
        UPDATE products SET is_active = FALSE 
        WHERE vendor_id = p_user_id;

    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user type!';
    END IF;

    COMMIT;
    SELECT CONCAT(p_user_type, ' #', p_user_id, ' deactivated. Reason: ', p_reason) AS result;
END$$

DELIMITER ;

-- =============================================================================================
-- Procedure 4: ProcessPayment --> Customer Role
-- Handles payment atomically - updates payment,
-- sets paid_at, updates order status
-- Usage: CALL ProcessPayment(customer_id, order_id, method, amount);
-- =============================================================================================
DROP PROCEDURE IF EXISTS ProcessPayment;

DELIMITER $$

CREATE PROCEDURE ProcessPayment(
    IN p_customer_id INT,
    IN p_order_id INT,
    IN p_method VARCHAR(20),
    IN p_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_order_total DECIMAL(10,2);
    DECLARE v_order_status VARCHAR(20);
    DECLARE v_customer_id INT;
    DECLARE v_payment_id INT;

    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validate payment method
    IF p_method NOT IN ('credit_card', 'debit_card', 'cash_on_delivery', 'bank_transfer') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method!';
    END IF;

    -- Validate amount
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment amount!';
    END IF;

    START TRANSACTION;

    -- Lock order record to prevent race condition
    SELECT customer_id, total_amount, status INTO v_customer_id, v_order_total, v_order_status
    FROM orders WHERE order_id = p_order_id
    FOR UPDATE;

    -- Check if order exists
    IF v_order_total IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found!';
    END IF;

    -- Check if order belongs to this customer
    IF v_customer_id != p_customer_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unauthorized: order does not belong to this customer!';
    END IF;

    -- Check order status for cancelled / confirmed (already paid) / delivered (paid and delivered)
    IF v_order_status = 'cancelled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot process payment for a cancelled order!';
    END IF;

    IF v_order_status IN ('confirmed', 'delivered') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order already paid!';
    END IF;

    -- Validate amount matches
    IF p_amount != v_order_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment amount does not match order total!';
    END IF;

    -- If a payment record already exists
    IF EXISTS (
        SELECT 1 FROM payments WHERE order_id = p_order_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment already exists for this order!';
    END IF;

    -- Insert payment
    INSERT INTO payments (order_id, method, status, amount, paid_at)
    VALUES (p_order_id, p_method, 'completed', p_amount, CURRENT_TIMESTAMP);

    -- Update order status (better design than directly delivered)
    UPDATE orders SET status = 'confirmed'
    WHERE order_id = p_order_id;

    COMMIT;

    SELECT p_order_id AS order_id, p_method AS payment_method, p_amount AS amount_paid, 'paid' AS order_status, 'Payment processed successfully!' AS message;
END$$

DELIMITER ;

-- =============================================================================================
-- Procedure 5: CancelOrder --> Customer Role
-- Reverses PlaceOrder - restores stock,
-- cancels order, handles payment refund
-- Usage: CALL CancelOrder(order_id, customer_id);
-- =============================================================================================
DROP PROCEDURE IF EXISTS CancelOrder;

DELIMITER $$

CREATE PROCEDURE CancelOrder(
    IN p_order_id INT,
    IN p_customer_id INT
)
BEGIN
    DECLARE v_order_status VARCHAR(20);
    DECLARE v_owner_id INT;
    DECLARE v_payment_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- If customer does not exist
    IF NOT EXISTS (
        SELECT 1 FROM customers WHERE customer_id = p_customer_id AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid customer!';
    END IF;

    START TRANSACTION;

    -- Lock order row to prevent race condition
    SELECT status, customer_id INTO v_order_status, v_owner_id
    FROM orders WHERE order_id = p_order_id
    FOR UPDATE;

    -- Check for order existence
    IF v_order_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found.';
    END IF;

    -- Check for ownership
    IF v_owner_id != p_customer_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Access denied. This order does not belong to you.';
    END IF;

    -- Check for order's state
    IF v_order_status NOT IN ('pending', 'confirmed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only pending or confirmed orders can be cancelled.';
    END IF;

    -- Restoring the stock
    UPDATE products p
    JOIN order_items oi ON p.product_id = oi.product_id
    SET p.stock_qty = p.stock_qty + oi.quantity
    WHERE oi.order_id = p_order_id;

    -- Cancelling order
    UPDATE orders SET status = 'cancelled'
    WHERE order_id = p_order_id;

    -- Handle payment safely
    SELECT status INTO v_payment_status
    FROM payments WHERE order_id = p_order_id
    LIMIT 1
    FOR UPDATE;

    IF v_payment_status = 'completed' THEN
        UPDATE payments SET status = 'refunded'
        WHERE order_id = p_order_id;

    ELSEIF v_payment_status = 'pending' THEN
        UPDATE payments SET status = 'failed'
        WHERE order_id = p_order_id;
    END IF;

    COMMIT;

    SELECT p_order_id AS cancelled_order_id, p_customer_id AS customer_id, v_order_status AS previous_status, 'cancelled' AS new_status,
        CASE
            WHEN v_payment_status = 'completed' THEN 'Refund initiated'
            WHEN v_payment_status = 'pending' THEN 'Payment voided'
            ELSE 'No payment to reverse'
        END AS payment_action, 'Order cancelled successfully!' AS message;
END$$

DELIMITER ;