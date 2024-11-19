select
    t1.country_code,
    basic.city_name,
    t1.month_year as month_year,
    daily_orders_table.days_in_month,
    t1.shop_id,
    basic.bd_user_name_extract,
    basic.is_suspended,
    basic.suspend_reason,
    daily_orders_table.completeOrders,
    daily_orders_table.daily_orders,
    priority_table.priority,
    priority_table.vertical,
    first_online_table.first_eff_online_date,
    CASE
        WHEN daily_orders_table.daily_orders > 5 then 1
        else 0
    end as is_plus_5,
    t1.ted_sum as ted_sum,
    t1.r_burn_sum as r_burn_sum,
    t1.b2c_sum as b2c_sum,
    t1.p2c_sum as p2c_sum,
    t2.ted_sum / daily_orders_table_old.completeOrders as ORD_last_month_ted_sum,
    t2.r_burn_sum / daily_orders_table_old.completeOrders as ORD_last_month_r_burn_sum,
    t2.b2c_sum / daily_orders_table_old.completeOrders as ORD_last_month_b2c_sum,
    t2.p2c_sum / daily_orders_table_old.completeOrders as ORD_last_month_p2c_sum,
    (t1.ted_sum / daily_orders_table.completeOrders) - (
        t2.ted_sum / daily_orders_table_old.completeOrders
    ) as ted_diff,
    (
        t1.r_burn_sum / daily_orders_table.completeOrders
    ) - (
        t2.r_burn_sum / daily_orders_table_old.completeOrders
    ) as r_burn_diff,
    (t1.b2c_sum / daily_orders_table.completeOrders) - (
        t2.b2c_sum / daily_orders_table_old.completeOrders
    ) as b2c_diff,
    (t1.p2c_sum / daily_orders_table.completeOrders) - (
        t2.p2c_sum / daily_orders_table_old.completeOrders
    ) as p2c_diff,
    CASE
        WHEN (
            daily_orders_table.daily_orders > 5
            and daily_orders_table_old.daily_orders > 5
        ) then 'Stay in'
        WHEN (
            daily_orders_table.daily_orders < 5
            and daily_orders_table_old.daily_orders < 5
        ) then 'Stay out'
        WHEN (
            daily_orders_table.daily_orders > 5
            and daily_orders_table_old.daily_orders < 5
        ) then 'Enter'
        WHEN (
            daily_orders_table.daily_orders < 5
            and daily_orders_table_old.daily_orders > 5
        ) then 'Exit'
        else ''
    end as is_status
