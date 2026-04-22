/*
 -- 描述：电解铝分公司区域日指标
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：1、废旧物资及副产品不含税销售额 2、工作餐 3、铝锭产量、铝母线产量、脱硫用水耗用量
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
truncate table sdhq.dwd_prd_al_brancom_area_d_ufd;

/*废旧物资及副产品不含税销售额*/
insert into
    sdhq.dwd_prd_al_brancom_area_d_ufd
    (id, dt_date, business_format, branch_company_area_code, branch_company_area_name,
     scrap_mat_byprod_nontax_sales_amt, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                as id,
    dt.dt_date                            as dt_date,
    '电解铝'                              as business_format,
    area.areacode                         as branch_company_area_code,
    org.company_area_nm                   as branch_company_area_name,
    Amount                                as scrap_mat_byprod_nontax_sales_amt, -- 废旧物资及副产品不含税销售额
    'hqsms'                               as source_system,
    'sales.CoProduct.CoProductOutStorage' as source_table_name,
    CoProductOutStorage_GUID              as source_id,
    now()                                 as etl_time
from
    sdhq.ods_hqsms_coproductoutstorage_ufd a
    left join sdhq.dim_prd_date dt on date(a.OutStorageDate) = dt.dt_date
    inner join (
        /**/
        select
            areacode_guid,
            areadescription,
            case areadescription
                when '铝业三分公司' then 'SDHQ_LYGS_ZPQY_02'
                when '铝业一分公司（魏桥）' then 'SDHQ_LYGS_WQQY_01'
                end as areacode
        from
            sdhq.ods_hqsms_areacode_ufd
        where
            AreaDescription in ('铝业三分公司', '铝业一分公司（魏桥）')
        ) area
        on a.areacode_guid = area.areacode_guid
    left join (
        select distinct company_area_no, company_area_nm from sdhq.dim_prd_org_flatten_ufd
        ) org on area.areacode = org.company_area_no
where
      a.delflag = 0
  and a.OutStorageDate >= '2025-11-25'
;
/*工作餐*/
insert into
    sdhq.dwd_prd_al_brancom_area_d_ufd
    (id, dt_date, business_format, branch_company_area_code, branch_company_area_name, dine_exp,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                 as id,
    ddate                                  as dt_date,
    '电解铝'                               as business_format,
    org.company_area_no                    as branch_company_area_code,
    org.company_area_nm                    as branch_company_area_name,
    t.subtotal                             as dine_exp, --  工作餐
    'hqbpm'                                as source_system,
    'BPMDATA.dbo.LDXGB_CanteenReception_B' as source_table_name,
    t.ID                                   as source_id,
    now()                                  as etl_time
from
    (
        select
            b.ID,
            str_to_date(replace(replace(ReceptionDate, '/', '-'), '.', '-'), 'yyyy-MM-dd') as ddate,
            case h.company
                when '铝业三分公司' then 'SDHQ_LYGS_ZPQY_02'
                when '铝业三分公司（魏桥侧）' then 'SDHQ_LYGS_WQQY_01'
                end                                                                        as company_code,
            ReceptionSubtotal * 1                                                          as subtotal
        from
            sdhq.ods_hqbpm_ldxgb_canteenreception_b_ufd b
            left join sdhq.ods_hqbpm_ldxgb_canteenreception_h_ufd h on b.taskid = h.taskid
        WHERE
              b.CBType = '计成本'
          AND h.company in ('铝业三分公司', '铝业三分公司（魏桥侧）')-- 公司名称条件（假设在h表）
        ) t
    inner join (
        select distinct
            company_area_no,
            company_area_nm
        from
            sdhq.dim_prd_org_flatten_ufd
        ) org
        on t.company_code = org.company_area_no
where
    ddate >= '2025-11-25'
;
/*铝锭产量、铝母线产量、脱硫用水耗用量*/
insert into
    sdhq.dwd_prd_al_brancom_area_d_ufd
    (id, dt_date, business_format, branch_company_area_code, branch_company_area_name,
     alumingot_prod, alumbusbar_prod, desulf_wateruse_consumqty, source_system, source_table_name,
     source_id, etl_time)
select
    uuid()                                                  as id,
    metric_time                                             as dt_date,
    '电解铝'                                                as business_format,
    case a.al_factory_no
        when 'SDHQ_LYGS_0305' then 'SDHQ_LYGS_ZPQY_02'
        when 'SDHQ_LYGS_0309' then 'SDHQ_LYGS_WQQY_01' end  as branch_company_area_code,  -- 分公司编码
    case a.al_factory_no
        when 'SDHQ_LYGS_0305' then '铝业三公司邹平区域'
        when 'SDHQ_LYGS_0309' then '铝业三公司魏桥区域' end as branch_company_area_name,  -- 分公司名称
    Prd_AL_Rece_Qty_AlumIngot_Whouse_D                      as alumingot_prod,            -- 铝锭产量
    Prd_AL_Rece_Qty_AlumBusbar_Whouse_D                     as alumbusbar_prod,           -- 铝母线产量
    Prd_AL_Qty_Desulf_Water_D                               as desulf_wateruse_consumqty, -- 脱硫用水耗用量
    'aloudatacan'                                           as source_system,             -- 来源系统
    'sdhq_prd_al_psales_energy_consum'                      as source_table_name,         -- 来源表名
    concat(metric_time, al_factory_no)                      as source_id,                 -- 来源ID
    now()                                                   as etl_time
from
    aloudatacan.sdhq_prd_al_psales_energy_consum a
where
    al_company_no = 'SDHQ_LYGS_03'
;
;