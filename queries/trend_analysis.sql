WITH daily_revenue AS (
    SELECT
        o.order_date::date AS day,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY o.order_date::date
)
SELECT
    day,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7d,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_30d
FROM daily_revenue
ORDER BY day;