WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date::date AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS rn
    FROM orders o
    WHERE o.status <> 'cancelled'
),
first_purchase AS (
    SELECT
        customer_id,
        order_date AS first_order_date,
        DATE_TRUNC('month', order_date)::date AS cohort_month
    FROM ranked_orders
    WHERE rn = 1
),
repeat_orders AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        fp.first_order_date,
        o.order_date::date AS repeat_order_date,
        (o.order_date::date - fp.first_order_date) AS days_after_first
    FROM first_purchase fp
    JOIN orders o
        ON o.customer_id = fp.customer_id
    WHERE o.status <> 'cancelled'
      AND o.order_date::date > fp.first_order_date
)
SELECT
    fp.cohort_month,
    COUNT(DISTINCT fp.customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN ro.days_after_first <= 30 THEN fp.customer_id END) AS retained_30,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ro.days_after_first <= 30 THEN fp.customer_id END)
        / NULLIF(COUNT(DISTINCT fp.customer_id), 0),
        2
    ) AS retention_30_pct,
    COUNT(DISTINCT CASE WHEN ro.days_after_first <= 60 THEN fp.customer_id END) AS retained_60,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ro.days_after_first <= 60 THEN fp.customer_id END)
        / NULLIF(COUNT(DISTINCT fp.customer_id), 0),
        2
    ) AS retention_60_pct,
    COUNT(DISTINCT CASE WHEN ro.days_after_first <= 90 THEN fp.customer_id END) AS retained_90,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ro.days_after_first <= 90 THEN fp.customer_id END)
        / NULLIF(COUNT(DISTINCT fp.customer_id), 0),
        2
    ) AS retention_90_pct
FROM first_purchase fp
LEFT JOIN repeat_orders ro
    ON fp.customer_id = ro.customer_id
GROUP BY fp.cohort_month
ORDER BY fp.cohort_month;