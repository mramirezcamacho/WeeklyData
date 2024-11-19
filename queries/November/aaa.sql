select
    base.date_data,
    base.country_code,
    city_table.city_name,
    city_table.priority,
    base.shop_id,
    base.complete_order_num_sum
from
    (
        select
            concat_ws('-', year, month, day) as date_data,
            country_code,
            shop_id,
            sum(nvl(complete_order_num, 0)) as complete_order_num_sum
        from
            soda_international_dwm.dwm_shop_wide_d_whole
        where
            concat_ws('-', year, month, day) between '2024-10-01'
            and '2024-10-31'
            and country_code in ('MX', 'CO', 'CR', 'PE')
        group by
            concat_ws('-', year, month, day),
            country_code,
            shop_id
    ) base
    LEFT JOIN (
        SELECT
            shop_id,
            city_name,
            priority
        from
            soda_international_dwm.dwm_bizopp_wide_d_whole
        where
            concat_ws('-', year, month, day) = '2024-10-31'
            and country_code in ('MX', 'CO', 'CR', 'PE')
            and city_name is not null
    ) city_table on base.shop_id = city_table.shop_id
order BY
    base.country_code,
    city_table.city_name,
    city_table.priority,
    base.shop_id,
    base.date_data;