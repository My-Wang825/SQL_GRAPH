-- 删除TargetTable已有数据
truncate table sdhq.dwd_prd_ao_fact_d_ufd;

-- 将SourceTable数据插入TargetTable
/*氧1主指标*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, ao_roast_prod, ao_actual_prod, ah_exportqty, recovery_condwater_qty,
     lowpres_steam_consumqty, highpres_steam_consumqty, coal_heatvalue, coal_consumqty,
     lime_consumqty, floc_consumqty, ao_elect_consumqty, water_type, water_consumqty,
     liqcaus_consumqty, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                                            as id,
    ds                                                                as dt_date,
    '氧化铝'                                                          as business_format,
    'SDHQ_YHLGS_0102'                                                 as branch_factory_code,
    org.branch_factory_nm                                             as branch_factory_name,
    org.company_no                                                    as branch_company_code,
    org.company_nm                                                    as branch_company_name,
    ao_prod_roast_total * 1                                           as ao_roast_prod,            -- 氧化铝焙烧产量
    ao_prod_theo_calc * 1                                             as ao_actual_prod,           -- 氧化铝实际产量
    ao_sales_export * 1                                               as ah_exportqty,             -- 	氢氧化铝外销量
    condensate_back_power_plant * 1                                   as recovery_condwater_qty,   -- 	回收冷凝水量
    energy_total_cons_steam_low * 1                                   as lowpres_steam_consumqty,  -- 	低压蒸汽耗用量
    energy_total_cons_steam_high * 1                                  as highpres_steam_consumqty, -- 	高压蒸汽耗用量
    coal_calorific_value_furnace * 1                                  as coal_heatvalue,           -- 	煤炭发热值
    energy_total_cons_coal * 1                                        as coal_consumqty,           -- 	煤炭耗用量
    ifnull(mat_input_total_lime_causticizing, 0) +
    ifnull(mat_input_total_lime_control, 0)                           as lime_consumqty,           -- 	石灰耗用量
    ifnull(mat_input_total_flocculant_settle, 0) +
    ifnull(mat_input_total_flocculant_sep, 0)                         as floc_consumqty,           -- 	絮凝剂耗用量
    energy_total_cons_electricity * 1                                 as ao_elect_consumqty,       -- 	氧化铝电耗用量
    if(energy_total_cons_fresh_water is null, null, '北海沾化黄河水') as water_type,               -- 水类型
    energy_total_cons_fresh_water * 1                                 as water_consumqty,          -- 	氧化铝水耗用量
    mat_input_total_liquid_alkali * 1                                 as liqcaus_consumqty,        -- 	液碱耗用量
    'y1_report'                                                       as source_system,
    'alo1_fill_production_economic_daily_1_report'                    as source_table_name,
    id                                                                as source_id,
    now()                                                             as etl_time
from
    sdhq.ods_aloms_alo1_fill_production_economic_daily_1_report_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on 'SDHQ_YHLGS_0102' = org.branch_factory_no
where
    sjwd = '日'
;
/*氧1_单耗*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, lowpres_steam_unconsum, elect_unconsum, highpres_steam_unconsum,
     bxt_unconsum, coal_unconsum, lime_unconsum, water_unconsum, floc_unconsum, liqcaus_unconsum,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                         as id,
    ds                                             as dt_date,
    '氧化铝'                                       as business_format,
    'SDHQ_YHLGS_0102'                              as branch_factory_code,
    org.branch_factory_nm                          as branch_factory_name,
    org.company_no                                 as branch_company_code,
    org.company_nm                                 as branch_company_name,
    energy_unit_cons_steam_low * 1                 as lowpres_steam_unconsum,  -- 	低压蒸汽单耗
    mat_unit_cons_flocculant_dian * 1              as elect_unconsum,          -- 	电单耗
    energy_unit_cons_steam_high * 1                as highpres_steam_unconsum, -- 	高压蒸汽单耗
    mat_unit_cons_ore * 1                          as bxt_unconsum,            -- 	矿石单耗
    energy_unit_cons_coal * 1                      as coal_unconsum,           -- 	煤炭单耗
    ifnull(mat_unit_cons_lime_causticizing, 0) +
    ifnull(mat_unit_cons_lime_control, 0)          as lime_unconsum,           -- 	石灰单耗
    energy_unit_cons_fresh_water * 1               as water_unconsum,          -- 	水单耗
    ifnull(mat_unit_cons_flocculant_settle, 0) +
    ifnull(mat_unit_cons_flocculant_sep, 0)        as floc_unconsum,           -- 	絮凝剂单耗
    mat_unit_cons_liquid_alkali * 1                as liqcaus_unconsum,        -- 	液碱(100%NaOH)单耗
    'y1_report'                                    as source_system,
    'alo1_fill_production_economic_daily_1_report' as source_table_name,
    id                                             as source_id,
    now()                                          as etl_time
from
    sdhq.ods_aloms_alo1_fill_production_economic_daily_1_report_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on 'SDHQ_YHLGS_0102' = org.branch_factory_no
where
    sjwd = '月'
;
/*氧2345主指标*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, ao_roast_prod, ao_actual_prod, other_convert_ao, ah_exportqty,
     recovery_condwater_qty, lowpres_steam_consumqty, highpres_steam_consumqty, cokegas_consumqty,
     coal_consumqty, lime_consumqty, natgas_consumqty, floc_consumqty, ao_elect_consumqty,
     water_type, water_consumqty, liqcaus_consumqty, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                           as id,
    ds                                               as dt_date,
    '氧化铝'                                         as business_format,
    a.company_no                                     as branch_factory_code,
    org.branch_factory_nm                            as branch_factory_name,
    org.company_no                                   as branch_company_code,
    org.company_nm                                   as branch_company_name,
    ao_prod_roast_total                              as ao_roast_prod,            -- 氧化铝焙烧产量
    ao_prod_theo_calc                                as ao_actual_prod,           -- 氧化铝实际产量
    ao_other_convert                                 as other_convert_ao,         -- 其他折AO
    ao_sales_export                                  as ah_exportqty,             -- 氢氧化铝外销量
    condensate_back_power_plant                      as recovery_condwater_qty,   -- 回收冷凝水量
    ifnull(energy_total_cons_steam_low, 0) +
    ifnull(energy_total_cons_steam, 0)               as lowpres_steam_consumqty,  -- 低压蒸汽耗用量
    energy_total_cons_steam_high                     as highpres_steam_consumqty, -- 高压蒸汽耗用量
    energy_total_cons_coking_gas                     as cokegas_consumqty,        -- 焦化煤气耗用量
    energy_total_cons_coal                           as coal_consumqty,           -- 煤炭耗用量
    ifnull(mat_input_total_lime_causticizing, 0) + ifnull(mat_input_total_lime_control, 0) +
    ifnull(mat_input_total_lime_pre_mill, 0) + ifnull(mat_input_total_lime_dissolution, 0) +
    ifnull(mat_input_total_lime_desulfurization, 0)  as lime_consumqty,           -- 石灰耗用量
    energy_total_cons_natural_gas                    as natgas_consumqty,         -- 天然气耗用量
    ifnull(mat_input_total_flocculant_washing, 0) +
    ifnull(mat_input_total_flocculant_separation, 0) as floc_consumqty,           -- 絮凝剂耗用量
    energy_total_cons_electricity                    as ao_elect_consumqty,       -- 氧化铝电耗用量
    '北海沾化黄河水'                                 as water_type,               -- 水类型
    if(left(a.company_no, 13) != 'SDHQ_YHLGS_03', energy_total_cons_fresh_water,
       null)                                         as water_consumqty,          -- 氧化铝水耗用量
    mat_input_total_liquid_alkali                    as liqcaus_consumqty,        -- 液碱耗用量
    'y2345_report'                                   as source_system,
    'yhl_rpt_production_economic_daily_1_report_m'   as source_table_name,
    id                                               as source_id,
    now()                                            as etl_time
from
    sdhq.ods_aloms_yhl_rpt_production_economic_daily_1_report_m_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and dim_type = '日'
;
/*氧2345_单耗*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, lowpres_steam_unconsum, elect_unconsum, highpres_steam_unconsum,
     cokegas_unconsum, bxt_unconsum, coal_unconsum, lime_unconsum, water_unconsum, natgas_unconsum,
     floc_unconsum, liqcaus_unconsum, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                         as id,
    ds                                             as dt_date,
    '氧化铝'                                       as business_format,
    a.company_no                                   as branch_factory_code,
    org.branch_factory_nm                          as branch_factory_name,
    org.company_no                                 as branch_company_code,
    org.company_nm                                 as branch_company_name,
    ifnull(energy_unit_cons_steam_low, 0) +
    ifnull(energy_unit_cons_steam, 0)              as lowpres_steam_unconsum,  -- 低压蒸汽单耗
    energy_unit_cons_electricity                   as elect_unconsum,          -- 电单耗
    energy_unit_cons_steam_high                    as highpres_steam_unconsum, -- 高压蒸汽单耗
    energy_unit_cons_coking_gas                    as cokegas_unconsum,        -- 焦化煤气单耗
    ifnull(mat_unit_cons_ore, 0) + ifnull(mat_unit_cons_ore_high, 0) +
    ifnull(mat_unit_cons_ore_low, 0)               as bxt_unconsum,            -- 矿石单耗
    energy_unit_cons_coal                          as coal_unconsum,           -- 煤炭单耗
    ifnull(mat_unit_cons_lime_comprehensive, 0) + ifnull(mat_unit_cons_lime_causticizing, 0) +
    ifnull(mat_unit_cons_lime_control, 0)          as lime_unconsum,           -- 石灰单耗
    energy_unit_cons_fresh_water                   as water_unconsum,          -- 水单耗
    energy_unit_cons_natural_gas                   as natgas_unconsum,         -- 天然气单耗
    ifnull(mat_unit_cons_flocculant_washing, 0) +
    ifnull(mat_unit_cons_flocculant_separation, 0) as floc_unconsum,           -- 絮凝剂单耗
    mat_unit_cons_liquid_alkali                    as liqcaus_unconsum,        -- 液碱(100%NaOH)单耗
    'y2345_report'                                 as source_system,
    'yhl_rpt_production_economic_daily_1_report_m' as source_table_name,
    id                                             as source_id,
    now()                                          as etl_time
from
    sdhq.ods_aloms_yhl_rpt_production_economic_daily_1_report_m_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and dim_type = '月'
;
/*矿石*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, bxt_type, bxt_consumqty, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                as id,
    ds                    as dt_date,
    '氧化铝'              as business_format,
    t.branch_factory_code,
    org.branch_factory_nm as branch_factory_name,
    org.company_no        as branch_company_code,
    org.company_nm        as branch_company_name,
    bxt_type              as bxt_type,      -- 矿石类型
    bxt_consumqty         as bxt_consumqty, -- 矿石耗用量
    source_system,
    source_table_name,
    source_id,
    now()                 as etl_time
from
    (
        select
            ds,
            'SDHQ_YHLGS_0102'       as branch_factory_code,
            '氧化铝一公司工艺系统'  as branch_factory_name,
            'y1_report'             as source_system,
            'alo1_fill_kuangshi_gx' as source_table_name,
            concat(ds, type)        as source_id,
            map(
                    '高温澳矿', xvalue1,
                    '多米尼加矿', xvalue2,
                    '几内亚矿', xvalue3,
                    '所罗门矿', xvalue4,
                    '几内亚矿(CBG)', xvalue5,
                    '牙买加矿', xvalue6
            )                       as fmap
        from
            sdhq.ods_aloms_alo1_fill_kuangshi_gx_uid
        where
            type = '日'

        union all
        select
            ds,
            company_no                                               as branch_factory_code,
            company_nm                                               as branch_factory_name,
            'y2345_report'                                           as source_system,
            'yhl_rpt_daily_report_raw_material_evaporation_report_m' as source_table_name,
            concat(ds, company_no, flg, dim_type)                    as source_id,
            map(
                    '高温澳矿', ore_outflow_high_temp_au,
                    '低温澳矿', ore_outflow_low_temp_au,
                    '多米尼加矿', ore_outflow_dominica,
                    '几内亚矿', ore_outflow_guinea,
                    '低硅几内亚矿', ore_outflow_low_silicon_guinea,
                    '所罗门矿', ore_outflow_solomon,
                    '几内亚矿(CBG)', ore_outflow_guinea_cbg,
                    '牙买加矿', ore_outflow_jamaica
            )                                                        as fmap
        from
            sdhq.ods_aloms_yhl_rpt_daily_report_raw_material_evaporation_report_m_uid
        where
            dim_type = '当日'
        ) t lateral view explode_map(fmap) tmp as bxt_type, bxt_consumqty
    left join sdhq.dim_prd_org_flatten_ufd org
on t.branch_factory_code = org.branch_factory_no
where
    bxt_consumqty <> 0
;
/*提铁*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, irex_elect_consumqty, water_type, irex_water_consumqty, source_system,
     source_table_name, source_id, etl_time)
select
    id,
    dt_date,
    business_format,
    org2.org_code                                                         as branch_factory_code,
    org3.branch_factory_nm                                                as branch_factory_name,
    org3.company_no                                                       as branch_company_code,
    org3.company_nm                                                       as branch_company_name,
    irex_elect_consumqty, -- 提铁电耗用量
    if(org2.org_code = 'SDHQ_YHLGS_TT02', '邹平台子水', '北海沾化黄河水') as water_type,
    irex_water_consumqty, -- 提铁水耗用量
    source_system,
    source_table_name,
    source_id,
    t.etl_time                                                            as etl_time
from
    (
        select
            uuid()                                           as id,
            ds                                               as dt_date,
            '氧化铝'                                         as business_format,
            case company_no
                when 'SDHQ_YHLGS_02' then 'YHL_ZH_TT_01'
                when 'SDHQ_YHLGS_03' then 'YHL_ZP_TT_01'
                when 'SDHQ_YHLGS_04' then 'YHL_BH_TT_01'
                when 'SDHQ_YHLGS_05' then 'YHL_BH_TT_02'
                end                                          as branch_factory_code,
            daily_energy_elect_kwh                           as irex_elect_consumqty, -- 提铁电耗用量
            daily_iron_idx_water_m3                          as irex_water_consumqty, -- 提铁水耗用量
            'y2345_report'                                   as source_system,
            'yhl_rpt_daily_report_iron_extraction_report_ym' as source_table_name,
            concat(ds, company_no, dim_type)                 as source_id,
            now()                                            as etl_time
        from
            sdhq.ods_aloms_yhl_rpt_daily_report_iron_extraction_report_ym_uid
        where
            dim_type = '当日'
        ) t
    left join sdhq.dim_prd_org_ufd org on t.branch_factory_code = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
;
/*铁粉*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, fe_type, fe_prod, source_system, source_table_name, source_id, etl_time)
select
    uuid()                 as id,
    dt_date,
    business_format,
    org2.org_code          as branch_factory_code,
    org3.branch_factory_nm as branch_factory_name,
    org3.company_no        as branch_company_code,
    org3.company_nm        as branch_company_name,
    fe_type, -- 铁粉类型
    fe_prod, -- 铁粉产量
    source_system,
    source_table_name,
    source_id,
    t.etl_time             as etl_time
from
    (
        select
            ds                                               as dt_date,
            '氧化铝'                                         as business_format,
            case company_no
                when 'SDHQ_YHLGS_02' then 'YHL_ZH_TT_01'
                when 'SDHQ_YHLGS_03' then 'YHL_ZP_TT_01'
                when 'SDHQ_YHLGS_04' then 'YHL_BH_TT_01'
                when 'SDHQ_YHLGS_05' then 'YHL_BH_TT_02'
                end                                          as branch_factory_code,
            map(
                    '铁粉_42%', daily_iron_prod_42,
                    '铁粉_45%', daily_iron_prod_45,
                    '铁粉_50%', daily_iron_prod_50
            )                                                as fmap, -- 铁粉产量
            'y2345_report'                                   as source_system,
            'yhl_rpt_daily_report_iron_extraction_report_ym' as source_table_name,
            concat(ds, company_no, dim_type)                 as source_id,
            now()                                            as etl_time
        from
            sdhq.ods_aloms_yhl_rpt_daily_report_iron_extraction_report_ym_uid
        where
            dim_type = '当日'
        ) t lateral view explode_map(fmap) tmp as fe_type, fe_prod
    left join sdhq.dim_prd_org_ufd org
on t.branch_factory_code = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
where
    fe_prod
  > 0
;
/*氧3水耗*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, water_type, water_consumqty, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                                  as id,
    ds                                                      as dt_date,
    '氧化铝'                                                as business_format,
    a.company_no                                            as branch_factory_code,
    org.branch_factory_nm                                   as branch_factory_name,
    org.company_no                                          as branch_company_code,
    org.company_nm                                          as branch_company_name,
    '邹平黄河水'                                            as water_type,      -- 水类型
    ifnull(fresh_water_evaporation_flow1_end, 0) -
    ifnull(fresh_water_evaporation_flow1_begin, 0)          as water_consumqty, -- 氧化铝水耗用量
    'y2345_report'                                          as source_system,
    'yhl_fill_daily_report_raw_material_evaporation_report' as source_table_name,
    id                                                      as source_id,
    now()                                                   as etl_time
FROM
    sdhq.ods_aloms_yhl_fill_daily_report_raw_material_evaporation_report_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and ifnull(fresh_water_evaporation_flow1_end, 0) -
      ifnull(fresh_water_evaporation_flow1_begin, 0) > 0
  and left(a.company_no, 13) = 'SDHQ_YHLGS_03' /*氧化铝三公司*/