from
    (
        select
            country_code,
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
            country_code in ('MX', 'CO', 'PE', 'CR')
            and concat_ws('-', year, month, day) between '2024-01-01'
            and '2024-10-19'
        group by
            country_code,
            shop_id,
            concat_ws('-', month, year),
            month,
            year
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
            country_code in ('MX', 'CO', 'PE', 'CR')
            and concat_ws('-', year, month, day) between '2023-12-01'
            and '2024-10-19'
        group by
            shop_id,
            concat_ws('-', month, year),
            month,
            year
    ) t2 on t1.shop_id = t2.shop_id
    and (
        (
            cast(t1.month_ as int) = (cast(t2.month_ as int) + 1)
            and cast(t1.year_ as int) = cast(t2.year_ as int)
        )
        or (
            cast(t1.year_ as int) = cast(t2.year_ as int) + 1
            and cast(t1.month_ as int) = 1
            and cast(t2.month_ as int) = 12
        )
    )
    left JOIN (
        SELECT
            shop_id,
            CONCAT_WS('-', month, year) AS month_year,
            COUNT(*) AS completeOrders,
            CASE
                WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-19' THEN LEAST(
                    DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
                    DATEDIFF('2024-10-19', CONCAT(year, '-', month, '-01')) + 1
                )
                ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
            END AS days_in_month,
            COUNT(*) / CASE
                WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-19' THEN LEAST(
                    DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
                    DATEDIFF('2024-10-19', CONCAT(year, '-', month, '-01')) + 1
                )
                ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
            END as daily_orders
        FROM
            soda_international_dwd.dwd_order_wide_d_increment
        WHERE
            country_code IN ('MX', 'CO', 'PE', 'CR')
            AND CONCAT_WS('-', year, month, day) BETWEEN '2024-01-01'
            AND '2024-10-19'
            AND (
                status = '600'
                OR status = 600
            )
            AND is_td_complete = 1
        GROUP BY
            shop_id,
            month,
            year
    ) daily_orders_table on daily_orders_table.shop_id = t1.shop_id
    and daily_orders_table.month_year = t1.month_year
    left JOIN (
        SELECT
            shop_id,
            CONCAT_WS('-', month, year) AS month_year,
            COUNT(*) AS completeOrders,
            month as month_,
            year as year_,
            CASE
                WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-19' THEN LEAST(
                    DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
                    DATEDIFF('2024-10-19', CONCAT(year, '-', month, '-01')) + 1
                )
                ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
            END AS days_in_month,
            COUNT(*) / CASE
                WHEN DATE_FORMAT(CONCAT(year, '-', month, '-01'), '%Y-%m-01') <= '2024-10-19' THEN LEAST(
                    DAY(LAST_DAY(CONCAT(year, '-', month, '-01'))),
                    DATEDIFF('2024-10-19', CONCAT(year, '-', month, '-01')) + 1
                )
                ELSE DAY(LAST_DAY(CONCAT(year, '-', month, '-01')))
            END as daily_orders
        FROM
            soda_international_dwd.dwd_order_wide_d_increment
        WHERE
            country_code IN ('MX', 'CO', 'PE', 'CR')
            AND CONCAT_WS('-', year, month, day) BETWEEN '2023-12-01'
            AND '2024-10-19'
            AND (
                status = '600'
                OR status = 600
            )
            AND is_td_complete = 1
        GROUP BY
            shop_id,
            month,
            year
    ) daily_orders_table_old on daily_orders_table_old.shop_id = t1.shop_id
    and (
        (
            cast(t1.month_ as int) = (cast(daily_orders_table_old.month_ as int) + 1)
            and cast(t1.year_ as int) = cast(daily_orders_table_old.year_ as int)
        )
        or (
            cast(t1.year_ as int) = cast(daily_orders_table_old.year_ as int) + 1
            and cast(t1.month_ as int) = 1
            and cast(daily_orders_table_old.month_ as int) = 12
        )
    )
    LEFT JOIN (
        select
            shop_id,
            city_name,
            CONCAT_WS('-', month, year) as month_year,
            case
                when sum(
                    CASE
                        WHEN is_suspend = 0
                        or is_suspend is null then 0
                        else 1
                    end
                ) > 0 then 1
                else 0
            end as is_suspended,
            suspend_reason,
            bd_user_name_extract
        from
            soda_international_dwm.dwm_bizopp_wide_d_whole
        where
            CONCAT_WS('-', year, month, day) = '2024-10-19'
            AND country_code IN ('MX', 'CO', 'PE', 'CR')
        group by
            shop_id,
            city_name,
            CONCAT_WS('-', month, year),
            suspend_reason,
            bd_user_name_extract
    ) as basic on basic.shop_id = t1.shop_id
    left join (
        select
            shop_id,
            first_eff_online_date
        from
            soda_international_dwm.dwm_bizopp_sign_process_d_whole
        where
            CONCAT_WS('-', year, month, day) = '2024-10-19'
            AND country_code IN ('MX', 'CO', 'PE', 'CR')
    ) as first_online_table on first_online_table.shop_id = t1.shop_id
    left join (
        select
            shop_id,
            priority,
            CASE
                WHEN organization_type = 2 then 'CKA'
                WHEN organization_type = 4 then 'Normal'
                else 'neither'
            END as vertical
        from
            soda_international_dwm.dwm_bizopp_wide_d_whole
        where
            CONCAT_WS('-', year, month, day) = '2024-10-19'
            AND country_code IN ('MX', 'CO', 'PE', 'CR')
    ) as priority_table on priority_table.shop_id = t1.shop_id
where
    priority_table.vertical != 'neither'
order BY
    t1.shop_id,
    t1.month_year;