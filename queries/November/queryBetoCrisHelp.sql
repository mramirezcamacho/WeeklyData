SELECT
    shop_id,
    CASE
        WHEN (
            top_1_item_days_in_promo >= 12
            OR top_2_item_days_in_promo >= 12
        ) THEN "Sí"
        ELSE "No"
    END AS top2_kpi_check
FROM
    (
        SELECT
            shop_id,
            MAX(
                CASE
                    WHEN item_rank = 1 THEN item_days_in_promo
                END
            ) AS top_1_item_days_in_promo,
            MAX(
                CASE
                    WHEN item_rank = 2 THEN item_days_in_promo
                END
            ) AS top_2_item_days_in_promo
        FROM
            (
                SELECT
                    ordered_ranked_items.shop_id,
                    ordered_ranked_items.item_id,
                    ordered_ranked_items.item_name,
                    ordered_ranked_items.item_rank,
                    ordered_ranked_items.sales_item_cnt,
                    promo_days.item_days_in_promo
                FROM
                    (
                        select
                            shop_id,
                            item_id,
                            item_name,
                            sum(item_orders) as sales_item_cnt,
                            ROW_NUMBER() OVER (
                                PARTITION BY shop_id
                                ORDER BY
                                    SUM(item_orders) DESC,
                                    item_id desc
                            ) AS item_rank
                        from
                            soda_international_dwm.dwm_item_wide_d_whole
                        where
                            country_code IN ('MX', 'CO', 'CR', 'PE')
                            AND concat_ws('-', year, month, day) between date_format(
                                add_months('$[YYYY-MM-DD - 1D]', -2),
                                'yyyy-MM-15'
                            )
                            and date_format(
                                add_months('$[YYYY-MM-DD - 1D]', -1),
                                'yyyy-MM-15'
                            )
                            and is_sold_separately = 1
                            and item_orders > 0
                        group by
                            shop_id,
                            item_id,
                            item_name
                    ) ordered_ranked_items
                    LEFT JOIN (
                        SELECT
                            item_meta.item_id,
                            COUNT(
                                DISTINCT CASE
                                    WHEN (
                                        item_r_burn_rate >= 0.1
                                        AND (item_discount = item_r_burn_rate)
                                    )
                                    OR (is_buygifts_activity = 1)
                                    OR (
                                        combo_type in (1, 2)
                                        and item_discount >= 0.1
                                    )
                                    OR (
                                        status in (6)
                                        and discount_rate >= 0.1
                                    ) THEN item_meta.stat_date
                                    ELSE null
                                END
                            ) AS item_days_in_promo
                        FROM
                            (
                                SELECT
                                    concat_ws('-', year, month, day) as stat_date,
                                    item_id,
                                    CASE
                                        WHEN is_sold_separately = 1
                                        AND concat_ws('-', year, month, day) >= '2023-05-17'
                                        AND additional_type = 1
                                        AND combo_version = 2 THEN 1
                                        WHEN is_sold_separately = 1
                                        AND concat_ws('-', year, month, day) >= '2023-05-17'
                                        AND additional_type = 1
                                        AND combo_version = 1 THEN 3
                                        WHEN is_sold_separately = 1
                                        AND concat_ws('-', year, month, day) <= '2023-04-03'
                                        AND additional_type = 1
                                        AND original_price = 0
                                        AND to_date(create_time) BETWEEN '2022-07-01'
                                        AND '2023-04-04' THEN 1
                                        WHEN (
                                            is_sold_separately = 1
                                            AND concat_ws('-', year, month, day) >= '2023-04-04'
                                            AND to_date(create_time) BETWEEN '2022-07-01'
                                            AND '2023-04-04'
                                            AND additional_type = 1
                                            AND original_price = 0
                                            AND combo_version <> 1
                                        )
                                        OR (
                                            to_date(create_time) >= '2023-04-05'
                                            AND concat_ws('-', year, month, day) >= '2023-04-04'
                                            AND is_sold_separately = 1
                                            AND additional_type = 1
                                            AND combo_version = 2
                                        ) THEN 1
                                        WHEN is_sold_separately = 1
                                        AND (
                                            lower(item_name) RLIKE 'combo|paquete|pack|compartir'
                                            OR additional_type = 1
                                        ) THEN 3
                                        ELSE 0
                                    END AS combo_type
                                FROM
                                    soda_international_dwd.dwd_item_meta_d_whole
                                WHERE
                                    country_code in ('MX', 'CO', 'CR', 'PE')
                                    AND concat_ws('-', year, month, day) between date_format('$[YYYY-MM-DD - 1D]', 'yyyy-MM-01')
                                    and '$[YYYY-MM-DD - 1D]' --AND status != 3 
                                    --AND is_sold_separately = 1
                            ) as item_meta
                            LEFT JOIN (
                                SELECT
                                    a.*
                                FROM
                                    (
                                        SELECT
                                            concat_ws('-', year, month, day) as stat_date,
                                            item_id,
                                            act_id,
                                            status,
                                            join_status,
                                            discount_rate * 0.01 as discount_rate
                                        FROM
                                            soda_international_dwd.dwd_marketing_special_item_v2_d_whole
                                        WHERE
                                            country_code in ('MX', 'CO', 'CR', 'PE')
                                            AND concat_ws('-', year, month, day) between date_format('$[YYYY-MM-DD - 1D]', 'yyyy-MM-01')
                                            and '$[YYYY-MM-DD - 1D]'
                                            and is_td_online = 1
                                            and is_td_join_status = 1
                                            and is_del = 0
                                            and status = 6
                                        union
                                        all
                                        select
                                            concat_ws('-', year, month, day) as stat_date,
                                            item_id,
                                            act_id,
                                            status,
                                            join_status,
                                            1 - buy_num / get_num as discount_rate
                                        from
                                            soda_international_dwd.dwd_marketing_buy_gifts_v2_d_whole
                                        where
                                            concat_ws('-', year, month, day) between date_format('$[YYYY-MM-DD - 1D]', 'yyyy-MM-01')
                                            and '$[YYYY-MM-DD - 1D]'
                                            AND country_code in ('MX', 'CO', 'CR', 'PE')
                                            and is_td_online = 1
                                            and is_td_join_status = 1
                                            and is_del = 0
                                            and status = 6
                                    ) a
                                    inner join (
                                        select
                                            act_id,
                                            concat_ws('-', year, month, day) as stat_date
                                        from
                                            soda_international_dwd.dwd_marketing_active_base_v2_d_whole
                                        where
                                            concat_ws('-', year, month, day) between date_format('$[YYYY-MM-DD - 1D]', 'yyyy-MM-01')
                                            and '$[YYYY-MM-DD - 1D]'
                                            AND country_code in ('MX', 'CO', 'CR', 'PE')
                                            and is_td_sold_effect = 1
                                    ) as b on a.act_id = b.act_id
                                    and a.stat_date = b.stat_date
                            ) eng_promos on item_meta.item_id = eng_promos.item_id
                            and item_meta.stat_date = eng_promos.stat_date
                            LEFT JOIN(
                                SELECT
                                    concat_ws('-', year, month, day) as stat_date,
                                    item_id,
                                    is_special_activity,
                                    is_buygifts_activity,
                                    item_r_burn_rate,
                                    item_discount
                                FROM
                                    soda_international_app.app_item_tag_d_whole
                                WHERE
                                    concat_ws('-', year, month, day) between date_format('$[YYYY-MM-DD - 1D]', 'yyyy-MM-01')
                                    and '$[YYYY-MM-DD - 1D]'
                                    AND country_code IN ('MX', 'CO', 'CR', 'PE')
                            ) as autopromo on item_meta.item_id = autopromo.item_id
                            and item_meta.stat_date = autopromo.stat_date
                        GROUP BY
                            item_meta.item_id
                    ) as promo_days on ordered_ranked_items.item_id = promo_days.item_id
                WHERE
                    item_rank <= 5
            )
    );