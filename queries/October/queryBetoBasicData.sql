select
    shop_id,
    is_suspended,
    suspend_reason,
    bd_user_name_extract
from
    soda_international_dwm.dwm_bizopp_wide_d_whole
where
    shop_id = '5764607523068575855'
    AND country_code IN ('MX', 'CO', 'PE', 'CR')
    AND CONCAT_WS('-', year, month, day) BETWEEN '2024-01-01'
    AND '2024-09-30';