-- ============================================================
-- SALES TRENDS
-- Dataset: staging.transactions
-- ============================================================

-- 1. MONTHLY SALES SUMMARY
-- Grain: one row per month.
-- December 2011 is incomplete (data only through Dec 9).
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS order_month,
        COUNT(DISTINCT invoice_no) AS order_count,
        SUM(quantity) AS quantity_sold,
        SUM(transaction_value) AS monthly_sales
    FROM staging.transactions
    WHERE transaction_type = 'sale'
    GROUP BY DATE_TRUNC('month', invoice_date)
)
SELECT
    order_month,
    order_count,
    quantity_sold,
    ROUND(monthly_sales, 2) AS monthly_sales,
    ROUND(
        monthly_sales / NULLIF(order_count, 0),
        2
    ) AS avg_order_value
FROM monthly_sales
ORDER BY order_month;


-- 2. HIGHEST-REVENUE COMPLETE MONTH
-- December 2011 is excluded because it is incomplete.
-- Verified result: November 2011.
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS order_month,
        COUNT(DISTINCT invoice_no) AS order_count,
        SUM(quantity) AS quantity_sold,
        SUM(transaction_value) AS monthly_sales
    FROM staging.transactions
    WHERE transaction_type = 'sale'
    GROUP BY DATE_TRUNC('month', invoice_date)
)
SELECT
    order_month,
    order_count,
    quantity_sold,
    ROUND(monthly_sales, 2) AS monthly_sales,
    ROUND(
        monthly_sales / NULLIF(order_count, 0),
        2
    ) AS avg_order_value
FROM monthly_sales
WHERE order_month <> DATE '2011-12-01'
ORDER BY monthly_sales DESC
LIMIT 1;
