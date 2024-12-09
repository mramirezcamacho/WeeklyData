--********************************************************************--
--When querying the hive partition table, in order to avoid a full table scan, you need to set the partition field in the where condition
----------------------------------
--The date variable of the original Datae datasource is changed to the system preset variable-please check the SQL rules for details. For example, concat(year,month,day)='[YYYYMMDD−1D]'
--Example: select * from database.table where pt='[YYYY-MM-DD-1D]'. The dataset will be executed every time it is refreshed. Current system days-1 day
----------------------------------
--Extract tool template variable usage: If you need to add template variables to the data set, please set the parameter 'data'. Note: The dataset cannot be accelerated after setting custom parameters
--Example: select orderid, cityname from database.table where cityname='{city_name}' dataset query can specify the city query
----------------------------------
--Full data acceleration, each time you accelerate the extraction of the latest data to cover the historical data, all the data you need in SQL, for example: select * from database.table where pt >='$[YYYYMMDD−15D]' and pt<='$[YYYYMMDD-1D]' Each acceleration will take the data of the last 15 days and only keep the data of the last 15 days
--Incremental data acceleration, each time the acceleration is extracted, the latest data is added and the historical data is added, and the latest data is taken from SQL, for example: select * from database.table where pt ='$[YYYYMMDD-1D]' The data of 1 day is added to the historical data, and the historical data from the first acceleration to the present will be retained
--********************************************************************--
SELECT
    shop_basic.country_code,
    shop_basic.stat_date,
    weekofyear(shop_basic.stat_date) WoY,
    shop_basic.city_id,
    shop_basic.brand_id,
    shop_basic.brand_name,
    city_name,
    region,
    store_type,
    potential,
    r_performance,
    priority,
    count(distinct shop_basic.shop_id) as leads,
    sum(nvl(is_rtbo, 0)) as RTBO,
    SUM(is_effective_online) as is_effective_online,
    SUM(is_effective_online_ssaa) as is_effective_online_ssaa,
    SUM(horas_disponibles) as horas_disponibles,
    SUM(horas_abiertas) as horas_abiertas,
    SUM(is_healthy_store) as is_healthy_store,
    SUM(is_healthy_store_ssaa) as is_healthy_store_ssaa,
    SUM(complete_orders) as complete_orders,
    SUM(is_active) as active_days,
    --COUNT(DISTINCT active_rs) as active_rs,
    SUM(is_first_online) as is_first_online,
    SUM(churn_ssaa) as churn_ssaa,
    SUM(shop_cnt_ssaa) as shop_cnt_ssaa,
    SUM(churn_cnt) as churn_cnt,
    COUNT(DISTINCT retention.shop_id) as retention_shop_cnt,
    pe_expansion,
    co_expansion
