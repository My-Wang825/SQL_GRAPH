/*
 -- 描述：氧化铝物料单价表-月
 -- 日期：2025-10-28
 -- 开发者：数语
 */

-- 删除TargetTable已有数据
truncate table sdhq.dwd_prd_ao_mat_unprice_m_ufd;

-- 将SourceTable数据插入TargetTable
/*回收冷凝水单价等单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name,
     recovery_condwater_unprice, lowpres_steam_unprice, elect_unprice, highpres_steam_unprice,
     steam_sales_unprice, elect_sales_unprice, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                        as id,
    mth                                           as prod_ym,
    vdt.last_day                                  as prod_ym_last_day,
    '氧化铝'                                      as business_format,
    'SDHQ_YHLGS'                                  as company_code,
    '氧化铝公司'                                  as company_name,
    condwater_price                               as recovery_condwater_unprice, -- 回收冷凝水单价
    cost_steam_price                              as lowpres_steam_unprice,      -- 低压蒸汽单价
    cost_elect_price                              as elect_unprice,              -- 电单价
    cost_steam_price                              as highpres_steam_unprice,     -- 高压蒸汽单价
    revenue_steam_price                           as steam_sales_unprice,        -- 蒸汽单价_算毛利
    revenue_elect_price                           as elect_sales_unprice,        -- 电单价_算毛利
    'fryw'                                        as source_system,
    'dw_centor_report.yhl_fill_energy_unit_price' as source_table_name,
    mth                                           as source_id,
    now()                                         as etl_time
from
    sdhq.ods_fryw_yhl_fill_energy_unit_price_ufd a
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*水单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name, water_type,
     water_unprice, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                        as id,
    mth                                           as prod_ym,
    vdt.last_day                                  as prod_ym_last_day,
    '氧化铝'                                      as business_format,
    'SDHQ_YHLGS'                                  as company_code,
    '氧化铝公司'                                  as company_name,
    water_type,    -- 水类型
    water_unprice, -- 水单价
    'fryw'                                        as source_system,
    'dw_centor_report.yhl_fill_energy_unit_price' as source_table_name,
    mth                                           as source_id,
    now()                                         as etl_time
from
    (
        select
            mth,
            map(
                    '邹平黄河水', zp_huanghe_water_price,
                    '邹平台子水', zp_taizi_water_price,
                    '北海沾化黄河水', bh_zh_huanghe_water_price
            ) as fmap
        from
            sdhq.ods_fryw_yhl_fill_energy_unit_price_ufd
        ) t lateral view explode_map(fmap) tmp as water_type, water_unprice
    left join sdhq.v_prd_ym_date vdt
on t.mth = vdt.prod_ym
where
    water_unprice <> 0
;
/*矿石单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name, bxt_type,
     bxt_unprice, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                     as id,
    mth                                        as prod_ym,
    vdt.last_day                               as prod_ym_last_day,
    '氧化铝'                                   as business_format,
    'SDHQ_YHLGS'                               as company_code,
    '氧化铝公司'                               as company_name,
    bxt_type,    -- 矿石类型
    bxt_unprice, -- 矿石单价
    'fryw'                                     as source_system,
    'dw_centor_report.yhl_fill_ore_unit_price' as source_table_name,
    mth                                        as source_id,
    now()                                      as etl_time
from
    (
        select
            mth,
            map(
                    '高温澳矿', high_temp_aus_ore_price,
                    '低温澳矿', low_temp_aus_ore_price,
                    '多米尼加矿', dominican_ore_price,
                    '几内亚矿', guinea_ore_price,
                    '所罗门矿', solomon_ore_price,
                    '几内亚矿(CBG)', guinea_csg_ore_price,
                    '牙买加矿', jamaica_ore_price,
                    '低硅几内亚矿', guinea_ls_ore_price
            ) as fmap
        from
            sdhq.ods_fryw_yhl_fill_ore_unit_price_ufd
        ) t lateral view explode_map(fmap) tmp as bxt_type, bxt_unprice
    left join sdhq.v_prd_ym_date vdt
on t.mth = vdt.prod_ym
where
    bxt_unprice <> 0
;
/*氧化铝、氢氧化铝销售单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name, ao_sales_unprice,
     ah_sales_unprice, source_system, source_table_name, source_id, etl_time)
select
    uuid()                             as id,
    dt.prod_ym                         as prod_ym,
    vdt.last_day                       as prod_ym_last_day,
    '氧化铝'                           as business_format,
    'SDHQ_YHLGS'                       as company_code,
    '氧化铝公司'                       as company_name,
    sum(if(VarietyCode_GUID = '99BA5433-DF5F-A898-C8E0-78B8BA55F251', OutStorageQuantity * Price,
           0)) /
    sum(if(VarietyCode_GUID = '99BA5433-DF5F-A898-C8E0-78B8BA55F251', OutStorageQuantity,
           0))                         as ao_sales_unprice, -- 氧化铝销售单价
    sum(if(VarietyCode_GUID = '5EAF4489-B30D-4ED6-B181-A6A52CC76992', OutStorageQuantity * Price,
           0)) /
    sum(if(VarietyCode_GUID = '5EAF4489-B30D-4ED6-B181-A6A52CC76992', OutStorageQuantity,
           0))                         as ah_sales_unprice, -- 氢氧化铝销售单价
    'hqsms'                            as source_system,
    'sales.EndProduct.OutStorageQuery' as source_table_name,
    dt.prod_ym                         as source_id,
    now()                              as etl_time
from
    sdhq.ods_hqsms_outstoragequery_uid a
    left join sdhq.dim_prd_date dt on date(a.DeliveryDate) = dt.dt_date
    left join sdhq.v_prd_ym_date vdt on dt.prod_ym = vdt.prod_ym
where
      a.DelFlag = 0
  and a.BusinessType = '外销'
  and a.DeliveryDate >= '2025-11-25'
group by
    dt.prod_ym, vdt.last_day
;
/*铁粉销售单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name, fe_type,
     fe_sales_unprice, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                                    as id,
    dt.prod_ym                                                as prod_ym,
    vdt.last_day                                              as prod_ym_last_day,
    '氧化铝'                                                  as business_format,
    'SDHQ_YHLGS'                                              as company_code,
    '氧化铝公司'                                              as company_name,
    concat('铁粉_', b.SpecModelName)                          as fe_type,          -- 铁粉类型
    sum(OutStorageQuantity * Price) / sum(OutStorageQuantity) as fe_sales_unprice, -- 铁粉销售单价
    'jtsms'                                                   as source_system,
    'jtsales.EndProduct.OutStorageQuery'                      as source_table_name,
    dt.prod_ym                                                as source_id,
    now()                                                     as etl_time
from
    sdhq.ods_jtsms_outstoragequery_uid a
    left join sdhq.ods_jtsms_specmodelcodetable_ufd b
        on a.SpecModelCode_GUID = b.SpecModelCode_GUID and b.DelFlag = 0
    left join sdhq.dim_prd_date dt on date(a.DeliveryDate) = dt.dt_date
    left join sdhq.v_prd_ym_date vdt on dt.prod_ym = vdt.prod_ym
where
      a.DelFlag = 0
  and a.VarietyCode_GUID in
      ('820546E5-989F-42DA-BDBA-A9E68951AF7B',
       '0F4C6008-FC4C-4182-B6D2-F378462B26FA',
       '060A6EF6-1807-4ACC-BBF5-47292ECE935F',
       'A7D9AB5E-81AE-49FF-A20E-1713F55FB4D5')
  and a.DeliveryDate >= '2025-11-25'
group by
    dt.prod_ym, concat('铁粉_', b.SpecModelName), vdt.last_day
;
/**/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_name, company_code,
     ao_sales_adjust_price, ah_sales_adjust_price, liquid_adjust_price, lime_adjust_price,
     flocculant_adjust_price, other_materials_adjust_price, desul_material_adjust_price,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                        as id,
    mth                                           as prod_ym,
    vdt.last_day                                  as prod_ym_last_day,
    '氧化铝'                                      as business_format,
    org.module_nm                                 as company_name,
    org.module_no                                 as company_code,
    ao_sale_price                                 as ao_sales_adjust_price,        -- 氧化铝销售修正单价
    ah_sale_price                                 as ah_sales_adjust_price,        -- 氢氧化铝销售修正单价
    liquid_soda_price                             as liquid_adjust_price,          -- 液碱(100%NaOH)修正单价
    lime_price                                    as lime_adjust_price,            -- 石灰修正单价
    flocculant_price                              as flocculant_adjust_price,      -- 絮凝剂修正单价
    other_aux_materials_price                     as other_materials_adjust_price, -- 其他原辅料修正单价
    desul_raw_material_price                      as desul_material_adjust_price,  -- 脱硫原材料修正单价
    'fryw'                                        as source_system,
    'dw_centor_report.yhl_fill_unit_price_adjust' as source_table_name,
    concat(mth, branch_no)                        as source_id,
    now()                                         as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_unit_price_adjust_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*铁粉修正销售单价*/
