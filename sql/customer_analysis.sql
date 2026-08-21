-- ============================================================
-- CUSTOMER ANALYSIS
-- Dataset: staging.transactions
-- ============================================================

-- 1. TOP 20 CUSTOMERS BY SALES REVENUE
-- Business question: Which customers generate the most sales revenue?
-- Grain: CTE = one row per order; final output = one row per customer.
-- Notes: sales only; NULL customer IDs excluded.

WITH orders AS (
    SELECT
        customer_id,
        invoice_no,
        SUM(transaction_value) AS order_value
    FROM staging.transactions
    WHERE transaction_type = 'sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id, invoice_no
)
SELECT
    customer_id,
    ROUND(SUM(order_value), 2) AS sales_revenue,
    COUNT(*) AS order_count,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM orders
GROUP BY customer_id
ORDER BY sales_revenue DESC
LIMIT 20;


-- 2. REPEAT CUSTOMER ANALYSIS
-- Business question: Which repeat customers generate the most revenue?
-- Definition: repeat customer = more than one distinct sale order.

WITH orders AS (
    SELECT
        customer_id,
        invoice_no,
        SUM(transaction_value) AS order_value
    FROM staging.transactions
    WHERE transaction_type = 'sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id, invoice_no
)
SELECT
    customer_id,
    COUNT(*) AS order_count,
    ROUND(SUM(order_value), 2) AS sales_revenue,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY sales_revenue DESC;


-- 3. REPEAT CUSTOMER KPI
-- Verified result:
-- total_customers = 4338
-- repeat_customers = 2845
-- repeat_customer_rate = 65.58%

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS order_count
    FROM staging.transactions
    WHERE customer_id IS NOT NULL
      AND transaction_type = 'sale'
    GROUP BY customer_id
) AS customers;