FROM
    (
        select
            stat_date,
            country_code,
            shop_id,
            brand_id,
            brand_name,
            city_id,
            city_name,
            CASE
                WHEN country_code = 'MX' THEN CASE
                    WHEN city_id in (52090100, 52151600) THEN 'CDMX'
                    WHEN city_id in (
                        52010100,
                        52110200,
                        52080200,
                        52080400,
                        52100200,
                        52110400,
                        52080800,
                        52110500,
                        52280500,
                        52190500,
                        52280100,
                        52220400,
                        52110600,
                        52050500,
                        52220200,
                        52240400,
                        52280300,
                        52050400,
                        52280400,
                        52320100,
                        52110300,
                        52050200,
                        52240100,
                        52110800,
                        52050300,
                        52280200
                    ) THEN 'Norte'
                    WHEN city_id in (
                        52280200,
                        52260100,
                        52060100,
                        52250100,
                        52020300,
                        52140500,
                        52260200,
                        52030200,
                        52030300,
                        52250400,
                        52060200,
                        52250300,
                        52020100,
                        52260300,
                        52140900,
                        52180200,
                        52020200,
                        52260400,
                        52260900
                    ) THEN 'Pacífico'
                    WHEN city_id in (
                        52160400,
                        52040100,
                        52230100,
                        52040200,
                        52230300,
                        52300200,
                        52301200,
                        52170200,
                        52302300,
                        52310300,
                        52200100,
                        52131100,
                        52300600,
                        52210400,
                        52070800,
                        52230200,
                        52070900,
                        52210600,
                        52290400,
                        52071100,
                        52300900,
                        52270100,
                        52301000,
                        52131500,
                        52290100,
                        52060300,
                        52120200,
                        52160800,
                        52160900,
                        52160200,
                        52301300,
                        52120500,
                        52070200,
                        52204400
                    ) THEN 'Sur'
                    ELSE 'Other'
                END
                WHEN country_code = 'CO' THEN 'CO'
                WHEN country_code = 'CR' THEN 'CR'
                WHEN country_code = 'PE' THEN 'PE'
                ELSE ''
            END AS region,
            case
                when stat_date < '2023-02-22'
                and nvl(is_dt_dk, 0) = 1 then 'DK'
                when stat_date >= '2023-02-22'
                and nvl(is_dark_kitchen, 0) = 1 then 'DK'
                when ka_type = 'ka' then 'KA'
                when ka_type = 'cka' then 'CKA'
                when ka_type = 'normal' then 'Normal'
                else ''
            end as store_type,
            potential,
            r_performance,
            priority,
            is_rtbo,
            pe_expansion,
            co_expansion
        from
            (
                select
                    stat_date,
                    country_code,
                    bizopp.shop_id,
                    brand_id,
                    brand_name,
                    city_id,
                    city_name,
                    ka_type,
                    potential,
                    is_rtbo,
                    priority,
                    is_dark_kitchen,
                    r_performance,
                    pe_expansion,
                    co_expansion,
                    max(
                        case
                            when stat_date >= first_managed_date
                            and (
                                end_managed_date = ''
                                or stat_date <= end_managed_date
                            ) then 1
                            else 0
                        end
                    ) is_dt_dk
                from
                    (
                        SELECT
                            concat_ws('-', year, month, day) as stat_date,
                            country_code,
                            shop_id,
                            ka_type,
                            brand_id,
                            brand_name,
                            city_id,
                            city_name,
                            case
                                when potential = '1' then 'T1'
                                when potential = '2' then 'T2'
                                when potential = '3' then 'T3'
                                else ''
                            end as potential,
                            r_performance,
                            is_didi_rtbo as is_rtbo,
                            priority,
                            is_dark_kitchen,
                            CASE
                                WHEN nvl(area_name, 'null') in (
                                    'BDArea 4 - D0 - San juan de miraflores',
                                    'BDArea 4 - 0 - D0 - San juan de miraflores',
                                    'BDArea 3 - D0 - San juan de miraflores',
                                    'BDArea 1 - D0 - San juan de miraflores',
                                    'BDArea 0 - D0 - San juan de miraflores',
                                    'BDArea 5 - D0 - San juan de miraflores',
                                    'BDArea 6 - D0 - San juan de miraflores',
                                    'BDArea 5 - D0 - Chorrillos',
                                    'BDArea 5 - D0 - Villa el salvador',
                                    'BDArea 3 - D0 - Villa maría del triunfo',
                                    'BDArea 0 - D0 - Villa el salvador',
                                    'BDArea 3 - D0 - Villa el salvador',
                                    'BDArea 4 - D0 - Villa el salvador',
                                    'BDArea 2 - D0 - Villa el salvador',
                                    'BDArea 1 - D0 - Villa el salvador',
                                    'BDArea 7 - D0 - Villa maría del triunfo',
                                    'BDArea 10 - D0 - San juan de lurigancho',
                                    'BDArea 6 - D0 - San juan de lurigancho',
                                    'BDArea 3 - 00 - D0 - San juan de luriganc',
                                    'BDArea 4 - D0 - San juan de lurigancho',
                                    'BDArea 11 - D0 - San juan de lurigancho',
                                    'BDArea 9 - D0 - Los olivos',
                                    'BDArea 2 - D0 - Los olivos',
                                    'BDArea 12 - D0 - San martín de porres',
                                    'BDArea 10 - D0 - Los olivos',
                                    'BDArea 3 - D0 - Comas',
                                    'BDArea 1 - D0 - Los olivos',
                                    'BDArea 8 - D0 - Los olivos',
                                    'BDArea 1 - D0 - Comas',
                                    'BDArea 0 - D0 - Comas',
                                    'BDArea 2 - D0 - Comas',
                                    'BDArea 2 - D0 - Puente piedra',
                                    'BDArea 1- D0 - Lurigancho',
                                    'BDArea 2- D0 - Lurigancho',
                                    'BDArea 12 - D0 - Ate',
                                    'BDArea 8 - D0 - Ate',
                                    'BDArea 6 - D0 - Ate',
                                    'BDArea 10 - D0 - Ate',
                                    'BDArea 3 - D0 - Santa anita',
                                    'BDArea 3 - D0 - El agustino'
                                ) THEN 'Yes'
                                ELSE 'No'
                            END AS pe_expansion,
                            CASE
                                WHEN nvl(district_id, 'null') in (
                                    'bdDistrict|5764607944139017545',
                                    'bdDistrict|5764608320758154129'
                                ) THEN 'Yes'
                                ELSE 'No'
                            END AS co_expansion
                        FROM
                            soda_international_dwm.dwm_bizopp_wide_d_whole
                        where
                            country_code in ('MX', 'CO', 'CR', 'PE')
                            and concat_ws('-', year, month, day) between '2023-01-01'
                            AND '$[YYYY-MM-DD - 1D]'
                            and shop_id is not null
                            and business_type = 1
                    ) as bizopp
                    LEFT JOIN (
                        select
                            split(shop_id, '_') [1] shop_id,
                            first_managed_date,
                            end_managed_date
                        from
                            ssl_food_bi.dk_offline_list
                        where
                            split(shop_id, '_') [1] is not null
                        group by
                            split(shop_id, '_') [1],
                            first_managed_date,
                            end_managed_date
                    ) as dk on bizopp.shop_id = dk.shop_id
                group by
                    stat_date,
                    country_code,
                    bizopp.shop_id,
                    brand_id,
                    brand_name,
                    city_id,
                    city_name,
                    ka_type,
                    potential,
                    is_rtbo,
                    is_dark_kitchen,
                    priority,
                    r_performance,
                    pe_expansion,
                    co_expansion
            ) as temp
    ) as shop_basic
    left join (
        select
            concat_ws('-', year, month, day) as stat_date,
            shop_id,
            nvl(is_effective_online, 0) as is_effective_online,
            complete_order_num as complete_orders,
            CASE
                WHEN complete_order_num > 0 THEN 1
                ELSE 0
            END as is_active,
            --CASE WHEN complete_order_num > 0 THEN shop_id ELSE null END as active_rs,
            CASE
                WHEN (
                    potential = 1
                    or potential = 2
                ) THEN NVL(is_effective_online, 0)
                ELSE 0
            END as is_effective_online_ssaa,
            nvl(set_duration, 0) / 3600 as horas_disponibles,
            nvl(open_duration_in_set, 0) / 3600 as horas_abiertas,
            CASE
                WHEN open_duration_in_set / set_duration > 0.6
                and is_headimg_default = 0
                and is_headimg = 1
                and available_item_num >= 5
                and is_logoimg = 1
                and is_logoimg_default = 0
                and available_pic_item_num / available_item_num >= 0.6 THEN 1
                ELSE 0
            END as is_healthy_store,
            CASE
                WHEN open_duration_in_set / set_duration > 0.6
                and is_headimg_default = 0
                and is_headimg = 1
                and available_item_num >= 5
                and is_logoimg = 1
                and is_logoimg_default = 0
                and available_pic_item_num / available_item_num >= 0.6
                and is_ready_online = 1
                and (
                    potential = 1
                    or potential = 2
                ) THEN 1
                ELSE 0
            END as is_healthy_store_ssaa
        from
            soda_international_dwm.dwm_shop_wide_d_whole
        where
            concat_ws('-', year, month, day) between '2023-01-01'
            and '$[YYYY-MM-DD - 1D]'
            AND country_code in ('MX', 'CO', 'CR', 'PE')
    ) as shop_active_stats on shop_basic.stat_date = shop_active_stats.stat_date
    and shop_basic.shop_id = shop_active_stats.shop_id
    left join (
        select
            concat_ws('-', year, month, day) as stat_date,
            shop_id,
            CASE
                WHEN if(
                    to_date(earliest_open_time) <= '2019-02-18',
                    '2019-02-18',
                    to_date(earliest_open_time)
                ) is null then '0'
                else '1'
            end as is_first_online
        from
            soda_international_dwd.dwd_shop_earliest_and_latestest_open_time
        where
            concat_ws('-', year, month, day) between '2023-01-01'
            and '$[YYYY-MM-DD - 1D]'
            and country_code in ('MX', 'CO', 'CR', 'PE')
    ) as efo on shop_basic.stat_date = efo.stat_date
    and shop_basic.shop_id = efo.shop_id
    left join (
        select
            t1.stat_date,
            t1.shop_id,
            is_never_online,
            not_online_day_cnt_from_last,
            NVL(churn_ssaa, 0) as churn_ssaa,
            NVL(shop_cnt_ssaa, 0) as shop_cnt_ssaa,
            churn_cnt,
            latest_open_day
        FROM
(
                select
                    distinct stat_date as stat_date,
                    shop_id,
                    is_never_online,
                    not_online_day_cnt_from_last,
                    CASE
                        WHEN (
                            potential = 1
                            or potential = 2
                        ) THEN 1
                        ELSE 0
                    END AS shop_cnt_ssaa,
                    CASE
                        WHEN not_online_day_cnt_from_last > 14
                        and (
                            potential = 1
                            or potential = 2
                        ) THEN 1
                        ELSE 0
                    END AS churn_ssaa,
                    CASE
                        WHEN not_online_day_cnt_from_last > 14 THEN 1
                    END as churn_cnt
                from
                    soda_international_dm.dm_shop_retention_d_whole
                where
                    country_code in ('MX', 'CO', 'CR', 'PE')
                    and stat_date between '2023-01-01'
                    and '$[YYYY-MM-DD - 1D]'
                    and shop_id is not null
            ) as t1
            LEFT JOIN (
                select
                    concat_ws('-', year, month, day) as stat_date,
                    shop_id,
                    substr(latest_open_time, 1, 10) as latest_open_day
                from
                    soda_international_dwd.dwd_shop_earliest_and_latestest_open_time
                where
                    country_code in ('MX', 'CO', 'CR', 'PE')
                    and concat_ws('-', year, month, day) between '2023-01-01'
                    and '$[YYYY-MM-DD - 1D]'
            ) as shop_open_close on t1.shop_id = shop_open_close.shop_id
            and t1.stat_date = shop_open_close.stat_date
        WHERE
            latest_open_day >= trunc(
                date_sub(trunc('$[YYYY-MM-DD - 1D]', 'MM'), 1),
                'MM'
            )
    ) retention on shop_basic.shop_id = retention.shop_id
    and shop_basic.stat_date = retention.stat_date
group by
    shop_basic.stat_date,
    weekofyear(shop_basic.stat_date),
    shop_basic.country_code,
    store_type,
    shop_basic.city_id,
    city_name,
    region,
    shop_basic.brand_id,
    shop_basic.brand_name,
    potential,
    r_performance,
    priority,
    pe_expansion,
    co_expansion
order by
    country_code,
    city_id ASC;