insert into
    sdhq.dwd_prd_ao_mat_unprice_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, company_code, company_name, fe_type,
     iron_sales_adjust_price, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                           as id,
    prod_ym                                          as prod_ym,
    vdt.last_day                                     as prod_ym_last_day,
    '氧化铝'                                         as business_format,
    'SDHQ_YHLGS'                                     as company_code,
    '氧化铝公司'                                     as company_name,
    fe_type                                          as fe_type,                 -- 铁粉类型
    iron_sales_adjust_price                          as iron_sales_adjust_price, -- 铁粉销售单价
    'fryw'                                           as source_system,
    'dw_centor_report.yhl_fill_ao_unit_price_adjust' as source_table_name,
    ''                                               as source_id,
    now()                                            as etl_time
from
    (
        select
            mth,
            map(
                    '铁粉_42%', 42iron_sale_price,
                    '铁粉_45%', 45iron_sale_price,
                    '铁粉_50%', 50iron_sale_price
            ) as fmap
        from
            sdhq.ods_fryw_yhl_fill_ao_unit_price_adjust_ufd a
        where
            branch_no = 'SDHQ_YHLGS'
        ) t lateral view explode_map(fmap) tmp as fe_type, iron_sales_adjust_price
    left join sdhq.v_prd_ym_date vdt
on t.mth = vdt.prod_ym
;