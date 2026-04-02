WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month_start,
    revenue,
    LAG(revenue) OVER (ORDER BY month_start) AS prev_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
        2
    ) AS growth_pct
FROM monthly_revenue
ORDER BY month_start;