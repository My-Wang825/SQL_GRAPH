/*
 -- 描述：氧化铝物料单价表-月
 -- 日期：2025-10-28
 -- 开发者：数语
 */
-- 删除TargetTable已有数据
truncate table sdhq.dwd_prd_ao_branch_company_d_ufd;

-- 将SourceTable数据插入TargetTable

/*副产品_废料&钒饼收入*/
insert into
    sdhq.dwd_prd_ao_branch_company_d_ufd
    (id, dt_date, business_format, branch_company_code, branch_company_name, company_name,
     company_code, scrap_mat_byprod_income, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                as id,
    dt.dt_date                            as dt_date,
    '氧化铝'                              as business_format,
    org.org_code                          as branch_company_code,
    area.areadescription                  as branch_company_name,
    org2.org_name                         as company_name,
    org2.org_code                         as company_code,
    Amount                                as scrap_mat_byprod_income,
    'hqsms'                               as source_system,
    'sales.CoProduct.CoProductOutStorage' as source_table_name,
    CoProductOutStorage_GUID              as source_id,
    now()                                 as etl_time
from
    sdhq.ods_hqsms_coproductoutstorage_ufd a
    left join sdhq.dim_prd_date dt on date(a.OutStorageDate) = dt.dt_date
    left join (
        /*分公司*/
        select
            areacode_guid,
            replace(replace(areadescription, '分公司', '公司'), '北区', '') as areadescription
        from
            sdhq.ods_hqsms_areacode_ufd
        ) area
        on a.areacode_guid = area.areacode_guid
    left join sdhq.dim_prd_org_ufd org on area.areadescription = org.org_name
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
where
      a.delflag = 0
  and a.OutStorageDate >= '2025-11-25'
  and area.AreaDescription in
      ('滨州市北海信和新材料有限公司', '氧化铝四分公司北区', '氧化铝二公司',
       '氧化铝四公司', '氧化铝五公司', '氧化铝三公司', '氧化铝一公司')
  and delflag = 0
;

/*工作餐*/
insert into
    sdhq.dwd_prd_ao_branch_company_d_ufd
    (id, dt_date, business_format, branch_company_code, branch_company_name, company_code,
     company_name, dine_exp, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                 as id,
    ddate                                  as dt_date,
    '氧化铝'                               as business_format,
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
            replace(replace(h.company, '分公司', '公司'), '北区', '') as company,
            str_to_date(ReceptionDate, 'yyyy-MM-dd')                  as ddate,
            ReceptionSubtotal * 1                                     as subtotal
        from
            sdhq.ods_hqbpm_ldxgb_canteenreception_b_ufd b
            left join sdhq.ods_hqbpm_ldxgb_canteenreception_h_ufd h on b.taskid = h.taskid
        WHERE
              b.CBType = '计成本'
          AND b.ReceptionSubtotal * 1 IS NOT NULL
          and str_to_date(ReceptionDate, 'yyyy-MM-dd') >= '2025-11-25'
          AND h.company LIKE '%氧化铝%' -- 公司名称条件（假设在h表）
        ) t
    left join sdhq.dim_prd_org_ufd org on t.company = org.org_name
    left join sdhq.dim_prd_org_ufd org2 on org.parent_id = org2.org_id
;