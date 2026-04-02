WITH monthly_segment AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month_start,
        c.segment,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date), c.segment
)
SELECT
    month_start,
    segment,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY segment
        ORDER BY month_start
    ) AS prev_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (
            PARTITION BY segment
            ORDER BY month_start
        ))
        / NULLIF(LAG(revenue) OVER (
            PARTITION BY segment
            ORDER BY month_start
        ), 0),
        2
    ) AS growth_pct,
    SUM(revenue) OVER (
        PARTITION BY segment
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM monthly_segment
ORDER BY month_start, segment;