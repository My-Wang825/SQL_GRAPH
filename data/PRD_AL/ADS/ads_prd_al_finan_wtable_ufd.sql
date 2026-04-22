
/*
 -- 描述：电解铝分公司财务指标宽表
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：分厂、分公司、分公司区域按产能分摊计算
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
/*定时封版历史数据，无需清空表*/
-- truncate table sdhq.ads_prd_al_finan_wtable_ufd;

/**/
insert into
    sdhq.ads_prd_al_finan_wtable_ufd
select
    dt.dt_date                                                                     as dt_date,
    dt.prod_ym                                                                     as prod_ym,
    dt.branch_factory_code                                                         as branch_factory_code,
    dt.branch_factory_name                                                         as branch_factory_name,
    dt.branch_company_area_code                                                    as branch_company_area_code,
    dt.branch_company_area_name                                                    as branch_company_area_name,
    dt.branch_company_code                                                         as branch_company_code,
    dt.branch_company_name                                                         as branch_company_name,
    dt.company_code                                                                as company_code,
    dt.company_name                                                                as company_name,
    dt.company_area_code                                                           as company_area_code,
    dt.company_area_name                                                           as company_area_name,
    dt.business_format                                                             as business_format,
    capacity.liq_alum_prod_capacity_fc                                             as liq_alum_prod_capacity_fc,
    capacity.liq_alum_prod_capacity_fgs                                            as liq_alum_prod_capacity_fgs,
    capacity.liq_alum_prod_capacity_fgsqy                                          as liq_alum_prod_capacity_fgsqy,
    capacity.liq_alum_prod_capacity_zgs                                            as liq_alum_prod_capacity_zgs,
    capacity.liq_alum_prod_capacity_zgsqy                                          as liq_alum_prod_capacity_zgsqy,
    scrap_mat_byprod_nontax_sales_amt_fgs,                                                                                    -- 废旧物资及副产品不含税销售额_分公司
    scrap_mat_byprod_nontax_sales_amt_fgsqy,                                                                                  -- 废旧物资及副产品不含税销售额_分公司区域
    sum(labor_cost)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as labor_cost,                             -- 人工成本
    elect_sales_unprice,                                                                                                      -- 电单价_毛利使用
    ao_sales_unprice,                                                                                                         -- 氧化铝单价_毛利使用
    overhaul_resi_proc_exp_fgs,                                                                                               -- 大修渣处置费_分公司
    overhaul_resi_proc_exp_fgsqy,                                                                                             -- 大修渣处置费_分公司区域
    deprec_exp_fgsqy,                                                                                                         -- 折旧费用_分公司区域
    prod_techno_retro_outsource_exp_fgs,                                                                                      -- 生产技改外委费用_分公司
    prod_techno_retro_outsource_exp_fgsqy,                                                                                    -- 生产技改外委费用_分公司区域
    sum(repair_exp_fc)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as repair_exp_fc,                          -- 日常维修费用
    repair_exp_fgs,
    repair_exp_fgsqy,
    sum(overhaul_exp_fc)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as overhaul_exp_fc,                        -- 大修费用_分厂
    overhaul_exp_fgs,                                                                                                         -- 大修费用_分公司
    overhaul_exp_fgsqy,                                                                                                       -- 大修费用_分公司区域
    sum(techno_retro_exp_fc)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as techno_retro_exp_fc,
    techno_retro_exp_fgs,
    techno_retro_exp_fgsqy,
    sum(vehicle_oil_usage_exp_fc)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as vehicle_oil_usage_exp_fc,
    vehicle_oil_usage_exp_fgs,
    vehicle_oil_usage_exp_fgsqy,
    dine_exp_fgs,
    dine_exp_fgsqy,
    sum(ncc_other_exp_fc)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as ncc_other_exp_fc,
    ncc_other_exp_fgs,
    ncc_other_exp_fgsqy,
    share_exp_fgs,                                                                                                            -- 共享费用_分公司
    share_exp_fgsqy,                                                                                                          -- 共享费用_分公司区域
    envir_prot_tax_amt_fgs,                                                                                                   -- 环保税_分公司
    envir_prot_tax_amt_fgsqy,                                                                                                 -- 环保税_分公司区域
    non_prod_techno_retro_outsource_exp_fgs,                                                                                  -- 非生产技改外委费用_分公司
    non_prod_techno_retro_outsource_exp_fgsqy,                                                                                -- 非生产技改外委费用_分公司区域
    sum(liq_alum_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as liq_alum_prod,                          -- 液态铝产量
    alumingot_prod_fgs,                                                                                                       -- 铝锭产量_分公司
    alumingot_prod_fgsqy,                                                                                                     -- 铝锭产量_分公司区域
    alumbusbar_prod_fgs,                                                                                                      -- 铝母线产量_分公司
    alumbusbar_prod_fgsqy,                                                                                                    -- 铝母线产量_分公司区域
    sum(liq_alum_997_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as liq_alum_997_prod,
    liq_alum_prod_m_fgs,                                                                                                      -- 液态铝产量_月_分公司
    liq_alum_prod_m_fgsqy,                                                                                                    -- 液态铝产量_月_分公司区域
    alumingot_prod_m_fgs,                                                                                                     -- 铝锭产量_月_分公司
    alumingot_prod_m_fgsqy,                                                                                                   -- 铝锭产量_月_分公司区域
    alumbusbar_prod_m_fgs,                                                                                                    -- 铝母线产量_月_分公司
    alumbusbar_prod_m_fgsqy,                                                                                                  -- 铝母线产量_月_分公司区域
    alumbusbar_sales_unprice,                                                                                                 --  铝母线销售单价
    alumingot_sales_unprice,                                                                                                  --  铝锭销售单价
    liq_alum_sales_unprice,                                                                                                   --  液态铝销售单价
    ao_pur_unprice,
    sum(ao_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as ao_consumqty_tzq,
    ifnull(anode_carb_correct_unprice, anode_carb_unprice)                         as anode_carb_unprice,                     -- 阳极炭块单价
    sum(anode_carb_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as anode_carb_consumqty_tzq,
    ifnull(alf3_correct_unprice, alf3_unprice)                                     as alf3_unprice,                           -- 氟化铝单价
    sum(alf3_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as alf3_consumqty_tzq,
    ifnull(cryo_correct_unprice, cryo_unprice)                                     as cryo_unprice,                           -- 冰晶石单价
    sum(cryo_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as cryo_consumqty_tzq,
    ifnull(electro_correct_unprice, electro_unprice)                               as electro_unprice,                        -- 电解质块（粉）单价
    sum(electro_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as electro_consumqty_tzq,
    ifnull(mgf2_correct_unprice, mgf2_unprice)                                     as mgf2_unprice,                           -- 氟化镁单价
    sum(mgf2_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as mgf2_consumqty_tzq,
    ifnull(caf2_correct_unprice, caf2_unprice)                                     as caf2_unprice,                           -- 氟化钙单价
    sum(caf2_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as caf2_consumqty_tzq,
    ifnull(pri.soda_ash_correct_unprice, soda_ash_unprice)                         as soda_ash_unprice,                       -- 纯碱单价
    sum(soda_ash_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as soda_ash_consumqty_tzq,
    ifnull(li2co3_correct_unprice, li2co3_unprice)                                 as li2co3_unprice,                         -- 碳酸锂单价
    sum(li2co3_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as li2co3_consumqty,                       -- 碳酸锂耗用量
    sum(anode_wksp_soda_ash_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as anode_wksp_soda_ash_consumqty,          -- 阳极车间纯碱耗用量
    anode_wksp_soda_ash_consumqty_fgs,                                                                                        -- 阳极车间纯碱耗用量_分公司
    anode_wksp_soda_ash_consumqty_fgsqy,                                                                                      -- 阳极车间纯碱耗用量_分公司区域
    sum(limestone_powder_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as limestone_powder_consumqty,             -- 石灰石粉耗用量
    sum(limestone_powder_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as limestone_powder_consum_amt,            -- 石灰石粉耗用金额
    desulf_wateruse_unprice,
    desulf_wateruse_consumqty_fgs,                                                                                            -- 脱硫用水耗用量_分公司
    desulf_wateruse_consumqty_fgsqy,                                                                                          -- 脱硫用水耗用量_分公司区域
    sum(natgas_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as natgas_consumqty_tzq,                   -- 天然气耗用量
    natgas_consumqty_tzq_fgs,                                                                                                 -- 天然气耗用量_分公司
    natgas_consumqty_tzq_fgsqy,                                                                                               -- 天然气耗用量_分公司区域
    ifnull(pri.natgas_correct_unprice, natgas_unprice)                             as natgas_unprice,                         -- 天然气单价
    sum(other_aux_mat_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as other_aux_mat_consumqty,                -- 其他辅料耗用量,
    other_aux_mat_consumqty_fgs,                                                                                              -- 其他辅料耗用量_分公司
    other_aux_mat_consumqty_fgsqy,                                                                                            -- 其他辅料耗用量_分公司区域
    sum(other_aux_mat_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as other_aux_mat_consum_amt,               -- 其他辅料耗金额
    other_aux_mat_consum_amt_fgs,                                                                                             -- 其他辅料耗用金额_分公司
    other_aux_mat_consum_amt_fgsqy,                                                                                           -- 其他辅料耗用金额_分公司区域
    compre_electqty_pur_unprice,
    sum(compre_electqty_consumqty_tzq)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as compre_electqty_consumqty_tzq,          -- 综合电量耗用量_调整前
    photovol_elect_unprice,
    sum(photovol_elect_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as photovol_elect_consumqty,               -- 光伏电量耗用量
    if(day(dt.dt_date) >= 25, stategrid_real_elect_unprice,
       stategrid_estimate_elect_unprice)                                           as stategrid_elect_unprice,                -- 国网电量单价
    sum(stategrid_elect_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as stategrid_elect_consumqty,              -- 国网电量耗用量
    if(day(dt.dt_date) = 24, stategrid_elect_adjust_consum_amt,
       0)                                                                          as stategrid_elect_adjust_consum_amt,      -- 国网电量调整耗用金额
    sum(ao_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as ao_compens_qty_consumqty,               -- 氧化铝补偿量耗用量
    sum(cryo_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as cryo_compens_qty_consumqty,
    sum(elect_blk_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as elect_blk_compens_qty_consumqty,
    sum(alf3_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as alf3_compens_qty_consumqty,
    sum(mgf2_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as mgf2_compens_qty_consumqty,
    sum(caf2_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as caf2_compens_qty_consumqty,
    sum(soda_ash_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as soda_ash_compens_qty_consumqty,
    sum(anode_carb_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as anode_carb_compens_qty_consumqty,
    sum(natgas_compens_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as natgas_compens_consumqty,               -- 天然气补偿耗用量
    sum(tank_startup_compens_electqty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as tank_startup_compens_electqty_consumqty,
    sum(tank_shutdown_deduct_electqty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as tank_shutdown_deduct_electqty_consumqty,
    sum(ao_end_waste_mat_compens_qty_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date) as ao_end_waste_mat_compens_qty_consumqty, -- 氧化铝末端废料补偿量耗用量
    now()                                                                          as etl_time
from
    (
        /*生成每天每个分厂的维度*/
        select
            dt_date,
            dt.prod_ym           as prod_ym,
            '电解铝'             as business_format,
            branch_factory_no    as branch_factory_code,      -- 分厂
            branch_factory_nm    as branch_factory_name,      -- 分厂
            company_area_no      as branch_company_area_code, -- 分公司区域
            company_area_nm      as branch_company_area_name, -- 分公司区域
            company_no           as branch_company_code,      -- 分公司
            company_nm           as branch_company_name,      -- 分公司
            module_no            as company_code,             -- 总公司
            module_nm            as company_name,             -- 总公司
            head_company_area_no as company_area_code,        -- 总公司区域
            head_company_area_nm as company_area_name         -- 总公司区域
        from
            sdhq.dim_prd_date dt
            join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '铝业公司'
        where
            dt_date between '2025-11-25' and LEAST('${now_date}', curdate())
            and dt_date >= date_trunc(LEAST('${now_date}', curdate()) - interval if(day(LEAST('${now_date}', curdate())) >= 6, 1, 2) month, 'month') + interval 24 day /*每月6号封版上月数据*/
        ) dt
    left join (
        /*液态铝额定产能*/
        select
            prod_ym,
            branch_factory_code,
            liq_alum_prod_capacity                                as liq_alum_prod_capacity_fc,
            sum(liq_alum_prod_capacity)
                over (partition by prod_ym, company_area_no)      as liq_alum_prod_capacity_fgsqy,
            sum(liq_alum_prod_capacity)
                over (partition by prod_ym, company_no)           as liq_alum_prod_capacity_fgs,
            sum(liq_alum_prod_capacity)
                over (partition by prod_ym, module_no)            as liq_alum_prod_capacity_zgs,
            sum(liq_alum_prod_capacity)
                over (partition by prod_ym, head_company_area_no) as liq_alum_prod_capacity_zgsqy,
            labor_cost                                            as labor_cost,
            stategrid_elect_adjust_consum_amt
        from
            (
                /*先汇总*/
                select
                    a.prod_ym                              as prod_ym,
                    a.branch_factory_code                  as branch_factory_code,
                    sum(liq_alum_prod_capacity)            as liq_alum_prod_capacity,            -- 液体铝额定产能
                    sum(stategrid_elect_adjust_consum_amt) as stategrid_elect_adjust_consum_amt, -- 国网电量调整耗用金额
                    sum(labor_cost) / avg(dt.days)         as labor_cost                         -- 人工成本
                from
                    sdhq.dwd_prd_al_branfact_m_ufd a
                    left join sdhq.v_prd_ym_date dt on a.prod_ym = dt.prod_ym
                group by a.prod_ym, branch_factory_code
                ) a
            left join sdhq.dim_prd_org_flatten_ufd org
                on a.branch_factory_code = org.branch_factory_no
        ) capacity
        on dt.prod_ym = capacity.prod_ym and dt.branch_factory_code = capacity.branch_factory_code
    left join (
        /**/
        select
            a.prod_ym                             as prod_ym,
            branch_company_code                   as branch_company_code,
            sum(alumbusbar_prod_m)                as alumbusbar_prod_m_fgs,            -- 铝母线产量_月_分公司
            sum(photovol_elect_unprice)           as photovol_elect_unprice,           -- 光伏电单价
            sum(compre_electqty_pur_unprice)      as compre_electqty_pur_unprice,      -- 综合电量电单价
            sum(stategrid_real_elect_unprice)     as stategrid_real_elect_unprice,     -- 国网电量真实电单价
            sum(stategrid_estimate_elect_unprice) as stategrid_estimate_elect_unprice, -- 国网电量预估电单价
            sum(desulf_wateruse_unprice)          as desulf_wateruse_unprice,          -- 脱硫用水单价
            sum(ao_pur_unprice)                   as ao_pur_unprice,                   -- 氧化铝单价
            sum(elect_sales_unprice)              as elect_sales_unprice,              -- 电单价_毛利使用
            sum(ao_sales_unprice)                 as ao_sales_unprice,                 -- 氧化铝单价_毛利使用
            sum(liq_alum_sales_unprice)           as liq_alum_sales_unprice,           -- 液态铝销售单价
            sum(alumingot_sales_unprice)          as alumingot_sales_unprice,          -- 铝锭销售单价
            sum(alumbusbar_sales_unprice)         as alumbusbar_sales_unprice,         -- 铝母线销售单价
            sum(share_exp)                        as share_exp_fgs,                    -- 共享费用_分公司
            sum(envir_prot_tax_amt)               as envir_prot_tax_amt_fgs,           -- 环保税_分公司
            sum(overhaul_resi_proc_exp)           as overhaul_resi_proc_exp_fgs,       -- 大修渣处置费_分公司
            1
        from
            sdhq.dwd_prd_al_branch_company_m_ufd a
            left join sdhq.v_prd_ym_date dt on a.prod_ym = dt.prod_ym
        group by a.prod_ym, branch_company_code
        ) deprec
        on dt.prod_ym = deprec.prod_ym and dt.branch_company_code = deprec.branch_company_code
    left join (
        /**/
        select
            a.prod_ym                   as prod_ym,
            a.branch_company_area_code  as branch_company_area_code,
            sum(alumbusbar_prod_m)      as alumbusbar_prod_m_fgsqy,      -- 铝母线产量_月_分公司区域
            sum(overhaul_resi_proc_exp) as overhaul_resi_proc_exp_fgsqy, -- 大修渣处置费_分公司区域
            sum(share_exp)              as share_exp_fgsqy,              -- 共享费用_分公司区域
            sum(envir_prot_tax_amt)     as envir_prot_tax_amt_fgsqy,     -- 环保税_分公司区域
            1
        from
            sdhq.dwd_prd_al_brancom_area_m_ufd a
            left join sdhq.v_prd_ym_date dt on a.prod_ym = dt.prod_ym
        group by a.prod_ym, branch_company_area_code
        ) deprec_area on dt.prod_ym = deprec_area.prod_ym and
                         dt.branch_company_area_code = deprec_area.branch_company_area_code
    left join (
        /*NCC出库费用_分厂*/
        select
            dt_date,
            org_code              as branch_factory_no,
            ncc_other_exp         as ncc_other_exp_fc,        --  其他费用_分厂
            techno_retro_exp      as techno_retro_exp_fc,     --  技改费用_分厂
            overhaul_exp          as overhaul_exp_fc,         --  大修费用_分厂
            repair_exp            as repair_exp_fc,           --  日常维修费用_分厂
            vehicle_oil_usage_exp as vehicle_oil_usage_exp_fc --  车辆用油_分厂
        from
            sdhq.v_dwd_prd_al_ncc_ckfy
        where
            org_code in (
                select
                    branch_factory_no
                from
                    sdhq.dim_prd_org_flatten_ufd
                where
                    module_nm = '铝业公司'
                ) /*过滤分厂*/
        ) ncc_fc
        on dt.dt_date = ncc_fc.dt_date and dt.branch_factory_code = ncc_fc.branch_factory_no
    left join (
        /*NCC物资耗用量、耗用金额*/
        select
            dt_date,
            org_code                      as branch_factory_no,
            other_aux_mat_consumqty       as other_aux_mat_consumqty,      -- 其他辅料耗用量
            other_aux_mat_consum_amt      as other_aux_mat_consum_amt,     -- 其他辅料耗用金额
            natgas_consumqty_tzq          as natgas_consumqty_tzq,         -- 天然气耗用量
            natgas_compens_consumqty      as natgas_compens_consumqty,     -- 天然气补偿耗用量
            anode_wksp_soda_ash_consumqty as anode_wksp_soda_ash_consumqty -- 阳极车间纯碱耗用量
        from
            sdhq.v_dwd_prd_al_ncc_wzhy a
        where
            org_code in (
                select
                    branch_factory_no
                from
                    sdhq.dim_prd_org_flatten_ufd
                where
                    module_nm = '铝业公司'
                ) /*过滤分厂*/
        ) nnc on dt.dt_date = nnc.dt_date and dt.branch_factory_code = nnc.branch_factory_no
    left join (
        /*NCC物资单价*/
        select
            dt.prod_ym,
            cost_acctg_dept_code                                    as branch_factory_no,
            sum(if(a.mat_id in
                   ('1001A11000000000MTV0', '1001A1100000006QMWN6', '1001A110000003B98ZFB',
                    '1001A110000000043D82', '1001A11000000222DOZW'), whouse_disp_amt, 0)) /
            sum(if(a.mat_id in
                   ('1001A11000000000MTV0', '1001A1100000006QMWN6', '1001A110000003B98ZFB',
                    '1001A110000000043D82', '1001A11000000222DOZW'), draw_qty,
                   0)) * 1000                                       as li2co3_unprice,  -- 碳酸锂单价
            sum(if(a.mat_id = '1001A11000000004DUZ4', whouse_disp_amt, 0)) /
            sum(if(a.mat_id = '1001A11000000004DUZ4', draw_qty, 0)) as natgas_unprice,  -- 天然气单价
            sum(if(a.mat_id = '1001A11000000000A34L', whouse_disp_amt, 0)) /
            sum(if(a.mat_id = '1001A11000000000A34L', draw_qty, 0)) as cryo_unprice,    -- 冰晶石单价
            sum(if(a.mat_id in
                   ('1001A11000000005TN1A', '1001A11000000005TMK5', '1001A11000000000EWHG'),
                   whouse_disp_amt, 0)) /
            sum(if(a.mat_id in ('1001A11000000005TN1A', '1001A11000000005TMK5',
                                '1001A11000000000EWHG'), draw_qty, 0)) *
            1000                                                    as electro_unprice, -- 电解质块（粉）单价
            sum(if(a.mat_id = '1001A11000000000A36J', whouse_disp_amt, 0)) /
            sum(if(a.mat_id = '1001A11000000000A36J', draw_qty, 0)) *
            1000                                                    as mgf2_unprice,    -- 氟化镁单价
            sum(if(a.mat_id = '1001A11000000000A365', whouse_disp_amt, 0)) /
            sum(if(a.mat_id = '1001A11000000000A365', draw_qty, 0)) *
            1000                                                    as caf2_unprice,    -- 氟化钙单价
            sum(if(a.mat_id = '1001A11000000000A34Z' and not regexp (a.draw_dept_name, '阳极|综合'),
                   whouse_disp_amt, 0)) /
            sum(if(a.mat_id = '1001A11000000000A34Z' and not regexp (a.draw_dept_name, '阳极|综合'),
                   draw_qty, 0)) *
            1000                                                    as soda_ash_unprice -- 纯碱单价
        from
            sdhq.dwd_pur_ic_material_ncc_ufd a
            left join sdhq.dim_prd_date dt on date(whouse_disp_time) = dt.dt_date
            left join sdhq.dim_org_dept_ufd dep on a.draw_dept_id = dep.dept_id
        where
              dep.cost_acctg_dept_code in (
                  select distinct
                      branch_factory_no
                  from
                      sdhq.dim_prd_org_flatten_ufd
                  where
                      module_nm = '铝业公司'
                  ) /*过滤分厂*/
          and a.whouse_disp_time >= '2025-11-25'
          and a.whouse_disp_type_id = '4D-Cxx-004'
        group by dt.prod_ym, cost_acctg_dept_code
        ) nnc2 on dt.prod_ym = nnc2.prod_ym and dt.branch_factory_code = nnc2.branch_factory_no
    left join sdhq.ods_fryw_ly_fill_correct_unit_price_ufd pri
        on dt.prod_ym = pri.mth and dt.branch_factory_code = pri.factory_no
    left join (
        /*产量、耗用量*/
        select
            dt_date,
            branch_factory_code,
            sum(tank_startup_compens_electqty_consumqty) as tank_startup_compens_electqty_consumqty, --  启动槽补偿电量耗用量
            sum(tank_shutdown_deduct_electqty_consumqty) as tank_shutdown_deduct_electqty_consumqty, -- 停槽扣除电量耗用量
            sum(alf3_compens_qty_consumqty)              as alf3_compens_qty_consumqty,              --  氟化铝补偿量耗用量
            sum(mgf2_compens_qty_consumqty)              as mgf2_compens_qty_consumqty,              -- 氟化镁补偿量耗用量
            sum(caf2_compens_qty_consumqty)              as caf2_compens_qty_consumqty,              -- 氟化钙补偿量耗用量
            sum(soda_ash_compens_qty_consumqty)          as soda_ash_compens_qty_consumqty,          -- 纯碱补偿量耗用量
            sum(anode_carb_compens_qty_consumqty)        as anode_carb_compens_qty_consumqty,        -- 阳极炭块补偿量耗用量
            sum(elect_blk_compens_qty_consumqty)         as elect_blk_compens_qty_consumqty,         -- 电解质块补偿量耗用量
            sum(cryo_compens_qty_consumqty)              as cryo_compens_qty_consumqty,              -- 冰晶石补偿量耗用量
            sum(compre_electqty_consumqty_tzq)           as compre_electqty_consumqty_tzq,           -- 综合电量耗用量_调整前,
            sum(photovol_elect_consumqty)                as photovol_elect_consumqty,                -- 光伏电量耗用量
            sum(ao_compens_qty_consumqty)                as ao_compens_qty_consumqty,                -- 氧化铝补偿量耗用量
            sum(soda_ash_consumqty_tzq)                  as soda_ash_consumqty_tzq,                  -- 纯碱耗用量_调整前
            sum(caf2_consumqty_tzq)                      as caf2_consumqty_tzq,                      -- 氟化钙耗用量_调整前
            sum(mgf2_consumqty_tzq)                      as mgf2_consumqty_tzq,                      -- 氟化镁耗用量_调整前
            sum(electro_consumqty_tzq)                   as electro_consumqty_tzq,                   -- 电解质块（粉）耗用量_调整前
            sum(cryo_consumqty_tzq)                      as cryo_consumqty_tzq,                      -- 冰晶石耗用量_调整前
            sum(alf3_consumqty_tzq)                      as alf3_consumqty_tzq,                      -- 氟化铝耗用量_调整前
            sum(anode_carb_consumqty_tzq)                as anode_carb_consumqty_tzq,                -- 阳极炭块耗用量_调整前
            sum(ao_consumqty_tzq)                        as ao_consumqty_tzq,                        -- 氧化铝耗用量_调整前
            sum(liq_alum_prod)                           as liq_alum_prod,                           -- 液态铝产量
            sum(liq_alum_997_prod)                       as liq_alum_997_prod,                       -- 液态铝99.70产量
            sum(li2co3_consumqty)                        as li2co3_consumqty,                        -- 碳酸锂耗用量
            sum(ao_end_waste_mat_compens_qty_consumqty)  as ao_end_waste_mat_compens_qty_consumqty,  -- 氧化铝末端废料补偿量耗用量
            sum(stategrid_elect_consumqty)               as stategrid_elect_consumqty,               -- 国网电量耗用量
            1
        from
            sdhq.dwd_prd_al_fact_d_ufd
        group by dt_date, branch_factory_code
        ) fact_d
        on dt.dt_date = fact_d.dt_date and dt.branch_factory_code = fact_d.branch_factory_code
    left join (
        /*氟化铝单价、阳极炭块单价*/
        select
            dt.prod_ym,
            cost_acctg_dept_code                              as branch_factory_code,
            sum(if(mat_name like '%氟化铝%', whouse_disp_amt, null)) /
            sum(if(mat_name like '%氟化铝%', draw_qty, null)) as alf3_unprice,      -- 氟化铝单价
            sum(if(mat_code = '1265', whouse_disp_amt, 0)) /
            sum(if(mat_code = '1265', draw_qty, 0))           as anode_carb_unprice -- 阳极炭块单价
        from
            sdhq.dwd_pur_ic_material_mms_bulk_ufd a
            left join sdhq.dim_prd_date dt on date(a.whouse_disp_time) = dt.dt_date
            left join sdhq.dim_org_dept_ufd dep
                on a.draw_dept_name = dep.dept_name and dep.source_system = 'ncc'
        where
            whouse_disp_time >= '2025-11-25'
                and cost_acctg_dept_code in (
                select
                    branch_factory_no
                from
                    sdhq.dim_prd_org_flatten_ufd
                where
                    module_nm = '铝业公司'
                )
                and regexp
            (dep.dept_name, '宏正|阳信|汇盛|魏桥|惠民|北海|云南宏泰|云南宏启|云南宏合')
        group by
            dt.prod_ym, cost_acctg_dept_code
        ) mms on dt.prod_ym = mms.prod_ym and dt.branch_factory_code = mms.branch_factory_code
    left join (
        /*石灰石粉耗用量、石灰石粉耗用金额*/
        select
            dt.dt_date,
            cost_acctg_dept_code as branch_factory_code,
            sum(draw_qty)        as limestone_powder_consumqty, -- 石灰石粉耗用量
            sum(whouse_disp_amt) as limestone_powder_consum_amt -- 石灰石粉耗用金额
        from
            sdhq.dwd_pur_ic_material_mms_bulk_ufd a
            left join sdhq.dim_prd_date dt on date(a.whouse_disp_time) = dt.dt_date
            left join sdhq.dim_org_dept_ufd dep
                on a.draw_dept_name = dep.dept_name and dep.source_system = 'ncc'
        where
            whouse_disp_time >= '2025-11-25'
                and whouse_disp_time < '2025-12-25'
                and mat_code = '1588'
                and cost_acctg_dept_code in (
                select
                    branch_factory_no
                from
                    sdhq.dim_prd_org_flatten_ufd
                where
                    module_nm = '铝业公司'
                )
                and regexp
            (dep.dept_name, '宏正|阳信|汇盛|魏桥|惠民|北海|云南宏泰|云南宏启|云南宏合')
        group by
            dt.dt_date, cost_acctg_dept_code
        ) mms2 on dt.dt_date = mms2.dt_date and dt.branch_factory_code = mms2.branch_factory_code
    left join (
        /*分公司区域*/
        select
            dt.dt_date,
            dt.branch_company_area_code,
            sum(ncc_other_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as ncc_other_exp_fgsqy,                       -- 其他费用_分公司区域
            sum(techno_retro_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as techno_retro_exp_fgsqy,                    -- 技改费用_分公司区域
            sum(overhaul_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as overhaul_exp_fgsqy,                        -- 大修费用_分公司区域
            sum(vehicle_oil_usage_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as vehicle_oil_usage_exp_fgsqy,               -- 车辆用油_分公司区域
            sum(repair_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as repair_exp_fgsqy,                          -- 日常维修费用_分公司区域
            sum(dine_exp)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as dine_exp_fgsqy,                            -- 工作餐_分公司区域
            sum(scrap_mat_byprod_nontax_sales_amt)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as scrap_mat_byprod_nontax_sales_amt_fgsqy,   -- 废旧物资及副产品不含税销售额_分公司区域
            sum(alumingot_prod)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as alumingot_prod_fgsqy,                      -- 铝锭产量_分公司区域
            sum(alumbusbar_prod)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as alumbusbar_prod_fgsqy,                     -- 铝母线产量_分公司区域
            sum(desulf_wateruse_consumqty)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as desulf_wateruse_consumqty_fgsqy,           -- 脱硫用水耗用量_分公司区域
            sum(other_aux_mat_consumqty_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as other_aux_mat_consumqty_fgsqy,             -- 其他辅料耗用量_分公司区域
            sum(other_aux_mat_consum_amt_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as other_aux_mat_consum_amt_fgsqy,            -- 其他辅料耗用金额_分公司区域
            sum(natgas_consumqty_tzq_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as natgas_consumqty_tzq_fgsqy,                -- 天然气耗用量_分公司区域
            sum(anode_wksp_soda_ash_consumqty_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as anode_wksp_soda_ash_consumqty_fgsqy,       -- 阳极车间纯碱耗用量_分公司区域
            sum(liq_alum_prod_m_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as liq_alum_prod_m_fgsqy,                     -- 液态铝产量_月_分公司区域
            sum(alumingot_prod_m_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as alumingot_prod_m_fgsqy,                    -- 铝锭产量_月_分公司区域
            sum(deprec_exp_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as deprec_exp_fgsqy,                          -- 折旧费_分公司区域
            sum(prod_techno_retro_outsource_exp_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as prod_techno_retro_outsource_exp_fgsqy,     -- 生产技改类外委费用_分公司区域
            sum(non_prod_techno_retro_outsource_exp_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as non_prod_techno_retro_outsource_exp_fgsqy, -- 非生产技改类外委费用_分公司区域
            1
        from
            (
                /*生成每天每个分公司区域的维度*/
                select
                    dt_date,
                    prod_ym,
                    company_area_no as branch_company_area_code -- 分公司区域
                from
                    sdhq.dim_prd_date dt
                    join (
                        select distinct
                            company_area_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '铝业公司'
                        ) org on 1 = 1
                where
                    dt_date between '2025-11-25' and curdate()
                ) dt
            left join (
                /*NCC出库费用_分公司区域*/
                select
                    dt_date,
                    org_code              as branch_company_area_code,
                    ncc_other_exp         as ncc_other_exp,        -- 其他费用_分公司区域
                    techno_retro_exp      as techno_retro_exp,     -- 技改费用_分公司区域
                    overhaul_exp          as overhaul_exp,         -- 大修费用_分公司区域
                    repair_exp            as repair_exp,           -- 日常维修费用_分公司区域
                    vehicle_oil_usage_exp as vehicle_oil_usage_exp -- 车辆用油_分公司区域
                from
                    sdhq.v_dwd_prd_al_ncc_ckfy
                where
                    org_code in (
                        select distinct
                            company_area_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '铝业公司'
                        ) /*过滤组织*/
                ) ncc_fgsqy
                on dt.dt_date = ncc_fgsqy.dt_date and
                   dt.branch_company_area_code = ncc_fgsqy.branch_company_area_code
            left join (
                /*NCC物资耗用_分公司区域*/
                select
                    dt_date,
                    org_code                      as branch_company_area_code,
                    other_aux_mat_consumqty       as other_aux_mat_consumqty_fgsqy,      -- 其他辅料耗用量_分公司区域
                    other_aux_mat_consum_amt      as other_aux_mat_consum_amt_fgsqy,     -- 其他辅料耗用金额_分公司区域
                    natgas_consumqty_tzq          as natgas_consumqty_tzq_fgsqy,         -- 天然气耗用量_分公司区域
                    anode_wksp_soda_ash_consumqty as anode_wksp_soda_ash_consumqty_fgsqy -- 阳极车间纯碱耗用量_分公司区域
                from
                    sdhq.v_dwd_prd_al_ncc_wzhy
                where
                    org_code in (
                        select distinct
                            company_area_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        )
                ) as ncc_wzhy on dt.dt_date = ncc_wzhy.dt_date and
                                 dt.branch_company_area_code = ncc_wzhy.branch_company_area_code
            left join (
                /*工作餐费用_分公司区域*/
                select
                    dt_date,
                    branch_company_area_code,
                    sum(alumingot_prod)                    as alumingot_prod,                   -- 铝锭产量
                    sum(alumbusbar_prod)                   as alumbusbar_prod,                  -- 铝母线产量
                    sum(desulf_wateruse_consumqty)         as desulf_wateruse_consumqty,        -- 脱硫用水耗用量
                    sum(dine_exp)                          as dine_exp,                         -- 工作餐
                    sum(scrap_mat_byprod_nontax_sales_amt) as scrap_mat_byprod_nontax_sales_amt -- 废旧物资及副产品不含税销售额
                from
                    sdhq.dwd_prd_al_brancom_area_d_ufd
                group by dt_date, branch_company_area_code
                ) dine_fgsqy
                on dt.dt_date = dine_fgsqy.dt_date and
                   dt.branch_company_area_code = dine_fgsqy.branch_company_area_code
            left join (
                /**/
                select
                    a.prod_ym                                               as prod_ym,
                    a.branch_company_area_code                              as branch_company_area_code,
                    sum(liq_alum_prod_m) / avg(dt.days)                     as liq_alum_prod_m_fgsqy,                     -- 液态铝产量_月_分公司区域
                    sum(alumingot_prod_m) / avg(dt.days)                    as alumingot_prod_m_fgsqy,                    -- 铝锭产量_月_分公司区域
                    sum(deprec_exp) / avg(dt.days)                          as deprec_exp_fgsqy,                          -- 折旧费_分公司区域
                    sum(prod_techno_retro_outsource_exp) / avg(dt.days)     as prod_techno_retro_outsource_exp_fgsqy,     -- 生产技改类外委费用_分公司区域
                    sum(non_prod_techno_retro_outsource_exp) / avg(dt.days) as non_prod_techno_retro_outsource_exp_fgsqy, -- 非生产技改类外委费用_分公司区域
                    1
                from
                    sdhq.dwd_prd_al_brancom_area_m_ufd a
                    left join sdhq.v_prd_ym_date dt on a.prod_ym = dt.prod_ym
                group by a.prod_ym, branch_company_area_code
                ) avgfgsqy on dt.prod_ym = avgfgsqy.prod_ym and
                              dt.branch_company_area_code = avgfgsqy.branch_company_area_code
        ) dtfgsqy
        on dt.dt_date = dtfgsqy.dt_date and
           dt.branch_company_area_code = dtfgsqy.branch_company_area_code
    left join (
        /*分公司*/
        select
            dt.dt_date,
            dt.branch_company_code,
            sum(ncc_other_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as ncc_other_exp_fgs,                       -- 其他费用_分公司
            sum(techno_retro_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as techno_retro_exp_fgs,                    -- 技改费用_分公司
            sum(overhaul_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as overhaul_exp_fgs,                        -- 大修费用_分公司
            sum(vehicle_oil_usage_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as vehicle_oil_usage_exp_fgs,               -- 车辆用油_分公司
            sum(repair_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as repair_exp_fgs,                          -- 日常维修费用_分公司
            sum(dine_exp)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as dine_exp_fgs,                            -- 工作餐_分公司
            sum(other_aux_mat_consum_amt)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as other_aux_mat_consum_amt_fgs,            -- 其他辅料耗用金额_分公司
            sum(other_aux_mat_consumqty)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as other_aux_mat_consumqty_fgs,             -- 其他辅料耗用量_分公司
            sum(natgas_consumqty_tzq)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as natgas_consumqty_tzq_fgs,                -- 天然气耗用量_分公司
            sum(desulf_wateruse_consumqty)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as desulf_wateruse_consumqty_fgs,           -- 脱硫用水耗用量_分公司
            sum(anode_wksp_soda_ash_consumqty)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as anode_wksp_soda_ash_consumqty_fgs,       -- 阳极车间纯碱耗用量_分公司
            sum(alumingot_prod)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as alumingot_prod_fgs,                      -- 铝锭产量_分公司
            sum(alumbusbar_prod)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as alumbusbar_prod_fgs,                     -- 铝母线产量_分公司
            sum(scrap_mat_byprod_nontax_sales_amt)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as scrap_mat_byprod_nontax_sales_amt_fgs,   -- 废旧物资及副产品不含税销售额_分公司
            sum(liq_alum_prod_m_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as liq_alum_prod_m_fgs,                     -- 液态铝产量_月_分公司
            sum(alumingot_prod_m_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as alumingot_prod_m_fgs,                    -- 铝锭产量_月_分公司
            sum(prod_techno_retro_outsource_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as prod_techno_retro_outsource_exp_fgs,     -- 生产技改类外委费用_分公司
            sum(non_prod_techno_retro_outsource_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as non_prod_techno_retro_outsource_exp_fgs, -- 非生产技改类外委费用_分公司
            1
        from
            (
                /*生成每天每个分公司的维度*/
                select
                    dt_date,
                    prod_ym,
                    company_no as branch_company_code -- 分公司
                from
                    sdhq.dim_prd_date dt
                    join (
                        select distinct
                            company_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '铝业公司'
                        ) org on 1 = 1
                where
                    dt_date between '2025-11-25' and curdate()
                ) dt
            left join (
                /*NCC出库费用_分公司*/
                select
                    dt_date,
                    org_code              as branch_company_code,
                    ncc_other_exp         as ncc_other_exp,        -- 其他费用_分公司
                    techno_retro_exp      as techno_retro_exp,     -- 技改费用_分公司
                    overhaul_exp          as overhaul_exp,         -- 大修费用_分公司
                    repair_exp            as repair_exp,           -- 日常维修费用_分公司
                    vehicle_oil_usage_exp as vehicle_oil_usage_exp -- 车辆用油_分公司
                from
                    sdhq.v_dwd_prd_al_ncc_ckfy
                where
                    org_code in (
                        select distinct
                            company_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '铝业公司'
                        ) /*过滤组织*/
                ) ncc_fgs
                on dt.dt_date = ncc_fgs.dt_date and
                   dt.branch_company_code = ncc_fgs.branch_company_code
            left join (
                /*耗用金额_分公司、耗用量_分公司*/
                select
                    dt_date,
                    org_code                      as branch_company_no,
                    other_aux_mat_consum_amt      as other_aux_mat_consum_amt,      -- 其他辅料耗用金额_分公司
                    natgas_consumqty_tzq          as natgas_consumqty_tzq,          -- 天然气耗用量_分公司
                    anode_wksp_soda_ash_consumqty as anode_wksp_soda_ash_consumqty, -- 阳极车间纯碱耗用量_分公司
                    other_aux_mat_consumqty       as other_aux_mat_consumqty,       -- 其他辅料耗用量_分公司
                    1
                from
                    sdhq.v_dwd_prd_al_ncc_wzhy
                where
                    org_code in (
                        select distinct
                            company_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '铝业公司'
                        ) /*过滤分公司*/
                ) nncfgs
                on dt.dt_date = nncfgs.dt_date and dt.branch_company_code = nncfgs.branch_company_no
            left join (
                /*工作餐费用、脱硫用水耗用量、铝锭产量、铝母线产量*/
                select
                    dt_date,
                    branch_company_code,
                    sum(dine_exp)                          as dine_exp,                         -- 工作餐费用
                    sum(desulf_wateruse_consumqty)         as desulf_wateruse_consumqty,        -- 脱硫用水耗用量
                    sum(alumingot_prod)                    as alumingot_prod,                   --  铝锭产量
                    sum(alumbusbar_prod)                   as alumbusbar_prod,                  -- 铝母线产量
                    sum(scrap_mat_byprod_nontax_sales_amt) as scrap_mat_byprod_nontax_sales_amt -- 废旧物资及副产品不含税销售额
                from
                    sdhq.dwd_prd_al_branch_company_d_ufd
                group by dt_date, branch_company_code
                ) dine_fgs
                on dt.dt_date = dine_fgs.dt_date and
                   dt.branch_company_code = dine_fgs.branch_company_code
            left join (
                /**/
                select
                    a.prod_ym                                               as prod_ym,
                    branch_company_code                                     as branch_company_code,
                    sum(liq_alum_prod_m) / avg(dt.days)                     as liq_alum_prod_m_fgs,                     -- 液态铝产量_月_分公司
                    sum(alumingot_prod_m) / avg(dt.days)                    as alumingot_prod_m_fgs,                    -- 铝锭产量_月_分公司
                    sum(prod_techno_retro_outsource_exp) / avg(dt.days)     as prod_techno_retro_outsource_exp_fgs,     -- 生产技改类外委费用_分公司
                    sum(non_prod_techno_retro_outsource_exp) / avg(dt.days) as non_prod_techno_retro_outsource_exp_fgs, -- 非生产技改类外委费用_分公司
                    1
                from
                    sdhq.dwd_prd_al_branch_company_m_ufd a
                    left join sdhq.v_prd_ym_date dt on a.prod_ym = dt.prod_ym
                group by a.prod_ym, branch_company_code
                ) avgfgs on dt.prod_ym = avgfgs.prod_ym and
                            dt.branch_company_code = avgfgs.branch_company_code
        ) dtfgs
        on dt.dt_date = dtfgs.dt_date and
           dt.branch_company_code = dtfgs.branch_company_code
;