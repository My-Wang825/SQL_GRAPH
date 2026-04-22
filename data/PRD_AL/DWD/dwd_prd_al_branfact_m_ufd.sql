
/*
 -- 描述：电解铝分厂月指标
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：1、人工成本 、国网电量调整耗用金额 2、液态铝计划产量 3、液态铝额定产能 4、单耗_月
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
truncate table sdhq.dwd_prd_al_branfact_m_ufd;

/*人工成本*/
insert into
    sdhq.dwd_prd_al_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_name, branch_factory_code,
     labor_cost, stategrid_elect_adjust_consum_amt, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                as id,
    mth                                   as prod_ym,
    vdt.last_day                          as prod_ym_last_day,
    '电解铝'                              as business_format,
    org.branch_factory_nm                 as branch_factory_name, -- 分厂名称
    branch_no                             as branch_factory_code, -- 分厂编码
    labor_cost                            as labor_cost,          -- 人工成本
    sgcc_adjust_consum_amount stategrid_elect_adjust_consum_amt, -- 国网电量调整耗用金额
    'fryw'                                as source_system,       -- 来源系统
    'dw_centor_report.ly_fill_labor_cost' as source_table_name,   -- 来源表名
    concat(mth, branch_no)                as source_id,           -- 来源ID
    now()                                 as etl_time
from
    sdhq.ods_fryw_ly_fill_labor_cost_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*液态铝计划产量*/
insert into
    sdhq.dwd_prd_al_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_name, branch_factory_code,
     series_code, series_name, liq_alum_plan_prod, source_system, source_table_name, source_id, etl_time)
select
    uuid()                               as id,
    mth                                  as prod_ym,
    vdt.last_day                         as prod_ym_last_day,
    '电解铝'                             as business_format,
    org.branch_factory_nm                as branch_factory_name, -- 分厂名称
    branch_no                            as branch_factory_code, -- 分厂编码
    series_no                            as series_code,         -- 系列编码
    series_nm                            as series_name,         -- 系列名称
    liq_alum_plan_prod                   as liq_alum_plan_prod,  -- 液态铝计划产量
    'fryw'                               as source_system,       -- 来源系统
    'dw_centor_report.ly_fill_plan_prod' as source_table_name,   -- 来源表名
    concat(mth, branch_no, series_nm)    as source_id,           -- 来源ID
    now()                                as etl_time
from
    sdhq.ods_fryw_ly_fill_plan_prod_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*液态铝额定产能*/
insert into
    sdhq.dwd_prd_al_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_code, branch_factory_name,
     series_code, series_name, liq_alum_prod_capacity, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                as id,
    mth                                   as prod_ym,
    vdt.last_day                          as prod_ym_last_day,
    '电解铝'                              as business_format,
    branch_no                             as branch_factory_code,    -- 分厂编码
    org.branch_factory_nm                 as branch_factory_name,    -- 分厂名称
    series_no                             as series_code,            -- 系列编码
    series_nm                             as series_name,            -- 系列名称
    liq_alum_rated_prod                   as liq_alum_prod_capacity, -- 液态铝额定产能
    'fryw'                                as source_system,          -- 来源系统
    'dw_centor_report.ly_fill_rated_prod' as source_table_name,      -- 来源表名
    concat(mth, branch_no, series_no)     as source_id,              -- 来源ID
    now()                                 as etl_time
from
    sdhq.ods_fryw_ly_fill_rated_prod_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*单耗*/
insert into
    sdhq.dwd_prd_al_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_name, branch_factory_code,
     ao_unconsum_m, anode_carb_unconsum_m, alf3_unconsum_m, additive_unconsum_m, source_system,
     source_table_name, source_id, etl_time)
select
    uuid()                                    as id,
    dt.prod_ym                                as prod_ym,
    vdt.last_day                              as prod_ym_last_day,
    '电解铝'                                  as business_format,
    org.branch_factory_nm                     as branch_factory_name,   -- 分厂名称
    al_factory_no                             as branch_factory_code,   -- 分厂编码
    Prd_AL_Ao_Unconsum_Fty_Qty_M              as ao_unconsum_m,         -- 氧化铝单耗_月
    Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M    as anode_carb_unconsum_m, -- 阳极炭块单耗_月
    Prd_AL_Alf3_Unconsum_Fty_Qty_M            as alf3_unconsum_m,       -- 氟化铝单耗_月
    Prd_AL_Additive_Unconsum_Fty_Qty_M        as additive_unconsum_m,   -- 添加剂单耗_月
    'aloudatacan'                             as source_system,         -- 来源系统
    'sdhq_prd_al_branch_rpt_factory_econ_al1' as source_table_name,     -- 来源表名
    concat(metric_time, al_factory_no)        as source_id,             -- 来源ID
    now()                                     as etl_time
from
    (
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al1
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al2_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al2
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al3wq_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al3wq
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al3_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al3zp
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al4
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_M,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_M,
            Prd_AL_Alf3_Unconsum_Fty_Qty_M,
            Prd_AL_Additive_Unconsum_Fty_Qty_M
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al5
        ) a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
    left join sdhq.dim_prd_date dt on a.metric_time = dt.dt_date
    left join sdhq.v_prd_ym_date vdt on dt.prod_ym = vdt.prod_ym
where
    day(a.metric_time) = 24
;