union all
select
    uuid()                                                  as id,
    ds                                                      as dt_date,
    '氧化铝'                                                as business_format,
    a.company_no                                            as branch_factory_code,
    org.branch_factory_nm                                   as branch_factory_name,
    org.company_no                                          as branch_company_code,
    org.company_nm                                          as branch_company_name,
    '邹平台子水'                                            as water_type,      -- 水类型
    ifnull(fresh_water_evaporation_flow2_end, 0) -
    ifnull(fresh_water_evaporation_flow2_begin, 0)          as water_consumqty, -- 氧化铝水耗用量
    'y2345_report'                                          as source_system,
    'yhl_fill_daily_report_raw_material_evaporation_report' as source_table_name,
    id                                                      as source_id,
    now()                                                   as etl_time
FROM
    sdhq.ods_aloms_yhl_fill_daily_report_raw_material_evaporation_report_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and ifnull(fresh_water_evaporation_flow2_end, 0) -
      ifnull(fresh_water_evaporation_flow2_begin, 0) > 0
  and left(a.company_no, 13) = 'SDHQ_YHLGS_03' /*氧化铝三公司*/
;
/*氧2345：煤炭发热值*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, coal_heatvalue, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                         as id,
    ds                                             as dt_date,
    '氧化铝'                                       as business_format,
    a.company_no                                   as branch_factory_code,
    org.branch_factory_nm                          as branch_factory_name,
    org.company_no                                 as branch_company_code,
    org.company_nm                                 as branch_company_name,
    coal_calorific_value_furnace                   as coal_heatvalue, -- 煤炭发热值
    'y2345_report'                                 as source_system,
    'yhl_rpt_production_economic_daily_2_report_m' as source_table_name,
    id                                             as source_id,
    now()                                          as etl_time
from
    sdhq.ods_aloms_yhl_rpt_production_economic_daily_2_report_m_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and dim_type = '日'
;
/*成品氧化钠含量*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, ao_na2o_content, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                             as id,
    ds                                                 as dt_date,
    '氧化铝'                                           as business_format,
    a.company_no                                       as branch_factory_code,
    org.branch_factory_nm                              as branch_factory_name,
    org.company_no                                     as branch_company_code,
    org.company_nm                                     as branch_company_name,
    (
        ifnull(bagged_night_na2o, 0) +
        ifnull(bagged_morning_na2o, 0) +
        ifnull(bagged_noon_na2o, 0) +
        ifnull(bulk_night_na2o, 0) +
        ifnull(bulk_morning_na2o, 0) +
        ifnull(bulk_noon_na2o, 0) +
        ifnull(bagged_night_na2o_2, 0) +
        ifnull(bagged_morning_na2o_2, 0) +
        ifnull(bagged_noon_na2o_2, 0) +
        ifnull(bulk_night_ext_na2o, 0) +
        ifnull(bulk_morning_ext_na2o, 0) +
        ifnull(bulk_noon_ext_na2o, 0)
        ) / (IF(bagged_night_na2o IS NOT NULL, 1, 0) +
             IF(bagged_morning_na2o IS NOT NULL, 1, 0) +
             IF(bagged_noon_na2o IS NOT NULL, 1, 0) +
             IF(bulk_night_na2o IS NOT NULL, 1, 0) +
             IF(bulk_morning_na2o IS NOT NULL, 1, 0) +
             IF(bulk_noon_na2o IS NOT NULL, 1, 0) +
             IF(bagged_night_na2o_2 IS NOT NULL, 1, 0) +
             IF(bagged_morning_na2o_2 IS NOT NULL, 1, 0) +
             IF(bagged_noon_na2o_2 IS NOT NULL, 1, 0) +
             IF(bulk_night_ext_na2o IS NOT NULL, 1, 0) +
             IF(bulk_morning_ext_na2o IS NOT NULL, 1, 0) +
             IF(bulk_noon_ext_na2o IS NOT NULL, 1, 0)) as ao_na2o_content, -- 成品氧化纳含量
    'y2345_report'                                     as source_system,
    'yhl_rpt_production_economic_daily_3_report_m'     as source_table_name,
    id                                                 as source_id,
    now()                                              as etl_time
from
    sdhq.ods_aloms_yhl_rpt_production_economic_daily_3_report_m_uid a
    left join sdhq.dim_prd_org_flatten_ufd org on a.company_no = org.branch_factory_no
where
      flg = '1'
  and dim_type = '日'
;
/*折旧费*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, deprec_exp, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                    as id,
    dt2.dt_date                               as dt_date,
    '氧化铝'                                  as business_format,
    a.branch_no                               as branch_factory_code,
    org.branch_factory_nm                     as branch_factory_name,
    org.company_no                            as branch_company_code,
    org.company_nm                            as branch_company_name,
    deprec_exp / days                         as deprec_exp, -- 折旧费
    'fryw'                                    as source_system,
    'dw_centor_report.yhl_fill_ao_deprec_exp' as source_table_name,
    concat(mth, a.company_no, branch_no)      as source_id,
    now()                                     as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_deprec_exp_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_date dt2 on dt.prod_ym = dt2.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no

union all
select
    uuid()                                      as id,
    dt2.dt_date                                 as dt_date,
    '氧化铝'                                    as business_format,
    org3.branch_factory_no                      as branch_company_code,
    org3.branch_factory_nm                      as branch_factory_name,
    org3.company_no                             as branch_company_code,
    org3.company_nm                             as branch_company_name,
    irex_deprec_exp / days                      as deprec_exp, -- 折旧费
    'fryw'                                      as source_system,
    'dw_centor_report.yhl_fill_irex_deprec_exp' as source_table_name,
    concat(mth, legal_entity_no)                as source_id,
    now()                                       as etl_time
from
    sdhq.ods_fryw_yhl_fill_irex_deprec_exp_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_date dt2 on dt.prod_ym = dt2.prod_ym
    left join sdhq.dim_prd_org_ufd org on a.legal_entity_no = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
;
/*人工成本*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, labor_cost, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                    as id,
    dt2.dt_date                               as dt_date,
    '氧化铝'                                  as business_format,
    a.branch_no                               as branch_factory_code,
    org.branch_factory_nm                     as branch_factory_name,
    org.company_no                            as branch_company_code,
    org.company_nm                            as branch_company_name,
    ao_labor_cost / days                      as labor_cost, -- 人工成本
    'fryw'                                    as source_system,
    'dw_centor_report.yhl_fill_ao_labor_cost' as source_table_name,
    concat(mth, a.company_no, branch_no)      as source_id,
    now()                                     as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_labor_cost_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_date dt2 on dt.prod_ym = dt2.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no

union all
select
    uuid()                                      as id,
    dt2.dt_date                                 as dt_date,
    '氧化铝'                                    as business_format,
    org3.branch_factory_no                      as branch_company_code,
    org3.branch_factory_nm                      as branch_factory_name,
    org3.company_no                             as branch_company_code,
    org3.company_nm                             as branch_company_name,
    irex_labor_cost / days                      as labor_cost, -- 人工成本
    'fryw'                                      as source_system,
    'dw_centor_report.yhl_fill_irex_labor_cost' as source_table_name,
    concat(mth, legal_entity_no)                as source_id,
    now()                                       as etl_time
from
    sdhq.ods_fryw_yhl_fill_irex_labor_cost_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_date dt2 on dt.prod_ym = dt2.prod_ym
    left join sdhq.dim_prd_org_ufd org on a.legal_entity_no = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
;
/*环保税*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, envir_prot_tax_amt, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                        as id,
    dt.last_day                                   as dt_date,
    '氧化铝'                                      as business_format,
    a.branch_no                                   as branch_factory_code,
    org.branch_factory_nm                         as branch_factory_name,
    org.company_no                                as branch_company_code,
    org.company_nm                                as branch_company_name,
    environmental_tax                             as envir_prot_tax_amt, -- 环保税
    'fryw'                                        as source_system,
    'dw_centor_report.yhl_fill_environmental_tax' as source_table_name,
    concat(mth, a.company_no, branch_no)          as source_id,
    now()                                         as etl_time
from
    sdhq.ods_fryw_yhl_fill_environmental_tax_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
;

/*铁粉计划产量*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, fe_plan_prod, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                     as id,
    dt.min_date                                as dt_date,
    '氧化铝'                                   as business_format,
    org3.branch_factory_no                     as branch_company_code,
    org3.branch_factory_nm                     as branch_factory_name,
    org3.company_no                            as branch_company_code,
    org3.company_nm                            as branch_company_name,
    irex_plan_prod                             as fe_plan_prod, -- 铁粉计划产量
    'fryw'                                     as source_system,
    'dw_centor_report.yhl_fill_irex_plan_prod' as source_table_name,
    concat(mth, legal_entity_no)               as source_id,
    now()                                      as etl_time
from
    sdhq.ods_fryw_yhl_fill_irex_plan_prod_ufd a
    left join (
        /*计算每月第一天*/
        select prod_ym, min(dt_date) as min_date from sdhq.dim_prd_date group by prod_ym
        ) dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_ufd org on a.legal_entity_no = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
