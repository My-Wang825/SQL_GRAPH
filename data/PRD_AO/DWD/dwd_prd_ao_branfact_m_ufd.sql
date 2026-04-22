/**/
truncate table sdhq.dwd_prd_ao_branfact_m_ufd;

/*氧化铝额定产能*/
insert into
    sdhq.dwd_prd_ao_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_code, branch_factory_name,
     branch_company_area_code, branch_company_area_name, branch_company_code, branch_company_name,
     company_name, company_code, ao_rated_prod_capacity, source_system, source_table_name,
     source_id, etl_time)
select
    uuid()                                    as id,
    mth                                       as prod_ym,
    vdt.last_day                              as prod_ym_last_day,
    '氧化铝'                                  as business_format,
    branch_no                                 as branch_company_code,
    org.branch_factory_nm                     as branch_company_name,
    org.company_area_no                       as branch_company_area_code,
    org.company_area_nm                       as branch_company_area_name,
    org.company_no                            as branch_company_code,
    org.company_nm                            as branch_company_name,
    org.module_nm                             as company_name,
    org.module_no                             as company_code,
    ao_rated_prod                             as ao_rated_prod_capacity, -- 氧化铝额定产能
    'fryw'                                    as source_system,
    'dw_centor_report.yhl_fill_ao_rated_prod' as source_table_name,
    concat(mth, branch_no)                    as source_id,
    now()                                     as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_rated_prod_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;
/*煤炭修正单价*/
insert into
    sdhq.dwd_prd_ao_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_code, branch_factory_name,
     branch_company_area_code, branch_company_area_name, branch_company_code, branch_company_name,
     company_name, company_code, coal_adjust_price, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                        as id,
    mth                                           as prod_ym,
    vdt.last_day                                  as prod_ym_last_day,
    '氧化铝'                                      as business_format,
    branch_no                                     as branch_factory_code,
    branch_nm                                     as branch_factory_name,
    org.company_area_no                           as branch_company_area_code,
    org.company_area_nm                           as branch_company_area_name,
    org.company_no                                as branch_company_code,
    org.company_nm                                as branch_company_name,
    org.module_nm                                 as company_name,
    org.module_no                                 as company_code,
    coal_price                                    as coal_adjust_price, -- 煤炭修正单价
    'fryw'                                        as source_system,
    'dw_centor_report.yhl_fill_unit_price_adjust' as source_table_name,
    concat(mth, branch_no)                        as source_id,
    now()                                         as etl_time
from
    sdhq.ods_fryw_yhl_fill_ao_unit_price_adjust_ufd a
    left join sdhq.dim_prd_org_flatten_ufd org on a.branch_no = org.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
where
    coal_price is not null
;
/*减排单价*/
insert into
    sdhq.dwd_prd_ao_branfact_m_ufd
    (id, prod_ym, prod_ym_last_day, business_format, branch_factory_code, branch_factory_name,
     branch_company_code,
     branch_company_name, branch_company_area_code, branch_company_area_name, company_code,
     company_name, emission_reduc_unprice, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                     as id,
    mth                                        as prod_ym,
    vdt.last_day                               as prod_ym_last_day,
    '氧化铝'                                   as business_format,
    org3.branch_factory_no                     as branch_company_code,
    org3.branch_factory_nm                     as branch_factory_name,
    org3.company_no                            as branch_company_code,
    org3.company_nm                            as branch_company_name,
    org3.company_area_no                       as branch_company_area_code,
    org3.company_area_nm                       as branch_company_area_name,
    org3.module_no                             as company_code,
    org3.module_nm                             as company_name,
    irex_abate_exp                             as emission_reduc_unprice, -- 减排单价
    'fryw'                                     as source_system,
    'dw_centor_report.yhl_fill_irex_abate_exp' as source_table_name,
    concat(mth, legal_entity_no)               as source_id,
    now()                                      as etl_time
from
    sdhq.ods_fryw_yhl_fill_irex_abate_exp_uid a
    left join sdhq.dim_prd_org_ufd org on a.legal_entity_no = org.org_code
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
    left join sdhq.dim_prd_org_flatten_ufd org3 on org2.org_code = org3.branch_factory_no
    left join sdhq.v_prd_ym_date vdt on a.mth = vdt.prod_ym
;