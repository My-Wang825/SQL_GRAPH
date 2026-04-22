/*表类型为主键模型，可以无需清空表*/
-- truncate table sdhq.ads_prd_ao_finan_wtable_ufd;

/**/
insert into
    sdhq.ads_prd_ao_finan_wtable_ufd
select
    dt.dt_date                                                                          as dt_date,                                   -- 日期
    dt.branch_factory_code                                                              as branch_factory_code,                       -- 分厂编码
    branch_factory_name,                                                                                                              -- 分厂名称
    dt.branch_company_area_code                                                         as branch_company_area_code,                  -- 分公司区域编码
    branch_company_area_name,                                                                                                         -- 分公司区域名称
    dt.branch_company_code                                                              as branch_company_code,                       -- 分公司编码
    branch_company_name,                                                                                                              -- 分公司名称
    company_name,                                                                                                                     -- 公司名称
    dt.company_code                                                                     as company_code,                              -- 公司编码
    business_format,                                                                                                                  -- 业态
    dt.prod_ym                                                                          as prod_ym,                                   -- 生产年月
    ao_rated_prod_capacity_fc,                                                                                                        -- 氧化铝额定产能_分厂
    ao_rated_prod_capacity_fgsqy,                                                                                                     -- 氧化铝额定产能_分公司区域
    ao_rated_prod_capacity_fgs,                                                                                                       -- 氧化铝额定产能_分公司
    ao_rated_prod_capacity_zgs,                                                                                                       -- 氧化铝额定产能_总公司
    sum(ao_plan_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as ao_plan_prod,                              -- 氧化铝计划产量
    sum(fe_plan_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as fe_plan_prod,                              -- 铁粉计划产量
    sum(bxt_consumqty_gwak)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_gwak,                        -- 矿石耗用量_高温奥矿
    sum(bxt_consumqty_dwak)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_dwak,                        -- 矿石耗用量_低温奥矿
    sum(bxt_consumqty_dmnjk)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_dmnjk,                       -- 矿石耗用量_多米尼加矿
    sum(bxt_consumqty_jnyk)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_jnyk,                        -- 矿石耗用量_几内亚矿
    sum(bxt_consumqty_slmk)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_slmk,                        -- 矿石耗用量_所罗门矿
    sum(bxt_consumqty_jnykcbg)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_jnykcbg,                     -- 矿石耗用量_几内亚矿(CBG)
    sum(bxt_consumqty_ymjk)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as bxt_consumqty_ymjk,                        -- 矿石耗用量_牙买加矿
    bxt_unprice_ymjk,                                                                                                                 -- 矿石单价_牙买加矿
    bxt_unprice_jnykcbg,                                                                                                              -- 矿石单价_几内亚矿(CBG)
    bxt_unprice_slmk,                                                                                                                 -- 矿石单价_所罗门矿
    bxt_unprice_jnyk,                                                                                                                 -- 矿石单价_几内亚矿
    bxt_unprice_dmnjk,                                                                                                                -- 矿石单价_多米尼加矿
    bxt_unprice_dwak,                                                                                                                 -- 矿石单价_低温奥矿
    bxt_unprice_gwak,                                                                                                                 -- 矿石单价_高温奥矿
    sum(liqcaus_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as liqcaus_consumqty,                         -- 液碱耗用量
    sum(liqcaus_disp_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as liqcaus_disp_amt,                          -- 液碱出库金额
    sum(liqcaus_freight_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as liqcaus_freight_amt,                       -- 液碱运费金额
    sum(lime_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as lime_consumqty,                            -- 石灰耗用量
    sum(lime_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as lime_consum_amt,                           -- 石灰耗用金额
    sum(floc_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as floc_consumqty,                            -- 絮凝剂耗用量
    sum(floc_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as floc_consum_amt,                           -- 絮凝剂耗用金额
    sum(other_raw_mat_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as other_raw_mat_consumqty,                   -- 其他原材料耗用量
    sum(other_raw_mat_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as other_raw_mat_consum_amt,                  -- 其他原材料金额
    sum(other_raw_mat_consum_amt_fgsqy)
        over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as other_raw_mat_consum_amt_fgsqy,            -- 其他原材料金额_分公司区域
    other_raw_mat_consum_amt_fgs,                                                                                                     -- 其他原材料金额_分公司
    other_raw_mat_consum_amt_zgs,                                                                                                     -- 其他原材料金额_总公司
    sum(desulf_raw_mat_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as desulf_raw_mat_consumqty,                  -- 脱硫原材料耗用量
    sum(desulf_raw_mat_consum_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as desulf_raw_mat_consum_amt,                 -- 脱硫原材料金额
    desulf_raw_mat_consum_amt_fgsqy,                                                                                                  -- 脱硫原材料金额_分公司区域
    desulf_raw_mat_consum_amt_fgs,                                                                                                    -- 脱硫原材料金额_分公司
    desulf_raw_mat_consum_amt_zgs,                                                                                                    -- 脱硫原材料金额_总公司
    lowpres_steam_unprice,                                                                                                            -- 低压蒸汽单价
    sum(lowpres_steam_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as lowpres_steam_consumqty,                   -- 低压蒸汽耗用量
    highpres_steam_unprice,                                                                                                           -- 高压蒸汽单价
    sum(highpres_steam_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as highpres_steam_consumqty,                  -- 高压蒸汽耗用量
    elect_unprice,                                                                                                                    -- 电单价
    sum(ao_elect_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as ao_elect_consumqty,                        -- 氧化铝电耗用量
    sum(irex_elect_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as irex_elect_consumqty,                      -- 提铁电耗用量
    null                                                                                as cokegas_unprice,                           -- 焦化煤气单价 /*近几年已不用了*/
    sum(cokegas_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as cokegas_consumqty,                         -- 焦化煤气耗用量
    null                                                                                as natgas_unprice,                            -- 天然气单价  /*近几年已不用了*/
    sum(natgas_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as natgas_consumqty,                          -- 天然气耗用量
    ifnull(coal_adjust_price, coal_unprice)                                             as coal_unprice,                              -- 煤炭单价
    sum(coal_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as coal_consumqty,                            -- 煤炭耗用量
    sum(coal_convert_unprice)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as coal_convert_unprice,                      -- 煤炭折算单价
    sum(coal_convert_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as coal_convert_consumqty,                    -- 煤炭折算耗用量
    water_unprice,                                                                                                                    -- 水单价
    sum(water_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as water_consumqty,                           -- 氧化铝水耗用量
    sum(irex_water_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as irex_water_consumqty,                      -- 提铁水耗用量
    steam_sales_unprice,                                                                                                              -- 蒸汽单价_算毛利
    elect_sales_unprice,                                                                                                              -- 电单价_算毛利
    recovery_condwater_unprice,                                                                                                       -- 回收冷凝水单价
    sum(recovery_condwater_qty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as recovery_condwater_qty,                    -- 回收冷凝水量
    round(sum(labor_cost)
              over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date),
          4)                                                                            as labor_cost,                                -- 人工成本
    round(sum(deprec_exp)
              over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date),
          4)                                                                            as deprec_exp,                                -- 折旧费
    sum(repair_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as repair_exp,                                -- 维修费
    sum(repair_exp_fgsqy)
        over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as repair_exp_fgsqy,                          -- 维修费_分公司区域
    repair_exp_fgs,                                                                                                                   -- 维修费_分公司
    repair_exp_zgs,                                                                                                                   -- 维修费_总公司
    sum(vehicle_oil_usage_qty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as vehicle_oil_usage_qty,                     -- 车辆用油
    vehicle_oil_usage_qty_fgsqy,                                                                                                      -- 车辆用油_分公司区域
    vehicle_oil_usage_qty_fgs,                                                                                                        -- 车辆用油_分公司
    vehicle_oil_usage_qty_zgs,                                                                                                        -- 车辆用油_总公司
    sum(consum_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as consum_exp,                                -- 消耗费用
    consum_exp_fgsqy,                                                                                                                 -- 消耗费用_分公司区域
    consum_exp_fgs,                                                                                                                   -- 消耗费用_分公司
    consum_exp_zgs,                                                                                                                   -- 消耗费用_总公司
    sum(ao_actual_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as ao_actual_prod,                            -- 氧化铝实际产量
    sum(ao_roast_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as ao_roast_prod,                             -- 氧化铝焙烧产量
    sum(ah_exportqty)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as ah_exportqty,                              -- 氢氧化铝外销量
    ifnull(ao_sales_adjust_price, ao_sales_unprice)                                     as ao_sales_unprice,                          -- 氧化铝销售单价
    ifnull(ah_sales_adjust_price, ah_sales_unprice)                                     as ah_sales_unprice,                          -- 氢氧化铝销售单价
    sum(prod_techno_retro_outsource_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as prod_techno_retro_outsource_exp,           -- 生产技改类外委费用
    null                                                                                as prod_techno_retro_outsource_exp_fgsqy,     -- 生产技改类外委费用_分公司区域
    prod_techno_retro_outsource_exp_fgs,                                                                                              -- 生产技改类外委费用_分公司
    null                                                                                as prod_techno_retro_outsource_exp_zgs,       -- 生产技改类外委费用_总公司
    sum(non_prod_techno_retro_outsource_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as non_prod_techno_retro_outsource_exp,       -- 非生产技改类外委费用
    null                                                                                as non_prod_techno_retro_outsource_exp_fgsqy, -- 非生产技改类外委费用_分公司区域
    non_prod_techno_retro_outsource_exp_fgs,                                                                                          -- 非生产技改类外委费用_分公司
    null                                                                                as non_prod_techno_retro_outsource_exp_zgs,   -- 非生产技改类外委费用_总公司
    sum(maint_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as maint_exp,                                 -- 检修费用(互用料折算)
    sum(other_convert_ao)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as other_convert_ao,                          -- 其他折AO
    sum(pack_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as pack_exp,                                  -- 包装费
    sum(common_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as common_exp,                                -- 共享费用
    sum(techno_retro_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as techno_retro_exp,                          -- 技改费用
    null                                                                                as dine_exp,                                  -- 工作餐
    dine_exp_fgs,                                                                                                                     -- 工作餐_分公司
    null                                                                                as scrap_mat_byprod_income,                   -- 副产品_废料&钒饼收入
    null                                                                                as scrap_mat_byprod_income_fgsqy,             -- 副产品_废料&钒饼收入_分公司区域
    scrap_mat_byprod_income_fgs,                                                                                                      -- 副产品_废料&钒饼收入_分公司
    null                                                                                as scrap_mat_byprod_income_zgs,               -- 副产品_废料&钒饼收入_总公司
    sum(irex_maint_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as irex_maint_exp,                            -- 提铁检修费
    sum(process_exp)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as process_exp,                               -- 加工费
    sum(envir_prot_tax_amt)
        over (partition by dt.prod_ym, dt.branch_factory_code order by dt.dt_date)      as envir_prot_tax_amt,                        -- 环保税
    now()                                                                               as etl_time                                   -- ETL更新时间
from
    (
        /*生成每天每个分厂的维度*/
        select
            dt_date,
            dt.prod_ym,
            '氧化铝'          as business_format,
            branch_factory_no as branch_factory_code,
            branch_factory_nm as branch_factory_name,
            company_area_no   as branch_company_area_code,
            company_area_nm   as branch_company_area_name,
            company_no        as branch_company_code,
            company_nm        as branch_company_name,
            module_no         as company_code,
            module_nm         as company_name
        from
            sdhq.dim_prd_date dt
            join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
        where
            dt_date between '2025-11-25' and LEAST('${now_date}', curdate())
        and dt_date >= date_trunc(LEAST('${now_date}', curdate()) - interval if(day(LEAST('${now_date}', curdate())) >= 6, 1, 2) month, 'month') + interval 24 day /*每月6号封版上月数据*/
        ) dt
    left join (
        /*产能、修正价*/
        select
            prod_ym,
            branch_factory_code,
            coal_adjust_price,                                                                         -- 煤炭修正单价
            ao_rated_prod_capacity                                    as ao_rated_prod_capacity_fc,    -- 氧化铝额定产能_分厂
            sum(ao_rated_prod_capacity)
                over (partition by prod_ym, branch_company_area_code) as ao_rated_prod_capacity_fgsqy, -- 氧化铝额定产能_分公司区域
            sum(ao_rated_prod_capacity)
                over (partition by prod_ym, branch_company_code)      as ao_rated_prod_capacity_fgs,   -- 氧化铝额定产能_分公司
            sum(ao_rated_prod_capacity)
                over (partition by prod_ym, company_code)             as ao_rated_prod_capacity_zgs    -- 氧化铝额定产能_总公司
        from
            (
                /*预先汇总*/
                select
                    prod_ym,
                    branch_factory_code,
                    branch_company_area_code,
                    branch_company_code,
                    company_code,
                    sum(ao_rated_prod_capacity) as ao_rated_prod_capacity, -- 氧化铝额定产能
                    sum(coal_adjust_price)      as coal_adjust_price       -- 煤炭修正单价
                from
                    sdhq.dwd_prd_ao_branfact_m_ufd
                group by
                    prod_ym, branch_factory_code, branch_company_area_code,
                    branch_company_code, company_code
                ) cap
        ) capc
        on dt.prod_ym = capc.prod_ym and dt.branch_factory_code = capc.branch_factory_code
    left join (
        /*氧化铝经济指标*/
        select
            dt_date,
            branch_factory_code,
            sum(if(bxt_type = '高温澳矿', bxt_consumqty, 0))      as bxt_consumqty_gwak,                  -- 矿石耗用量_高温奥矿
            sum(if(bxt_type = '低温澳矿', bxt_consumqty, 0))      as bxt_consumqty_dwak,                  -- 矿石耗用量_低温奥矿
            sum(if(bxt_type = '多米尼加矿', bxt_consumqty, 0))    as bxt_consumqty_dmnjk,                 -- 矿石耗用量_多米尼加矿
            sum(if(bxt_type = '几内亚矿', bxt_consumqty, 0))      as bxt_consumqty_jnyk,                  -- 矿石耗用量_几内亚矿
            sum(if(bxt_type = '所罗门矿', bxt_consumqty, 0))      as bxt_consumqty_slmk,                  -- 矿石耗用量_所罗门矿
            sum(if(bxt_type = '几内亚矿(CBG)', bxt_consumqty, 0)) as bxt_consumqty_jnykcbg,               -- 矿石耗用量_几内亚矿(CBG)
            sum(if(bxt_type = '牙买加矿', bxt_consumqty, 0))      as bxt_consumqty_ymjk,                  -- 矿石耗用量_牙买加矿
            sum(lowpres_steam_consumqty)                          as lowpres_steam_consumqty,             --  低压蒸汽耗用量
            sum(highpres_steam_consumqty)                         as highpres_steam_consumqty,            -- 高压蒸汽耗用量
            sum(ao_elect_consumqty)                               as ao_elect_consumqty,                  --  氧化铝电耗用量
            sum(irex_elect_consumqty)                             as irex_elect_consumqty,                --  提铁电耗用量
            sum(cokegas_consumqty)                                as cokegas_consumqty,                   -- 焦化煤气耗用量
            sum(natgas_consumqty)                                 as natgas_consumqty,                    --  天然气耗用量
            sum(liqcaus_consumqty)                                as liqcaus_consumqty,                   -- 液碱耗用量
            sum(lime_consumqty)                                   as lime_consumqty,                      -- 石灰耗用量
            sum(floc_consumqty)                                   as floc_consumqty,                      -- 絮凝剂耗用量
            sum(coal_consumqty)                                   as coal_consumqty,                      -- 煤炭耗用量
            sum(coal_convert_unprice)                             as coal_convert_unprice,                -- 煤炭折算单价
            sum(coal_convert_consumqty)                           as coal_convert_consumqty,              -- 煤炭折算耗用量
            sum(water_consumqty)                                  as water_consumqty,                     -- 氧化铝水耗用量
            sum(irex_water_consumqty)                             as irex_water_consumqty,                -- 提铁水耗用量
            sum(recovery_condwater_qty)                           as recovery_condwater_qty,              -- 回收冷凝水量
            sum(labor_cost)                                       as labor_cost,                          -- 人工成本
            sum(deprec_exp)                                       as deprec_exp,                          -- 折旧费
            sum(maint_exp)                                        as maint_exp,                           -- 检修费用(互用料折算)
            sum(other_convert_ao)                                 as other_convert_ao,                    -- 其他折AO
            sum(ao_actual_prod)                                   as ao_actual_prod,                      -- 氧化铝实际产量
            sum(ao_roast_prod)                                    as ao_roast_prod,                       -- 氧化铝焙烧产量
            sum(common_exp)                                       as common_exp,                          -- 共享费用
            sum(techno_retro_exp)                                 as techno_retro_exp,                    -- 技改费用
            sum(ah_exportqty)                                     as ah_exportqty,                        -- 氢氧化铝外销量
            sum(irex_maint_exp)                                   as irex_maint_exp,                      -- 提铁检修费
            sum(prod_techno_retro_outsource_exp)                  as prod_techno_retro_outsource_exp,     -- 生产技改类外委费用
            sum(non_prod_techno_retro_outsource_exp)              as non_prod_techno_retro_outsource_exp, -- 非生产技改类外委费用
            sum(process_exp)                                      as process_exp,                         -- 加工费
            sum(envir_prot_tax_amt)                               as envir_prot_tax_amt,                  -- 环保税
            sum(ao_plan_prod)                                     as ao_plan_prod,                        -- 氧化铝计划产量
            sum(fe_plan_prod)                                     as fe_plan_prod,                        -- 铁粉计划产量
            1
        from
            sdhq.dwd_prd_ao_fact_d_ufd
        group by dt_date, branch_factory_code
        ) fd on dt.dt_date = fd.dt_date and dt.branch_factory_code = fd.branch_factory_code
    left join (
        /*液碱、石灰*/
        select
            date(ck.x_date)                             as dt_date,
            org.branch_factory_no,
            sum(if(ck.type = '液碱', ck.x_ckje * 1, 0)) as liqcaus_disp_amt,    -- 液碱出库金额
            sum(if(ck.type = '液碱', ck.x_yfje * 1, 0)) as liqcaus_freight_amt, --  液碱运费金额
            sum(if(ck.type = '石灰', ck.x_ckje * 1, 0)) as lime_consum_amt      --  石灰耗用金额
        from
            (
                select
                    x_date,
                    x_lybm,
                    '液碱' as type,
                    x_ckje,
                    x_yfje
                from
                    sdhq.ods_mms_yjcksjb_ufd ck
                union all
                select
                    x_date,
                    x_lybm,
                    '石灰' as type,
                    x_ckje,
                    x_yfje
                from
                    sdhq.ods_mms_shcksjb_ufd ck
                ) ck
            left join sdhq.dim_org_dept_ufd dep
                on ck.x_lybm = dep.dept_code and dep.source_system = 'ncc'
            left join sdhq.dim_prd_org_flatten_ufd org
                on dep.cost_acctg_dept_code = org.branch_factory_no
        where
              x_date >= '2025-11-25'
          and org.branch_factory_no is not null
        group by date(ck.x_date), org.branch_factory_no
        ) yj on dt.dt_date = yj.dt_date and dt.branch_factory_code = yj.branch_factory_no
    left join (
        /*NCC出库费用_分厂*/
        select
            dt_date,
            org_code as branch_factory_no,
            pack_exp,                  -- 包装费
            consum_exp,                -- 消耗费用
            desulf_raw_mat_consumqty,  -- 脱硫原材料耗用量
            desulf_raw_mat_consum_amt, -- 脱硫原材料金额
            other_raw_mat_consumqty,   -- 其他原材料耗用量
            other_raw_mat_consum_amt,  -- 其他原材料金额
            vehicle_oil_usage_qty,     -- 车辆用油
            repair_exp,                -- 维修费
            floc_consum_amt            -- 絮凝剂耗用金额
        from
            sdhq.v_dwd_prd_ao_ncc_ck a
        where
            a.org_code in (
                select
                    branch_factory_no
                from
                    sdhq.dim_prd_org_flatten_ufd
                where
                    module_nm = '氧化铝公司'
                ) /*过滤分厂*/
        ) ncc on dt.dt_date = ncc.dt_date and dt.branch_factory_code = ncc.branch_factory_no
    left join (
        /*单价*/
        select
            prod_ym,
            company_code,
            sum(if(bxt_type = '高温澳矿', bxt_unprice, 0))      as bxt_unprice_gwak,             -- 矿石单价_高温澳矿
            sum(if(bxt_type = '低温澳矿', bxt_unprice, 0))      as bxt_unprice_dwak,             -- 矿石单价_低温澳矿
            sum(if(bxt_type = '多米尼加矿', bxt_unprice, 0))    as bxt_unprice_dmnjk,            -- 矿石单价_多米尼加矿
            sum(if(bxt_type = '几内亚矿', bxt_unprice, 0))      as bxt_unprice_jnyk,             -- 矿石单价_几内亚矿
            sum(if(bxt_type = '所罗门矿', bxt_unprice, 0))      as bxt_unprice_slmk,             -- 矿石单价_所罗门矿
            sum(if(bxt_type = '几内亚矿(CBG)', bxt_unprice, 0)) as bxt_unprice_jnykcbg,          -- 矿石单价_几内亚矿(CBG)
            sum(if(bxt_type = '牙买加矿', bxt_unprice, 0))      as bxt_unprice_ymjk,             -- 矿石单价_牙买加矿
            sum(lowpres_steam_unprice)                          as lowpres_steam_unprice,        -- 低压蒸汽单价
            sum(highpres_steam_unprice)                         as highpres_steam_unprice,       --  高压蒸汽单价
            sum(elect_unprice)                                  as elect_unprice,                --  电单价
            sum(water_unprice)                                  as water_unprice,                -- 水单价
            sum(steam_sales_unprice)                            as steam_sales_unprice,          -- 蒸汽单价_算毛利
            sum(elect_sales_unprice)                            as elect_sales_unprice,          -- 电单价_算毛利
            sum(recovery_condwater_unprice)                     as recovery_condwater_unprice,   -- 回收冷凝水单价
            sum(ah_sales_unprice)                               as ah_sales_unprice,             -- 氢氧化铝销售单价
            sum(ao_sales_unprice)                               as ao_sales_unprice,             -- 氧化铝销售单价
            sum(ah_sales_adjust_price)                          as ah_sales_adjust_price,        -- 氢氧化铝销售修正单价
            sum(ao_sales_adjust_price)                          as ao_sales_adjust_price,        -- 氧化铝销售修正单价
            1
        from
            sdhq.dwd_prd_ao_mat_unprice_m_ufd
        group by prod_ym, company_code
        ) dj on dt.prod_ym = dj.prod_ym and dt.company_code = dj.company_code
    left join (
        /*煤炭单价*/
        select
            dt.prod_ym,
            org.branch_factory_no,
            sum(settlement_amt) / sum(settlement_qty) as coal_unprice -- 煤炭单价
        from
            (
                select
                    date(a.business_tab_doc_dt)                                   as ddate,
                    case a.require_whouse_name
                        when '北海燃气三厂' then 'SDHQ_YHLGS_0502'
                        when '北海燃气四厂' then 'SDHQ_YHLGS_0503'
                        when '北海燃气一厂' then 'SDHQ_YHLGS_0402'
                        when '北海燃气二厂' then 'SDHQ_YHLGS_0403'
                        when '沾化汇宏粉煤灰一厂' then 'SDHQ_YHLGS_0202'
                        when '汇茂氧三燃气站' then 'SDHQ_YHLGS_0302'
                        when '沾化汇宏粉煤灰二厂' then 'SDHQ_YHLGS_0203'
                        when '沾化氧一燃气站' then 'SDHQ_YHLGS_0102'
                        end                                                       as branch_factory_code,
                    ifnull(settlement_amt, 0) + ifnull(freight_settlement_amt, 0) as settlement_amt,
                    settlement_qty
                from
                    sdhq.dwd_pur_info_rec_hqmt_ufd a
                ) a
            left join sdhq.dim_prd_date dt on a.ddate = dt.dt_date
            left join sdhq.dim_prd_org_flatten_ufd org
                on a.branch_factory_code = org.branch_factory_no
        where
            a.branch_factory_code is not null
        group by prod_ym, org.branch_factory_no
        ) mtdj on dt.prod_ym = mtdj.prod_ym and dt.branch_factory_code = mtdj.branch_factory_no
    left join (
        /*分公司*/
        select
            dt.dt_date,
            dt.branch_company_code,
            sum(consum_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as consum_exp_fgs,                          -- 消耗费用_分公司
            sum(desulf_raw_mat_consum_amt_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as desulf_raw_mat_consum_amt_fgs,           -- 脱硫原材料金额_分公司
            sum(other_raw_mat_consum_amt_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as other_raw_mat_consum_amt_fgs,            -- 其他原材料金额_分公司
            sum(vehicle_oil_usage_qty_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as vehicle_oil_usage_qty_fgs,               -- 车辆用油_分公司
            sum(repair_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as repair_exp_fgs,                          -- 维修费_分公司
            sum(scrap_mat_byprod_income_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as scrap_mat_byprod_income_fgs,             -- 副产品_废料&钒饼收入_分公司
            sum(dine_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as dine_exp_fgs,                            -- 工作餐_分公司
            sum(prod_techno_retro_outsource_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as prod_techno_retro_outsource_exp_fgs,     -- 生产技改类外委费用_分公司
            sum(non_prod_techno_retro_outsource_exp_fgs)
                over (partition by dt.prod_ym, dt.branch_company_code order by dt.dt_date) as non_prod_techno_retro_outsource_exp_fgs, -- 非生产技改类外委费用_分公司
            1
        from
            (
                /*生成每天每个分公司的维度*/
                select distinct
                    dt_date,
                    dt.prod_ym,
                    company_no as branch_company_code
                from
                    sdhq.dim_prd_date dt
                    join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
                where
                    dt_date between '2025-11-25' and curdate()
                order by dt.dt_date, org.company_no
                ) dt
            left join (
                /*NCC出库费用_分公司*/
                select
                    dt_date,
                    org_code                  as branch_company_code,
                    consum_exp                as consum_exp_fgs,                -- 消耗费用_分公司
                    desulf_raw_mat_consum_amt as desulf_raw_mat_consum_amt_fgs, -- 脱硫原材料金额_分公司
                    other_raw_mat_consum_amt  as other_raw_mat_consum_amt_fgs,  -- 其他原材料金额_分公司
                    vehicle_oil_usage_qty     as vehicle_oil_usage_qty_fgs,     -- 车辆用油_分公司
                    repair_exp                as repair_exp_fgs                 -- 维修费_分公司
                from
                    sdhq.v_dwd_prd_ao_ncc_ck a
                where
                    a.org_code in (
                        select distinct
                            company_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                            module_nm = '氧化铝公司'
                        ) /*过滤分公司*/
                ) exp_fgs on dt.dt_date = exp_fgs.dt_date and
                             dt.branch_company_code = exp_fgs.branch_company_code
            left join (
                /*副产品_废料&钒饼收入_分公司、工作餐_分公司*/
                select
                    a.dt_date,
                    dt.prod_ym,
                    branch_company_code,
                    sum(scrap_mat_byprod_income) as scrap_mat_byprod_income_fgs, -- 副产品_废料&钒饼收入_分公司
                    sum(dine_exp)                as dine_exp_fgs                 -- 工作餐_分公司
                from
                    sdhq.dwd_prd_ao_branch_company_d_ufd a
                    left join sdhq.dim_prd_date dt on a.dt_date = dt.dt_date
                where
                    a.dt_date >= '2025-11-25'
                group by a.dt_date, dt.prod_ym, branch_company_code
                ) brancom
                on dt.dt_date = brancom.dt_date and
                   dt.branch_company_code = brancom.branch_company_code
            left join (
                /*技改类外委费用-分公司*/
                select
                    a.dt_date,
                    branch_factory_code                      as branch_company_code,
                    sum(prod_techno_retro_outsource_exp)     as prod_techno_retro_outsource_exp_fgs,    -- 生产技改类外委费用_分公司
                    sum(non_prod_techno_retro_outsource_exp) as non_prod_techno_retro_outsource_exp_fgs -- 非生产技改类外委费用_分公司
                from
                    sdhq.dwd_prd_ao_fact_d_ufd a
                    left join sdhq.dim_prd_date dt on a.dt_date = dt.dt_date
                where
                      (prod_techno_retro_outsource_exp > 0 or
                       non_prod_techno_retro_outsource_exp > 0)
                  and a.branch_factory_code in (
                    select distinct
                        company_no
                    from
                        sdhq.dim_prd_org_flatten_ufd
                    where
                        module_nm = '氧化铝公司'
                    )
                group by a.dt_date, branch_factory_code
                ) wwfy_fgs
                on dt.dt_date = wwfy_fgs.dt_date and
                   dt.branch_company_code = wwfy_fgs.branch_company_code
        ) dtfgs on dt.dt_date = dtfgs.dt_date and dt.branch_company_code = dtfgs.branch_company_code
    left join (
        /*分公司区域*/
        select
            dt.dt_date,
            dt.branch_company_area_code,
            sum(consum_exp_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as consum_exp_fgsqy,                -- 消耗费用_分公司区域
            sum(desulf_raw_mat_consum_amt_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as desulf_raw_mat_consum_amt_fgsqy, -- 脱硫原材料金额_分公司区域
            sum(other_raw_mat_consum_amt_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as other_raw_mat_consum_amt_fgsqy,  -- 其他原材料金额_分公司区域
            sum(vehicle_oil_usage_qty_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as vehicle_oil_usage_qty_fgsqy,     -- 车辆用油_分公司区域
            sum(repair_exp_fgsqy)
                over (partition by dt.prod_ym, dt.branch_company_area_code order by dt.dt_date) as repair_exp_fgsqy,                -- 维修费_分公司区域
            1
        from
            (
                /*生成每天每个分公司区域的维度*/
                select distinct
                    dt_date,
                    dt.prod_ym,
                    company_area_no as branch_company_area_code
                from
                    sdhq.dim_prd_date dt
                    join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
                where
                      dt_date between '2025-11-25' and curdate()
                  and company_area_no is not null
                ) dt
            left join (
                /*NCC出库费用_分公司区域*/
                select
                    dt_date,
                    org_code                  as branch_company_area_code,
                    consum_exp                as consum_exp_fgsqy,                -- 消耗费用_分公司区域
                    desulf_raw_mat_consum_amt as desulf_raw_mat_consum_amt_fgsqy, -- 脱硫原材料金额_分公司区域
                    other_raw_mat_consum_amt  as other_raw_mat_consum_amt_fgsqy,  -- 其他原材料金额_分公司区域
                    vehicle_oil_usage_qty     as vehicle_oil_usage_qty_fgsqy,     -- 车辆用油_分公司区域
                    repair_exp                as repair_exp_fgsqy                 -- 维修费_分公司区域
                from
                    sdhq.v_dwd_prd_ao_ncc_ck a
                where
                    org_code in (
                        select distinct
                            company_area_no
                        from
                            sdhq.dim_prd_org_flatten_ufd
                        where
                              module_nm = '氧化铝公司'
                          and company_area_no is not null
                        ) /*过滤分公司区域*/
                ) exp_fgsqy on dt.dt_date = exp_fgsqy.dt_date and
                               dt.branch_company_area_code = exp_fgsqy.branch_company_area_code
        ) dtfgsqy
        on dt.dt_date = dtfgsqy.dt_date and
           dt.branch_company_code = dtfgsqy.branch_company_area_code
    left join (
        /*总公司*/
        select
            dt.dt_date,
            dt.company_code,
            sum(consum_exp_zgs)
                over (partition by dt.prod_ym, dt.company_code order by dt.dt_date) as consum_exp_zgs,                -- 消耗费用_总公司
            sum(desulf_raw_mat_consum_amt_zgs)
                over (partition by dt.prod_ym, dt.company_code order by dt.dt_date) as desulf_raw_mat_consum_amt_zgs, -- 脱硫原材料金额_总公司
            sum(other_raw_mat_consum_amt_zgs)
                over (partition by dt.prod_ym, dt.company_code order by dt.dt_date) as other_raw_mat_consum_amt_zgs,  -- 其他原材料金额_总公司
            sum(vehicle_oil_usage_qty_zgs)
                over (partition by dt.prod_ym, dt.company_code order by dt.dt_date) as vehicle_oil_usage_qty_zgs,     -- 车辆用油_总公司
            sum(repair_exp_zgs)
                over (partition by dt.prod_ym, dt.company_code order by dt.dt_date) as repair_exp_zgs,                -- 维修费_总公司
            1
        from
            (
                /*生成每天每个分公司区域的维度*/
                select
                    dt_date,
                    dt.prod_ym,
                    'SDHQ_YHLGS' as company_code
                from
                    sdhq.dim_prd_date dt
                where
                    dt_date between '2025-11-25' and curdate()
                ) dt
            left join (
                /*NCC出库费用_总公司*/
                select
                    dt_date,
                    org_code                  as company_code,
                    consum_exp                as consum_exp_zgs,                -- 消耗费用_总公司
                    desulf_raw_mat_consum_amt as desulf_raw_mat_consum_amt_zgs, -- 脱硫原材料金额_总公司
                    other_raw_mat_consum_amt  as other_raw_mat_consum_amt_zgs,  -- 其他原材料金额_总公司
                    vehicle_oil_usage_qty     as vehicle_oil_usage_qty_zgs,     -- 车辆用油_总公司
                    repair_exp                as repair_exp_zgs                 -- 维修费_总公司
                from
                    sdhq.v_dwd_prd_ao_ncc_ck a
                where
                    org_code = 'SDHQ_YHLGS' /*过滤公司*/
                ) exp_zgs
                on dt.dt_date = exp_zgs.dt_date and dt.company_code = exp_zgs.company_code
        ) dtzgs on dt.dt_date = dtzgs.dt_date and dt.company_code = dtzgs.company_code
;