;
/*技改类外委费用*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, non_prod_techno_retro_outsource_exp, prod_techno_retro_outsource_exp,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                 as id,
    dt.last_day                            as dt_date,
    '氧化铝'                               as business_format,
    a.branch_no                            as branch_factory_code,
    org.branch_factory_nm                  as branch_factory_name,
    org.company_no                         as branch_company_code,
    org.company_nm                         as branch_company_name,
    if(use_type = '非生产', outsrc_exp, 0) as non_prod_techno_retro_outsource_exp, -- 非生产技改类外委费用
    if(use_type = '生产', outsrc_exp, 0)   as prod_techno_retro_outsource_exp,     -- 生产技改类外委费用
    'fryw'                                 as source_system,
    'dw_centor_report.yhl_fill_outsrc_exp' as source_table_name,
    concat(a.mth, branch_no)               as source_id,
    now()                                  as etl_time
from
    sdhq.ods_fryw_yhl_fill_outsrc_exp_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
where
    use_type is not null
;
/*共享费用、技改费用、检修费用(互用料折算)、加工费*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, common_exp, techno_retro_exp, maint_exp, process_exp, source_system,
     source_table_name, source_id, etl_time)
select
    uuid()                                  as id,
    dt.last_day                             as dt_date,
    '氧化铝'                                as business_format,
    a.branch_no                             as branch_factory_code,
    org.branch_factory_nm                   as branch_factory_name,
    org.company_no                          as branch_company_code,
    org.company_nm                          as branch_company_name,
    share_exp                               as common_exp,       -- 共享费用
    techno_exp                              as techno_retro_exp, -- 技改费用
    maint_exp                               as maint_exp,        -- 检修费用(互用料折算)
    process_exp                             as process_exp,      -- 加工费
    'fryw'                                  as source_system,
    'dw_centor_report.yhl_fill_process_exp' as source_table_name,
    concat(a.mth, branch_no)                as source_id,
    now()                                   as etl_time
from
    sdhq.ods_fryw_yhl_fill_process_exp_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
;
/*氧化铝计划产量*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, ao_plan_prod, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                   as id,
    dt.first_day                             as dt_date,
    '氧化铝'                                 as business_format,
    branch_no                                as branch_company_code,
    org.branch_factory_nm                    as branch_factory_name,
    org.company_no                           as branch_company_code,
    org.company_nm                           as branch_company_name,
    ao_plan_prod                             as ao_plan_prod, -- 氧化铝计划产量
    'fryw'                                   as source_system,
    'dw_centor_report.yhl_fill_ao_plan_prod' as source_table_name,
    concat(mth, branch_no)                   as source_id,
    now()                                    as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_plan_prod_ufd a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
;
/*煤炭折算单价、煤炭折算耗用量*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, coal_convert_unprice, coal_convert_consumqty, source_system,
     source_table_name, source_id, etl_time)
select
    uuid()                                   as id,
    dt.first_day                             as dt_date,
    '氧化铝'                                 as business_format,
    branch_no                                as branch_company_code,
    org.branch_factory_nm                    as branch_factory_name,
    org.company_no                           as branch_company_code,
    org.company_nm                           as branch_company_name,
    coal_eq_price                            as coal_convert_unprice,   -- 煤炭折算单价
    coal_eq_cons                             as coal_convert_consumqty, -- 煤炭折算耗用量
    'fryw'                                   as source_system,
    'dw_centor_report.yhl_fill_coal_eq_cons' as source_table_name,
    concat(mth, branch_no)                   as source_id,
    now()                                    as etl_time
from
    sdhq.ods_fryw_yhl_fill_coal_eq_cons_uid a
    left join sdhq.v_prd_ym_date dt on a.mth = dt.prod_ym
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
;
/*提铁检修费*/
insert into
    sdhq.dwd_prd_ao_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, branch_company_code,
     branch_company_name, irex_maint_exp, source_system,
     source_table_name, source_id, etl_time)
select
    uuid()                                               as id,
    whouse_disp_date                                     as dt_date,
    '氧化铝'                                             as business_format,
    org3.branch_factory_no                               as branch_company_code,
    org3.branch_factory_nm                               as branch_factory_name,
    org3.company_no                                      as branch_company_code,
    org3.company_nm                                      as branch_company_name,
    whouse_disp_amt                                      as irex_maint_exp, -- 提铁检修费
    'fryw'                                               as source_system,
    'dw_centor_report.yhl_fill_irex_whouse_disp_summary' as source_table_name,
    concat(whouse_disp_date, dept_no)                    as source_id,
    now()                                                as etl_time
from
    sdhq.ods_fryw_yhl_fill_irex_whouse_disp_summary_ufd a
    left join sdhq.dim_prd_org_ufd org on a.dept_no = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
;