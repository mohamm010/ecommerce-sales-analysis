-- ============================================================
-- PRODUCT ANALYSIS
-- Dataset: staging.transactions
-- Non-product/service codes excluded:
-- AMAZONFEE, BANK CHARGES, CRUK, D, DOT, M, POST, B, C2
-- ============================================================

-- 1. TOP 10 PRODUCTS BY SALES REVENUE
SELECT
    stock_code,
    ROUND(SUM(transaction_value), 2) AS sales_revenue,
    SUM(quantity) AS quantity_sold
FROM staging.transactions
WHERE transaction_type = 'sale'
  AND stock_code NOT IN (
      'AMAZONFEE','BANK CHARGES','CRUK','D','DOT','M','POST','B','C2'
  )
GROUP BY stock_code
ORDER BY sales_revenue DESC
LIMIT 10;


-- 2. TOP 10 PRODUCTS BY QUANTITY SOLD
SELECT
    stock_code,
    ROUND(SUM(transaction_value), 2) AS sales_revenue,
    SUM(quantity) AS quantity_sold
FROM staging.transactions
WHERE transaction_type = 'sale'
  AND stock_code NOT IN (
      'AMAZONFEE','BANK CHARGES','CRUK','D','DOT','M','POST','B','C2'
  )
GROUP BY stock_code
ORDER BY quantity_sold DESC
LIMIT 10;


-- 3. AVERAGE REVENUE PER UNIT
-- HAVING applies the 100-unit threshold after grouping by product.
-- NULLIF protects the denominator from zero.
SELECT
    stock_code,
    ROUND(SUM(transaction_value), 2) AS sales_revenue,
    SUM(quantity) AS quantity_sold,
    ROUND(
        SUM(transaction_value) / NULLIF(SUM(quantity), 0),
        2
    ) AS avg_revenue_per_unit
FROM staging.transactions
WHERE transaction_type = 'sale'
  AND stock_code NOT IN (
      'AMAZONFEE','BANK CHARGES','CRUK','D','DOT','M','POST','B','C2'
  )
GROUP BY stock_code
HAVING SUM(quantity) >= 100
ORDER BY avg_revenue_per_unit DESC
LIMIT 10;


-- 4. PRODUCT RETURN/CANCELLATION RATE
-- transaction_type combines returns and cancellations, so extreme
-- rates must be investigated before being treated as product-return behavior.
WITH product_activity AS (
    SELECT
        stock_code,
        COALESCE(
            SUM(quantity) FILTER (WHERE transaction_type = 'sale'),
            0
        ) AS quantity_sold,
        COALESCE(
            -SUM(quantity) FILTER (
                WHERE transaction_type = 'return/cancellation'
            ),
            0
        ) AS quantity_returned
    FROM staging.transactions
    WHERE stock_code NOT IN (
        'AMAZONFEE','BANK CHARGES','CRUK','D','DOT','M','POST','B','C2'
    )
    GROUP BY stock_code
    HAVING SUM(quantity) FILTER (
        WHERE transaction_type = 'sale'
    ) >= 100
)
SELECT
    stock_code,
    quantity_sold,
    quantity_returned,
    ROUND(
        100.0 * quantity_returned / NULLIF(quantity_sold, 0),
        2
    ) AS return_cancellation_rate
FROM product_activity
ORDER BY return_cancellation_rate DESC
LIMIT 10;
