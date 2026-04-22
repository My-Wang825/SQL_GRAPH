/**/
truncate table sdhq.ads_prd_ao_waterbxt_consum_udf;

/*矿石耗用*/
insert into
    sdhq.ads_prd_ao_waterbxt_consum_udf
    (dt_date, prod_ym, branch_factory_code, consum_type, branch_factory_name, branch_company_code,
     branch_company_name, business_format, bxt_type, bxt_consumqty, bxt_unprice, etl_time)
select
    dt.dt_date                                                                                  as dt_date,
    dt.prod_ym                                                                                  as prod_ym,
    dt.branch_factory_code,
    '矿石'                                                                                      as consum_type,
    dt.branch_factory_name,
    dt.branch_company_code,
    dt.branch_company_name,
    dt.business_format                                                                          as business_format,
    dt.bxt_type                                                                                 as bxt_type,
    sum(bxt_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code, dt.bxt_type order by dt.dt_date) as bxt_consumqty,
    b.bxt_unprice                                                                               as bxt_unprice,
    now()                                                                                       as etl_time
from
    (
        /*生成每天每个分厂每个矿石类型的数据*/
        select
            dt_date,
            prod_ym,
            '氧化铝'          as business_format,
            branch_factory_no as branch_factory_code,
            branch_factory_nm as branch_factory_name,
            company_no        as branch_company_code,
            company_nm        as branch_company_name,
            bxt_type          as bxt_type
        from
            sdhq.dim_prd_date
            join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
            join (
                select distinct bxt_type from sdhq.dwd_prd_ao_fact_d_ufd where bxt_type != ''
                ) bxt_type on 1 = 1
        where
            dt_date between '2025-11-25' and curdate()
        ) dt
    left join
        (
            /*先汇总*/
            select
                dt_date,
                branch_factory_code,
                bxt_type,
                sum(bxt_consumqty) as bxt_consumqty
            from
                sdhq.dwd_prd_ao_fact_d_ufd
            where
                bxt_type != ''
            group by
                dt_date, branch_factory_code, bxt_type
            ) a on a.dt_date = dt.dt_date and dt.branch_factory_code = a.branch_factory_code and
                   dt.bxt_type = a.bxt_type
    left join sdhq.dwd_prd_ao_mat_unprice_m_ufd b
        on dt.prod_ym = b.prod_ym and b.bxt_unprice is not null and dt.bxt_type = b.bxt_type
;
/*水耗用*/
insert into
    sdhq.ads_prd_ao_waterbxt_consum_udf
    (dt_date, prod_ym, branch_factory_code, consum_type, branch_factory_name, branch_company_code,
     branch_company_name, business_format, water_type, water_consumqty, irex_water_consumqty,
     water_unprice, etl_time)
select
    dt.dt_date                                                                                    as dt_date,
    dt.prod_ym                                                                                    as prod_ym,
    dt.branch_factory_code,
    '水'                                                                                          as consum_type,
    dt.branch_factory_name,
    dt.branch_company_code,
    dt.branch_company_name,
    dt.business_format                                                                            as business_format,
    dt.water_type                                                                                 as bxt_type,
    sum(water_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code, dt.water_type order by dt.dt_date) as water_consumqty,      -- 氧化铝水耗用量
    sum(irex_water_consumqty)
        over (partition by dt.prod_ym, dt.branch_factory_code, dt.water_type order by dt.dt_date) as irex_water_consumqty, -- 提铁水耗用量
    b.water_unprice                                                                               as water_unprice,
    now()                                                                                         as etl_time
