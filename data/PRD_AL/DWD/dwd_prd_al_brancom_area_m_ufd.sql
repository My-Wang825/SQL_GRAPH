/*
 -- 描述：电解铝分公司区域月指标
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：1、共享费用 2、折旧费 3、环保税 4、大修渣处置费 5、液态铝产量_月、铝锭产量_月、铝母线产量_月 6、技改类外委费用
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
truncate table sdhq.dwd_prd_al_brancom_area_m_ufd;

/*共享费用*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name,
     share_exp, source_system, source_table_name, source_id, etl_time)
select
    uuid()                               as id,
    mth                                  as prod_ym,
    '电解铝'                             as business_format,
    company_area_no                      as branch_company_area_code, -- 分公司区域编码
    company_area_nm                      as branch_company_area_name, -- 分公司区域名称
    share_exp                            as share_exp,                -- 共享费用
    'fryw'                               as source_system,            -- 来源系统
    'dw_centor_report.ly_fill_share_exp' as source_table_name,        -- 来源表名
    concat(mth, a.company_no)            as source_id,                -- 来源ID
    now()                                as etl_time
from
    sdhq.ods_fryw_ly_fill_share_exp_ufd a
where
    company_no = 'SDHQ_LYGS_03'
;
/*折旧费*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name, deprec_exp,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                as id,
    mth                                   as prod_ym,
    '电解铝'                              as business_format,
    company_area_no                       as branch_company_area_code, -- 分公司区域编码
    company_area_nm                       as branch_company_area_name, -- 分公司区域名称
    deprec_exp,                                                        -- 折旧费
    'fryw'                                as source_system,            -- 来源系统
    'dw_centor_report.ly_fill_deprec_exp' as source_table_name,        -- 来源表名
    concat(mth, a.company_area_no)        as source_id,                -- 来源ID
    now()                                 as etl_time
from
    sdhq.ods_fryw_ly_fill_deprec_exp_ufd a
;
/*环保税*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name,
     envir_prot_tax_amt, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                       as id,
    mth                                          as prod_ym,
    '电解铝'                                     as business_format,
    company_area_no                              as branch_company_area_code, -- 分公司区域编码
    company_area_nm                              as branch_company_area_name, -- 分公司区域名称
    environmental_tax                            as envir_prot_tax_amt,       -- 环保税
    'fryw'                                       as source_system,            -- 来源系统
    'dw_centor_report.ly_fill_environmental_tax' as source_table_name,        -- 来源表名
    concat(mth, a.company_area_no)               as source_id,                -- 来源ID
    now()                                        as etl_time
from
    sdhq.ods_fryw_ly_fill_environmental_tax_ufd a
where
    company_no = 'SDHQ_LYGS_03'
;
/*大修渣处置费*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name,
     overhaul_resi_proc_exp, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                          as id,
    mth                                             as prod_ym,
    '电解铝'                                        as business_format,
    company_area_no                                 as branch_company_code,    -- 分公司编码
    company_area_nm                                 as branch_company_name,    -- 分公司名称
    overhaul_residue_exp                            as overhaul_resi_proc_exp, -- 大修渣处置费
    'fryw'                                          as source_system,          -- 来源系统
    'dw_centor_report.ly_fill_overhaul_residue_exp' as source_table_name,      -- 来源表名
    concat(mth, a.company_area_no)                  as source_id,              -- 来源ID
    now()                                           as etl_time
from
    sdhq.ods_fryw_ly_fill_overhaul_residue_exp_ufd a
where
    a.company_no = 'SDHQ_LYGS_03'
;
/*液态铝产量_月、铝锭产量_月、铝母线产量_月*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name,
     liq_alum_prod_m, alumingot_prod_m, alumbusbar_prod_m, source_system, source_table_name,
     source_id, etl_time)
select
    uuid()                              as id,
    t.prod_ym                           as prod_ym,
    '电解铝'                            as business_format,
    t.branch_company_area_no            as branch_company_area_code, -- 分公司区域编码
    org.company_area_nm                 as branch_company_area_name, -- 分公司区域名称
    ifnull(t.liq_alum_cons, 0) + ifnull(t3.liq_alum_econ, 0) + ifnull(t2.liq_alum_item_val_1, 0) -
    ifnull(t2.liq_alum_item_val_0, 0) -
    ifnull(t2.liq_alum_item_val_3, 0)   as liq_alum_prod_m,          -- 液态铝产量_月
    ifnull(t1.alumingot_qty, 0) + ifnull(t2.alumingot_item_val_1, 0) -
    ifnull(t2.alumingot_item_val_0, 0)  as alumingot_prod_m,         -- 铝锭产量_月
    ifnull(t1.alumbusbar_qty, 0) + ifnull(t2.alumbusbar_item_val_1, 0) -
    ifnull(t2.alumbusbar_item_val_0, 0) as alumbusbar_prod_m,        -- 铝母线产量_月
    'ipms'                              as source_system,            -- 来源系统
    ''                                  as source_table_name,        -- 来源表名
    ''                                  as source_id,                -- 来源ID
    now()                               as etl_time
from
    (
        /*外销铝水 + 送新材料  + 委外加工*/
        select
            dt.prod_ym,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end as branch_company_area_no,
            SUM(IFNULL(export_water, 0) + IFNULL(xcl_qlhl, 0) +
                IFNULL(weiwai, 0)) / 1000                          AS liq_alum_cons
        from
            sdhq.ods_ipms_ly_it_prod_sales_volume_energy_consum_ufd a
            left join sdhq.dim_prd_date dt on a.data_dt = dt.dt_date
        where
              company_no = 'SDHQ_LYGS_03'
          and a.data_dt >= '2025-11-25'
        group by
            dt.prod_ym,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end
        ) t
    left join (
        /**/
        select
            dt.prod_ym,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end as branch_company_area_no,
            sum(alumingot_whouse_rece_qty)                         as alumingot_qty,
            sum(alumbusbar_whouse_rece_qty)                        as alumbusbar_qty
        from
            sdhq.ods_ipms_ly_fill_prod_sales_volume_energy_consum_uid a
            left join sdhq.dim_prd_date dt on a.dt = dt.dt_date
        where
              flg = '1'
          and a.dt >= '2025-11-25'
          and branch_company_no = 'SDHQ_LYGS_03'
        group by
            dt.prod_ym,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end
        ) t1 on t.prod_ym = t1.prod_ym and t.branch_company_area_no = t1.branch_company_area_no
    left join (
        /*取金属平衡表的期初铸部存铝、期末盘存*/
        select
            prod_mth                                                            as prod_ym,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309'
                    then 'SDHQ_LYGS_WQQY_01' end                                as branch_company_area_no,
            SUM(if((a.item_type = '1' AND a.item_name LIKE '%冷料%'), a.item_val,
                   0))                                                          AS liq_alum_item_val_0,
            SUM(if((a.item_type = '4' AND a.item_name LIKE '%冷%'), a.item_val,
                   0))                                                          AS liq_alum_item_val_1,
            SUM(if((a.item_type = '3' AND a.item_name LIKE '%清槽%'), a.item_val,
                   0))                                                          AS liq_alum_item_val_3,
            sum(if((item_type = '1' AND item_name LIKE '%铝锭%'), item_val, 0)) AS alumingot_item_val_0,  -- 期初铸部存铝小计
            sum(if((item_type = '4' AND item_name LIKE '%铝锭%'), item_val, 0)) AS alumingot_item_val_1,  -- 期末铸部存铝小计
            sum(if((item_type = '1' AND item_name LIKE '%铝母线%'), item_val,
                   0))                                                          AS alumbusbar_item_val_0, -- 期初铸部存铝小计
            sum(if((item_type = '4' AND item_name LIKE '%铝母线%'), item_val,
                   0))                                                          AS alumbusbar_item_val_1  -- 期末铸部存铝小计
        from
            sdhq.ods_ipms_ly_fill_metal_balance_uid a
        where
              flg = '1'
          and a.branch_company_no = 'SDHQ_LYGS_03'
        group by
            a.prod_mth,
            case a.factory_no
                when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
                when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end
        ) t2 on t.prod_ym = t2.prod_ym and t.branch_company_area_no = t2.branch_company_area_no
    left join (
        select
            dt.prod_ym,
            org.company_area_no               as branch_company_area_no,
            SUM(IFNULL(alum_pour_qty, 0) - IFNULL(shutdown_alum, 0) - IFNULL(electro_borrowin, 0) +
                IFNULL(electro_borrowout, 0)) as liq_alum_econ -- 经济指标合计
        from
            sdhq.ods_ipms_ly_fill_other_econ_index_uid a
            left join sdhq.dim_prd_date dt on a.dt = dt.dt_date
            left join sdhq.dim_prd_org_flatten_ufd org on a.factory_no = org.branch_factory_no
        where
              flg = '1'
          and branch_company_no = 'SDHQ_LYGS_03'
        group by
            dt.prod_ym,
            org.company_area_no
        ) t3 on t.prod_ym = t3.prod_ym and t.branch_company_area_no = t3.branch_company_area_no
    left join (
        select distinct
            company_area_no,
            company_area_nm
        from
            sdhq.dim_prd_org_flatten_ufd
        where
            module_nm = '铝业公司'
        ) org on t.branch_company_area_no = org.company_area_no
