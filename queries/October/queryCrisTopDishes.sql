select
    shop_id_table.date_,
    shop_id,
    shop_id_table.order_id,
    items_table.item_id,
    item_name,
    parent_mdu_id,
    content,
    amount,
    item_price,
    main_category_name,
    item_discount
from
    (
        select
            shop_id,
            order_id,
            CONCAT_WS('-', year, month, day) as date_
        from
            soda_international_dwd.dwd_order_wide_d_increment
        where
            CONCAT_WS('-', year, month, day) BETWEEN '2024-10-10'
            AND '2024-10-20'
            and shop_id = '5764607523043411655'
    ) shop_id_table
    left JOIN (
        select
            order_id,
            item_id,
            parent_mdu_id,
            content,
            amount,
            CONCAT_WS('-', year, month, day) as date_
        from
            soda_international_dwd.dwd_order_item_d_increment
        where
            CONCAT_WS('-', year, month, day) BETWEEN '2024-10-10'
            AND '2024-10-20'
    ) items_table on shop_id_table.order_id = items_table.order_id
    and shop_id_table.date_ = items_table.date_
    left JOIN (
        select
            item_id,
            item_name,
            item_price,
            main_category_name,
            item_discount,
            CONCAT_WS('-', year, month, day) as date_
        from
        where
            CONCAT_WS('-', year, month, day) BETWEEN '2024-10-10'
            AND '2024-10-20'
            AND item_name is not null
            AND item_price is not null
            AND main_category_name is not null
            AND item_discount is not null
    ) item_description on item_description.item_id = items_table.item_id
    and item_description.date_ = items_table.date_
where
    item_name is not null
order by
    shop_id_table.date_,
    shop_id,
    shop_id_table.order_id;