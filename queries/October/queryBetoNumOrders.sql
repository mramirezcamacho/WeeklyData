SELECT
    shop_id,
    CONCAT_WS('-', month, year) AS month_year,
    COUNT(*) AS completeOrders,
    CASE
        WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-20' THEN LEAST(
            DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
            DATEDIFF('2024-10-20', CONCAT(year, '-', month, '-01')) + 1
        )
        ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
    END AS days_in_month,
    COUNT(*) / CASE
        WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-20' THEN LEAST(
            DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
            DATEDIFF('2024-10-20', CONCAT(year, '-', month, '-01')) + 1
        )
        ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
    END as daily_orders
FROM
    soda_international_dwd.dwd_order_wide_d_increment
WHERE
    shop_id = '5764607523068575855'
    AND country_code IN ('MX', 'CO', 'PE', 'CR')
    AND CONCAT_WS('-', year, month, day) BETWEEN '2024-01-01'
    AND '2024-10-20'
    AND (
        status = '600'
        OR status = 600
    )
GROUP BY
    shop_id,
    month,
    year;