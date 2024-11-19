select
    t1.shop_id,
    t1.month_year as month_year,
    daily_orders_table.completeOrders,
    daily_orders_table.daily_orders,
    t1.ted_sum as ted_sum,
    t1.r_burn_sum as r_burn_sum,
    t1.b2c_sum as b2c_sum,
    t1.p2c_sum as p2c_sum,
    t2.ted_sum / daily_orders_table.days_in_month as ORD_last_month_ted_sum,
    t2.r_burn_sum / daily_orders_table.days_in_month as ORD_last_month_r_burn_sum,
    t2.b2c_sum / daily_orders_table.days_in_month as ORD_last_month_b2c_sum,
    t2.p2c_sum / daily_orders_table.days_in_month as ORD_last_month_p2c_sum,
    (t1.ted_sum / daily_orders_table.days_in_month) - (t2.ted_sum / daily_orders_table.days_in_month) as ted_diff,
    (t1.r_burn_sum / daily_orders_table.days_in_month) - (t2.r_burn_sum / daily_orders_table.days_in_month) as r_burn_diff,
    (t1.b2c_sum / daily_orders_table.days_in_month) - (t2.b2c_sum / daily_orders_table.days_in_month) as b2c_diff,
    (t1.p2c_sum / daily_orders_table.days_in_month) - (t2.p2c_sum / daily_orders_table.days_in_month) as p2c_diff
from
    (
        select
            shop_id,
            concat_ws('-', month, year) as month_year,
            month as month_,
            year as year_,
            round(sum(ted), 2) as ted_sum,
            round(sum(r_burn), 2) as r_burn_sum,
            round(sum(b2c_eng_burn) + sum(b2c_acq_burn), 2) as b2c_sum,
            round(sum(p2c_eng_burn) + sum(p2c_acq_burn), 2) as p2c_sum
        from
            soda_international_dwm.dwm_finance_order_d_increment
        where
            shop_id = '5764607523068575855'
            and country_code in ('MX', 'CO', 'PE', 'CR')
            and concat_ws('-', year, month, day) between '2024-01-01'
            and '2024-09-30'
        group by
            shop_id,
            concat_ws('-', month, year)
    ) t1
    left join (
        select
            shop_id,
            concat_ws('-', month, year) as month_year,
            month as month_,
            year as year_,
            round(sum(ted), 2) as ted_sum,
            round(sum(r_burn), 2) as r_burn_sum,
            round(sum(b2c_eng_burn) + sum(b2c_acq_burn), 2) as b2c_sum,
            round(sum(p2c_eng_burn) + sum(p2c_acq_burn), 2) as p2c_sum
        from
            soda_international_dwm.dwm_finance_order_d_increment
        where
            shop_id = '5764607523068575855'
            and country_code in ('MX', 'CO', 'PE', 'CR')
            and concat_ws('-', year, month, day) between '2023-12-01'
            and '2024-08-31'
        group by
            shop_id,
            concat_ws('-', month, year)
    ) t2 on t1.shop_id = t2.shop_id
    and (
        (
            t1.month_ = (t2.month_ + 1)
            and t1.concat_wsyear_ = t2.year_
        )
        or (
            t1.year_ = t2.year_ + 1
            and t1.month = 1
            and t2.month = 12
        )
    )
    left JOIN (
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
            year
    ) daily_orders_table on daily_orders_table.shop_id = t1.shop_id
    and daily_orders_tablemonth_year = t1.month_year;