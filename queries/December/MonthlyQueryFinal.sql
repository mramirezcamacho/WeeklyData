select 
    kType,
    case
        when week_num in (36, 37, 38, 39) then 'September'
        when week_num in (31, 32, 33, 34, 35) then 'August'
        when week_num in (40, 41, 42, 43, 44) then 'October'
        when week_num in (45, 46, 47, 48) then 'November'
        else 'Other'
    END as month_data,
    country_code,
    avg(total_daily_orders_new_rs) as avg_per_week_total_daily_orders_new_rs,
    avg(imperfect_orders_rate) as avg_per_week_imperfect_orders_rate,
    avg(R1_count) as avg_per_week_R1_count,
    avg(R0_count) as avg_per_week_R0_count,
    avg(b_cancel_rate) as avg_per_week_b_cancel_rate,
    avg(total_complete_orders) as avg_per_week_total_complete_order
from
    (
        select
            principal.kType,
            principal.week_num,
            principal.country_code,
            principal.total_daily_orders_new_rs,
            imperfect_orders_rate,
            R1_count,
            R0_count,
            b_cancel_rate,
            total_orders_table.total_complete_orders
        from
            (
                SELECT
                    kType,
                    week_num,
                    country_code,
                    round(sum(daily_orders_per_week), 2) as total_daily_orders_new_rs
                from
                    (
                        select
                            bizopp.shop_id,
                            bizopp.country_code,
                            SUM(bizopp.complete_order_num) AS total_complete_orders,
                            sum(complete_order_num) / 7 as daily_orders_per_week,
                            CASE
                                WHEN (
                                    SUM(complete_order_num) / 7
                                ) > 15 THEN 'R0'
                                WHEN (
                                    SUM(complete_order_num) / 7
                                ) > 5 THEN 'R1'
                                ELSE 'R2 or worse'
                            END AS r_performance,
                            CASE
                                WHEN organization_type = 2 then 'CKA'
                                WHEN organization_type = 4 then 'SME'
                                else 'NAN'
                            END as kType,
                            weekofyear(
                                concat_ws('-', bizopp.year, bizopp.month, bizopp.day)
                            ) as week_num,
                            new_old
                        FROM
                            soda_international_dwm.dwm_shop_wide_d_whole as bizopp
                            LEFT JOIN (
                                select
                                    shop_id,
                                    first_online_time,
                                    case
                                        when first_online_time > '2024-01-01 00:00:00' then 'new'
                                        else 'old'
                                    end as new_old
                                from
                                    soda_international_dwm.dwm_bizopp_sign_process_d_whole
                                where
                                    country_code in('MX', 'CO', 'PE', 'CR')
                                    and concat_ws('-', year, month, day) = '2024-12-01'
                            ) as fo_data on fo_data.shop_id = bizopp.shop_id
                        WHERE
                            country_code IN ('MX', 'CO', 'PE', 'CR')
                            and concat_ws('-', bizopp.year, bizopp.month, bizopp.day) between '2024-09-02'
                            AND '2024-12-01'
                            and organization_type in (2, 4)
                        GROUP BY
                            bizopp.shop_id,
                            bizopp.country_code,
                            weekofyear(
                                concat_ws('-', bizopp.year, bizopp.month, bizopp.day)
                            ),
                            CASE
                                WHEN organization_type = 2 then 'CKA'
                                WHEN organization_type = 4 then 'SME'
                                else 'NAN'
                            END,
                            new_old
                        ORDER by
                            weekofyear(
                                concat_ws('-', bizopp.year, bizopp.month, bizopp.day)
                            ),
                            bizopp.shop_id
                    ) basic
                WHERE
                    new_old = 'new'
                group BY
                    kType,
                    week_num,
                    country_code
            ) as principal
            LEFT JOIN (
                select
                    week_num,
                    kType,
                    country_code,
                    sum(
                        case
                            when r_performance = 'R1' then 1
                            else 0
                        end
                    ) as R1_count,
                    sum(
                        case
                            when r_performance = 'R0' then 1
                            else 0
                        end
                    ) as R0_count
                from
                    (
                        select
                            shop_id,
                            country_code,
                            weekofyear(concat_ws('-', year, month, day)) as week_num,
                            SUM(complete_order_num) AS total_complete_orders,
                            sum(complete_order_num) / 7 as orders_per_week,
                            CASE
                                WHEN (
                                    sum(complete_order_num) / 7
                                ) > 15 THEN 'R0'
                                WHEN (
                                    sum(complete_order_num) / 7
                                ) > 5 THEN 'R1'
                                ELSE 'R2 or worse'
                            END AS r_performance,
                            CASE
                                WHEN organization_type = 2 then 'CKA'
                                WHEN organization_type = 4 then 'SME'
                                else 'NAN'
                            END as kType
                        FROM
                            soda_international_dwm.dwm_shop_wide_d_whole
                        WHERE
                            country_code IN ('MX', 'CO', 'PE', 'CR')
                            and concat_ws('-', year, month, day) between '2024-09-02'
                            AND '2024-12-01'
                            and organization_type in (2, 4)
                        GROUP BY
                            shop_id,
                            country_code,
                            weekofyear(concat_ws('-', year, month, day)),
                            CASE
                                WHEN organization_type = 2 then 'CKA'
                                WHEN organization_type = 4 then 'SME'
                                else 'NAN'
                            END
                    ) basic
                group by
                    week_num,
                    kType,
                    country_code
            ) as r0r1 on r0r1.week_num = principal.week_num
            AND r0r1.kType = principal.kType
            AND r0r1.country_code = principal.country_code
            LEFT JOIN (
                
                select
                    weekofyear(order_base.stat_date) as weekNumber,
                    order_base.country_code as country_code_usable,
                    count(
                        distinct case
                            when nvl(missing_food, 0) + nvl(Wrong_Food, 0) + nvl(Whole_Sent_Wrong, 0) + nvl(missing_food_wrong_food_whole_sent_wrong_cpo, 0) + nvl(c_d_tag_ids, 0) > 0 then order_base.order_id
                        end
                    ) / count(
                        distinct case
                            when is_td_complete = 1 then order_base.order_id
                        end
                    ) as imperfect_orders_rate,
                    kType as vertical
                from
                    (
                        select
                            concat_ws('-', year, month, day) as stat_date,
                            shop_id,
                            concat("_", city_id) as city_id,
                            upper(country_code) as country_code,
                            is_td_complete,
                            is_td_pay,
                            concat('_', order_id) as order_id
                        from
                            soda_international_dwd.dwd_order_wide_d_increment
                        where
                            1 = 1
                            and upper(country_code) in ('MX', 'CO', 'PE', 'CR')
                            and concat_ws('-', year, month, day) between '2024-09-02'
                            AND '2024-12-01'
                            and channel = 0
                            and (
                                '0' == '0'
                                or city_id in (0)
                            )
                            and (
                                is_td_complete = 1
                                or is_td_cancel = 1
                                or is_td_pay = 1
                            )
                    ) as order_base
                    LEFT JOIN (
                        select
                            
                            shop_id,
                            order_id,
                            c_d_tag_ids
                        from
                            (
                                select
                                    
                                    shop_id,
                                    order_id,
                                    case
                                        when (
                                            c_d_tag_ids like '%302011%'
                                            or c_b_tag_ids like '%202001%'
                                            or c_b_tag_ids like '%202003%'
                                            or c_b_tag_ids like '%202006%'
                                            or c_b_tag_ids like '%202014%'
                                        ) then 1
                                        else 0
                                    end as c_d_tag_ids
                                from
                                    (
                                        select
                                            shop_id,
                                            order_id,
                                            order_date,
                                            c_d_tag_ids,
                                            c_b_tag_ids,
                                            regexp_replace(sub_comment, '["\\[\\]]', '') as user_comment
                                        from
                                            (
                                                SELECT
                                                    to_date(complete_time_local) as order_date,
                                                    shop_id,
                                                    concat('_', order_id) as order_id,
                                                    c_b_tags AS categories,
                                                    c_b_score as score,
                                                    c_b_tag_ids,
                                                    c_d_tag_ids
                                                FROM
                                                    soda_international_dwd.dwd_order_evaluation_d_increment AS evals
                                                WHERE
                                                    1 = 1
                                                    AND country_code in ('MX', 'CO', 'PE', 'CR')
                                                    and concat_ws('-', year, month, day) between '2024-09-02'
                                                    AND '2024-12-01'
                                            ) as tb lateral view explode(split(categories, ',')) Subs AS sub_comment
                                    ) b
                            ) c
                    ) as bad_reviews on order_base.order_id = bad_reviews.order_id 
                    LEFT JOIN (
                        select
                            *
                        from
                            (
                                select
                                    
                                    country_code,
                                    apply_id,
                                    concat('_', order_id) as order_id,
                                    apply_type,
                                    split(selected_reason_tag_list, ',') as reason_tag_list,
                                    case
                                        when array_CONTAINS(split(selected_reason_tag_list, ','), '1') then 1
                                        else 0
                                    end as Missing_Food,
                                    case
                                        when array_contains(split(selected_reason_tag_list, ','), '2')
                                        and (
                                            get_json_object(
                                                get_json_object(apply_info, '$.additionalDetails'),
                                                '$.wholeSentWrong'
                                            ) is null
                                            or get_json_object(
                                                get_json_object(apply_info, '$.additionalDetails'),
                                                '$.wholeSentWrong'
                                            ) = 'false'
                                        ) then 1
                                        else 0
                                    end as Wrong_Food,
                                    case
                                        when array_CONTAINS(split(selected_reason_tag_list, ','), '3') then 1
                                        else 0
                                    end as Food_Damage,
                                    case
                                        when array_CONTAINS(split(selected_reason_tag_list, ','), '6') then 1
                                        else 0
                                    end as Food_Quality,
                                    case
                                        when apply_type = 4 then 1
                                        else 0
                                    end as Didnt_Receive_Order,
                                    case
                                        when array_contains(split(selected_reason_tag_list, ','), '2')
                                        and get_json_object(
                                            get_json_object(apply_info, '$.additionalDetails'),
                                            '$.wholeSentWrong'
                                        ) = 'true' then 1
                                        else 0
                                    end as Whole_Sent_Wrong,
                                    row_number() over(
                                        partition by apply_id,
                                        order_id
                                        order by
                                            update_time_local desc
                                    ) rn,
                                    get_json_object(
                                        get_json_object(apply_info, '$.additionalDetails'),
                                        '$.sealDetail'
                                    ) as seal_detail
                                from
                                    soda_international_dwd.dwd_order_refund_apply_d_increment
                                where
                                    1 = 1
                                    and concat_ws('-', year, month, day) between '2024-09-02'
                                    AND '2024-12-01'
                                    and apply_type = 3
                            ) m
                        where
                            rn = 1
                            and country_code in ('MX', 'CO', 'PE', 'CR')
                    ) as after_sales on after_sales.order_id = order_base.order_id 
                    LEFT JOIN (
                        select
                            concat('_', order_id) as order_id,
                            
                            category_id,
                            case
                                when category_id in (
                                    '960030884',
                                    '960020854',
                                    '960030886',
                                    '960020822',
                                    '960030876',
                                    '960030890',
                                    '960020860',
                                    '960030892',
                                    '960105621',
                                    '960105619',
                                    '960020862',
                                    '960030894',
                                    '960020856',
                                    '960030888',
                                    '960020824'
                                ) then 1
                                else 0
                            end as missing_food_wrong_food_whole_sent_wrong_cpo,
                            case
                                when category_id in ('960020854', '960030886') then 1
                                else 0
                            end as small_portions_c,
                            case
                                when category_id in ('960030884') then 1
                                else 0
                            end as damaged_c,
                            case
                                when category_id in ('960020862', '960030894') then 1
                                else 0
                            end as wrong_c,
                            case
                                when category_id in ('960020856', '960030888') then 1
                                else 0
                            end as missing_c,
                            case
                                when category_id in ('960020860', '960030892') then 1
                                else 0
                            end as different_c,
                            case
                                when category_id in (
                                    '960020822',
                                    '960030876',
                                    '960030890',
                                    '960105621',
                                    '960105619',
                                    '960020824'
                                ) then 1
                                else 0
                            end as other_c,
                            '1' as incoming_cs
                        from
                            soda_international_dwd.dwd_service_ticket_global_d_increment
                        where
                            concat_ws('-', year, month, day) between '2024-09-02'
                            AND '2024-12-01'
                            and country_code in ('MX', 'CO', 'PE', 'CR')
                            and order_id is not null
                            and length(order_id) > 3
                            and is_auto <> '1'
                            and category_id not in (
                                '960043658',
                                '960021416',
                                '960043656',
                                '960022290',
                                '960043482',
                                '960043480',
                                '960043476',
                                '960043570',
                                '960019030',
                                '960043568'
                            )
                            and category_id not in ('960007794', '960007832')
                            and requester_type in ('1')
                    ) as incoming on incoming.order_id = order_base.order_id
                    LEFT JOIN (
                        select
                            shop_id,
                            CASE
                                WHEN organization_type = 2 then 'CKA'
                                WHEN organization_type = 4 then 'SME'
                                else 'NAN'
                            END as kType
                        from
                            soda_international_dwm.dwm_bizopp_wide_d_whole
                        where
                            concat_ws('-', year, month, day) = '2024-12-01'
                            and country_code in ('MX', 'CO', 'PE', 'CR')
                            and organization_type in (2, 4)
                    ) as kaType on kaType.shop_id = order_base.shop_id
                where
                    kaType.kType is not null
                group by
                    weekofyear(order_base.stat_date),
                    kType,
                    order_base.country_code
            ) as imperfect_table on imperfect_table.weekNumber = principal.week_num
            AND imperfect_table.vertical = principal.kType
            AND imperfect_table.country_code_usable = principal.country_code
            LEFT JOIN (
                select
                    weekofyear(concat_ws('-', year, month, day)) as weekNumber,
                    country_code,
                    sum(b_cancel_order_cnt) / sum(pay_order_cnt) as b_cancel_rate,
                    CASE
                        WHEN organization_type = 2 then 'CKA'
                        WHEN organization_type = 4 then 'SME'
                        else 'NAN'
                    END as kType
                from
                    soda_international_dwm.dwm_shop_wide_d_whole
                where
                    concat_ws('-', year, month, day) between '2024-09-02'
                    AND '2024-12-01'
                    AND country_code in('MX', 'CO', 'PE', 'CR')
                    and organization_type in (2, 4)
                group by
                    weekofyear(concat_ws('-', year, month, day)),
                    CASE
                        WHEN organization_type = 2 then 'CKA'
                        WHEN organization_type = 4 then 'SME'
                        else 'NAN'
                    END,
                    country_code
            ) as cancel_table on cancel_table.weekNumber = principal.week_num
            AND cancel_table.kType = principal.kType
            AND cancel_table.country_code = principal.country_code
            LEFT JOIN (
                select
                    CASE
                        WHEN organization_type = 2 then 'CKA'
                        WHEN organization_type = 4 then 'SME'
                        else 'NAN'
                    END as kType,
                    country_code,
                    weekofyear(
                        concat_ws('-', bizopp.year, bizopp.month, bizopp.day)
                    ) as week_num,
                    SUM(bizopp.complete_order_num) AS total_complete_orders
                FROM
                    soda_international_dwm.dwm_shop_wide_d_whole as bizopp
                    LEFT JOIN (
                        select
                            shop_id,
                            first_eff_online_date,
                            case
                                when first_eff_online_date > '2024-01-01 00:00:00' then 'new'
                                else 'old'
                            end as new_old
                        from
                            soda_international_dwm.dwm_bizopp_sign_process_d_whole
                        where
                            country_code in('MX', 'CO', 'PE', 'CR')
                            and concat_ws('-', year, month, day) = '2024-12-01'
                    ) as fo_data on fo_data.shop_id = bizopp.shop_id
                WHERE
                    country_code IN ('MX', 'CO', 'PE', 'CR')
                    and concat_ws('-', bizopp.year, bizopp.month, bizopp.day) between '2024-09-02'
                    AND '2024-12-01'
                    and organization_type in (2, 4)
                GROUP BY
                    weekofyear(
                        concat_ws('-', bizopp.year, bizopp.month, bizopp.day)
                    ),
                    CASE
                        WHEN organization_type = 2 then 'CKA'
                        WHEN organization_type = 4 then 'SME'
                        else 'NAN'
                    END,
                    country_code
            ) as total_orders_table on total_orders_table.week_num = principal.week_num
            AND total_orders_table.kType = principal.kType
            AND total_orders_table.country_code = principal.country_code
    ) all_the_soup
group BY
    kType,
    case
        when week_num in (36, 37, 38, 39) then 'September'
        when week_num in (31, 32, 33, 34, 35) then 'August'
        when week_num in (40, 41, 42, 43, 44) then 'October'
        when week_num in (45, 46, 47, 48) then 'November'
        else 'Other'
    END,
    country_code
order BY
    kType,
    case
        when week_num in (36, 37, 38, 39) then 'September'
        when week_num in (31, 32, 33, 34, 35) then 'August'
        when week_num in (40, 41, 42, 43, 44) then 'October'
        when week_num in (45, 46, 47, 48) then 'November'
        else 'Other'
    END,
    country_code;