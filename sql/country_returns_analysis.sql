-- ============================================================
-- COUNTRY & RETURN/CANCELLATION ANALYSIS
-- Dataset: staging.transactions
-- ============================================================

-- 1. COUNTRY REVENUE + REVENUE SHARE
-- Verified finding: United Kingdom = 84.59% of total sales revenue.
SELECT
    country,
    ROUND(SUM(transaction_value), 2) AS country_revenue,
    ROUND(
        100.0 * SUM(transaction_value) /
        (
            SELECT SUM(transaction_value)
            FROM staging.transactions
            WHERE transaction_type = 'sale'
        ),
        2
    ) AS country_revenue_share
FROM staging.transactions
WHERE transaction_type = 'sale'
GROUP BY country
ORDER BY country_revenue_share DESC;


-- 2. COUNTRY AVERAGE ORDER VALUE
-- Only countries with at least 20 sale orders are retained.
-- Verified finding: Netherlands had the highest AOV among countries
-- meeting this threshold; UK dominance was mainly volume-driven.
WITH country_orders AS (
    SELECT
        country,
        COUNT(DISTINCT invoice_no) AS orders,
        SUM(transaction_value) AS country_revenue
    FROM staging.transactions
    WHERE transaction_type = 'sale'
    GROUP BY country
)
SELECT
    country,
    orders,
    ROUND(country_revenue, 2) AS country_revenue,
    ROUND(
        country_revenue / NULLIF(orders, 0),
        2
    ) AS avg_order_value
FROM country_orders
WHERE orders >= 20
ORDER BY avg_order_value DESC;


-- 3. COUNTRY RETURN/CANCELLATION ACTIVITY
-- Non-product/service codes are excluded.
-- sales_orders and cancellation_orders are activity counts and should
-- not be divided into a "true order cancellation rate" unless original
-- sales can be matched to cancellation invoices.
WITH country_activity AS (
    SELECT
        country,
        COALESCE(
            -SUM(quantity) FILTER (
                WHERE transaction_type = 'return/cancellation'
            ),
            0
        ) AS quantity_returned,
        COALESCE(
            SUM(quantity) FILTER (
                WHERE transaction_type = 'sale'
            ),
            0
        ) AS quantity_sold,
        COUNT(DISTINCT invoice_no) FILTER (
            WHERE transaction_type = 'sale'
        ) AS sales_orders,
        COUNT(DISTINCT invoice_no) FILTER (
            WHERE transaction_type = 'return/cancellation'
        ) AS cancellation_orders
    FROM staging.transactions
    WHERE stock_code NOT IN (
        'AMAZONFEE','BANK CHARGES','CRUK','D','DOT','M','POST','B','C2'
    )
    GROUP BY country
)
SELECT
    country,
    quantity_returned,
    quantity_sold,
    sales_orders,
    cancellation_orders,
    ROUND(
        100.0 * quantity_returned / NULLIF(quantity_sold, 0),
        2
    ) AS return_cancellation_rate
FROM country_activity
ORDER BY return_cancellation_rate DESC NULLS LAST;


-- ============================================================
-- INVESTIGATION / DATA QUALITY CHECKS
-- Not main KPI outputs.
-- ============================================================

-- A. USA RETURN/CANCELLATION AUDIT
-- Verified: 112 transaction rows, 2 cancellation invoices,
-- 1,424 returned/cancelled units.
SELECT
    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT invoice_no) AS cancellation_orders,
    -SUM(quantity) AS quantity_returned,
    -SUM(transaction_value) AS cancelled_value
FROM staging.transactions
WHERE country = 'USA'
  AND transaction_type = 'return/cancellation';


-- B. USA CANCELLATION INVOICES
-- Verified:
-- C570867 = 1,228 units
-- C581229 =   196 units
SELECT
    invoice_no,
    COUNT(*) AS transaction_rows,
    -SUM(quantity) AS quantity_returned,
    -SUM(transaction_value) AS cancelled_value
FROM staging.transactions
WHERE country = 'USA'
  AND transaction_type = 'return/cancellation'
GROUP BY invoice_no
ORDER BY quantity_returned DESC;


-- C. BAHRAIN INVOICE TIMELINE
-- Verified: one full 54-unit cancellation drove the 17.20% rate.
SELECT
    invoice_no,
    CAST(MIN(invoice_date) AS date) AS order_date,
    transaction_type,
    SUM(quantity) AS total_quantity,
    SUM(transaction_value) AS total_value
FROM staging.transactions
WHERE country = 'Bahrain'
GROUP BY invoice_no, transaction_type
ORDER BY order_date;


-- D. CZECH REPUBLIC INVOICE TIMELINE
-- Cleaned product-level result after excluding POST:
-- quantity_returned = 78
-- quantity_sold = 670
-- sales_orders = 2
-- cancellation_orders = 2
-- return_cancellation_rate = 11.64%
SELECT
    invoice_no,
    MIN(invoice_date)::date AS invoice_date,
    transaction_type,
    SUM(quantity) AS total_quantity,
    SUM(transaction_value) AS total_value
FROM staging.transactions
WHERE country = 'Czech Republic'
GROUP BY invoice_no, transaction_type
ORDER BY invoice_date;


-- E. CZECH REPUBLIC SUSPICIOUS CANCELLATION PRODUCTS
-- C548667 and C577151 contained identical product quantities/values.
-- C577353 contained POSTAGE only.
SELECT
    invoice_no,
    invoice_date::date AS invoice_date,
    stock_code,
    description,
    quantity,
    transaction_value
FROM staging.transactions
WHERE country = 'Czech Republic'
  AND invoice_no IN ('C548667', 'C577151', 'C577353')
ORDER BY invoice_no, stock_code;


-- F. CUSTOMER 12781 HISTORY FOR THE SUSPICIOUS PRODUCTS
-- For 84459A, the observed dataset contains +24 sold units but
-- -48 cancelled units across two cancellation invoices.
SELECT
    invoice_no,
    invoice_date::date AS invoice_date,
    country,
    stock_code,
    quantity,
    transaction_type,
    transaction_value
FROM staging.transactions
WHERE customer_id = 12781
  AND stock_code IN ('22231', '84459A')
ORDER BY stock_code, invoice_date;