from
    (
        /*生成每天每个分厂每个水类型的数据*/
        select
            dt_date,
            prod_ym,
            '氧化铝'          as business_format,
            branch_factory_no as branch_factory_code,
            branch_factory_nm as branch_factory_name,
            company_no        as branch_company_code,
            company_nm        as branch_company_name,
            water_type        as water_type
        from
            sdhq.dim_prd_date
            join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
            join (
                select distinct
                    water_type
                from
                    sdhq.dwd_prd_ao_fact_d_ufd
                where
                    water_type != ''
                ) water_type on 1 = 1
        where
            dt_date between '2025-11-25' and curdate()
        ) dt
    left join
        (
            /*先汇总*/
            select
                dt_date,
                branch_factory_code,
                water_type,
                sum(water_consumqty)      as water_consumqty,
                sum(irex_water_consumqty) as irex_water_consumqty
            from
                sdhq.dwd_prd_ao_fact_d_ufd
            where
                water_type != ''
            group by
                dt_date, branch_factory_code, water_type
            ) a on a.dt_date = dt.dt_date and dt.branch_factory_code = a.branch_factory_code and
                   dt.water_type = a.water_type
    left join sdhq.dwd_prd_ao_mat_unprice_m_ufd b
        on dt.prod_ym = b.prod_ym and b.water_unprice is not null and dt.water_type = b.water_type
;
/*铁粉*/
insert into
    sdhq.ads_prd_ao_waterbxt_consum_udf
    (dt_date, prod_ym, branch_factory_code, consum_type, branch_factory_name, branch_company_code,
     branch_company_name, business_format, fe_type, fe_prod, fe_sales_unprice,
     emission_reduc_unprice, etl_time)
select
    dt.dt_date                                                                                 as dt_date,
    dt.prod_ym                                                                                 as prod_ym,
    dt.branch_factory_code,
    '铁粉'                                                                                     as consum_type,
    dt.branch_factory_name,
    dt.branch_company_code,
    dt.branch_company_name,
    dt.business_format                                                                         as business_format,
    dt.fe_type                                                                                 as fe_type,
    sum(fe_prod)
        over (partition by dt.prod_ym, dt.branch_factory_code, dt.fe_type order by dt.dt_date) as fe_prod,
    ifnull(b.iron_sales_adjust_price, b.fe_sales_unprice)                                      as fe_sales_unprice, -- 铁粉销售单价
    reduc.emission_reduc_unprice,                                                                                   -- 减排单价
    now()                                                                                      as etl_time
from
    (
        /*生成每天每个分厂每个铁粉类型的数据*/
        select
            dt_date,
            prod_ym,
            '氧化铝'          as business_format,
            branch_factory_no as branch_factory_code,
            branch_factory_nm as branch_factory_name,
            company_no        as branch_company_code,
            company_nm        as branch_company_name,
            fe_type           as fe_type
        from
            sdhq.dim_prd_date
            join sdhq.dim_prd_org_flatten_ufd org on org.module_nm = '氧化铝公司'
            join (
                select distinct
                    fe_type
                from
                    sdhq.dwd_prd_ao_fact_d_ufd
                where
                    fe_type != ''
                ) fe_type on 1 = 1
        where
            dt_date between '2025-11-25' and curdate()
        ) dt
    left join
        (
            /*先汇总*/
            select
                dt_date,
                branch_factory_code,
                fe_type,
                sum(fe_prod) as fe_prod
            from
                sdhq.dwd_prd_ao_fact_d_ufd
            where
                fe_type != ''
            group by
                dt_date, branch_factory_code, fe_type
            ) a on a.dt_date = dt.dt_date and dt.branch_factory_code = a.branch_factory_code and
                   dt.fe_type = a.fe_type
    left join (
        /*先汇总*/
        select
            prod_ym,
            branch_factory_code,
            emission_reduc_unprice -- 减排单价
        from
            sdhq.dwd_prd_ao_branfact_m_ufd
        where
            emission_reduc_unprice is not null
        ) reduc on dt.prod_ym = reduc.prod_ym and dt.branch_factory_code = reduc.branch_factory_code
    left join sdhq.dwd_prd_ao_mat_unprice_m_ufd b
        on ifnull(b.iron_sales_adjust_price, b.fe_sales_unprice) is not null and
           dt.prod_ym = b.prod_ym and dt.fe_type = b.fe_type
;