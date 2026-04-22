/*
 -- 描述：电解铝分公司日指标
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：1、铝锭产量、铝母线产量、脱硫用水耗用量 2、废旧物资及副产品不含税销售额 3、工作餐
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

truncate table sdhq.dwd_prd_al_branch_company_d_ufd;

/*铝锭产量、铝母线产量、脱硫用水耗用量*/
insert into
    sdhq.dwd_prd_al_branch_company_d_ufd
    (id, dt_date, business_format, branch_company_code, branch_company_name, alumingot_prod,
     alumbusbar_prod, desulf_wateruse_consumqty, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                              as id,
    metric_time                         as dt_date,
    '电解铝'                            as business_format,
    org.org_code                        as branch_company_code,       -- 分公司编码
    org.org_name                        as branch_company_name,       -- 分公司名称
    Prd_AL_Rece_Qty_AlumIngot_Whouse_D  as alumingot_prod,            -- 铝锭产量
    Prd_AL_Rece_Qty_AlumBusbar_Whouse_D as alumbusbar_prod,           -- 铝母线产量
    Prd_AL_Qty_Desulf_Water_D           as desulf_wateruse_consumqty, -- 脱硫用水耗用量
    'aloudatacan'                       as source_system,             -- 来源系统
    'sdhq_prd_al_psales_energy_consum'  as source_table_name,         -- 来源表名
    concat(metric_time, al_factory_no)  as source_id,                 -- 来源ID
    now()                               as etl_time
from
    aloudatacan.sdhq_prd_al_psales_energy_consum a
    left join sdhq.dim_prd_org_ufd org on a.al_company_no = org.org_code
where
    a.al_company_no <> 'SDHQ_LYGS_03' -- 排除铝三
;
/*废旧物资及副产品不含税销售额*/
insert into
    sdhq.dwd_prd_al_branch_company_d_ufd
    (id, dt_date, business_format, branch_company_code, branch_company_name, company_code,
     company_name, scrap_mat_byprod_nontax_sales_amt, source_system, source_table_name, source_id,
     etl_time)
select
    uuid()                                as id,
    dt.dt_date                            as dt_date,
    '电解铝'                              as business_format,
    area.company_no                       as branch_company_code,
    org.company_nm                        as branch_company_name,
    org.module_no                         as company_code,
    org.module_nm                         as company_name,
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
                when '铝业一分公司' then 'SDHQ_LYGS_01'
                when '铝业二分公司' then 'SDHQ_LYGS_02'
                when '铝业四分公司' then 'SDHQ_LYGS_04'
                when '铝业五分公司' then 'SDHQ_LYGS_05'
                when '云南宏泰新型材料有限公司' then 'SDHQ_LYGS_06'
                when '云南宏启新型材料有限公司' then 'SDHQ_LYGS_06'
                when '云南宏合新型材料有限公司' then 'SDHQ_LYGS_07'
                end as company_no
        from
            sdhq.ods_hqsms_areacode_ufd
        where
            AreaDescription in
            ('铝业一分公司', '铝业二分公司', '铝业四分公司', '铝业五分公司',
             '云南宏合新型材料有限公司', '云南宏泰新型材料有限公司', '云南宏启新型材料有限公司')
        ) area
        on a.areacode_guid = area.areacode_guid
    left join (
        /*分公司*/
        select distinct
            company_no,
            company_nm,
            module_no,
            module_nm
        from
            sdhq.dim_prd_org_flatten_ufd
        ) org on area.company_no = org.company_no
where
      a.delflag = 0
  and a.OutStorageDate >= '2025-11-25'
;
/*工作餐*/
insert into
    sdhq.dwd_prd_al_branch_company_d_ufd
    (id, dt_date, business_format, branch_company_code, branch_company_name, company_code,
     company_name, dine_exp, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                 as id,
    ddate                                  as dt_date,
    '电解铝'                               as business_format,
    org.org_code                           as branch_company_code,
    t.company                              as branch_company_name,
    org2.org_code                          as company_code,
    org2.org_name                          as company_name,
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
            replace(replace(replace(h.company, '分公司', '公司'), '（胡集侧）', ''),
                    '云南宏合新型材料有限公司',
                    '云南宏合')                                                            as company,
            ReceptionSubtotal * 1                                                          as subtotal
        from
            sdhq.ods_hqbpm_ldxgb_canteenreception_b_ufd b
            left join sdhq.ods_hqbpm_ldxgb_canteenreception_h_ufd h on b.taskid = h.taskid
        WHERE
              b.CBType = '计成本'
          and h.company not in ('铝业三分公司', '铝业三分公司（魏桥侧）', '铝业四分公司（滨州侧）')
        ) t
    inner join sdhq.dim_prd_org_ufd org
        on t.company = org.org_name and org.org_code like 'SDHQ_LYGS%'
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
where
    ddate >= '2025-11-25'
;