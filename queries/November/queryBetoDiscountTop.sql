select
    shop_name,
    item_id,
    is_special_activity,
    item_price,
    is_buy_1_get_2,
    is_buy_2_get_3,
    is_buy_3_get_4,
    item_discount,
    item_r_burn_rate,
    discount_price
from
    soda_international_app.app_item_tag_d_whole
where
    country_code in ('MX', 'CO', 'CR', 'PE')
    and CONCAT_WS('-', year, month, day) = '2024-10-30'
    and (
        is_buy_1_get_2 <> 0
        or is_buy_2_get_3 <> 0
        or is_buy_3_get_4 <> 0
    )
limit
    50;