;
/*技改类外委费用*/
insert into
    sdhq.dwd_prd_al_brancom_area_m_ufd
    (id, prod_ym, business_format, branch_company_area_code, branch_company_area_name,
     prod_techno_retro_outsource_exp, non_prod_techno_retro_outsource_exp, source_system,
     source_table_name, source_id, etl_time)
select
    uuid()                                 as id,
    mth                                    as prod_ym,
    '电解铝'                               as business_format,
    a.company_area_no                      as branch_company_area_code,            -- 分公司编码
    org.company_area_nm                    as branch_company_area_name,            -- 分公司名称
    if(use_type = '生产', outsrc_exp, 0)   as prod_techno_retro_outsource_exp,     -- 生产技改类外委费用
    if(use_type = '非生产', outsrc_exp, 0) as non_prod_techno_retro_outsource_exp, -- 非生产技改类外委费用
    'fryw'                                 as source_system,                       -- 来源系统
    'dw_centor_report.ly_fill_outsrc_exp'  as source_table_name,                   -- 来源表名
    concat(mth, a.company_area_no)         as source_id,                           -- 来源ID
    now()                                  as etl_time
from
    sdhq.ods_fryw_ly_fill_outsrc_exp_ufd a
    left join (
        select distinct
            company_area_no,
            company_area_nm
        from
            sdhq.dim_prd_org_flatten_ufd
        ) org on a.company_area_no = org.company_area_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
where
    a.company_no = 'SDHQ_LYGS_03'
;