
/*

 -- 描述：电解铝组织维度表 
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 描述：国科(公司->系列) + 云杉(车间->工区)
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

DELETE FROM dim_prd_al_report_org_ufd WHERE ds = '$[yyyy-MM-dd]';
INSERT INTO
  dim_prd_al_report_org_ufd (
    ds,
    group_no,
    company_no,
    branch_company_no,
    factory_no,
    series_no,
    area_no,
    work_area_no,
    group_nm,
    company_nm,
    branch_company_nm,   
    factory_nm,    
    series_name,
    series_na,    
    area_nm,    
    work_area_nm,
    work_section_nm,
    etl_time
  )
SELECT
  CURDATE() AS ds,
  a.group_no,
  a.company_no,
  a.company_nick_no as branch_company_no ,
  a.factory_no,
  a.series_no,
  b.area_no,
  b.work_area_no,
  a.group_nm,
  a.company_nm,
  a.company_nick_name as branch_company_nm,
  a.factory_nm,
  a.series_name,
  a.series_na,
  b.area_nm,
  b.work_area_nm,
  b.work_section_nm,
  CURRENT_TIMESTAMP AS etl_time
FROM
  sdhq.ods_gksso_sys_depart_record_ufd a
  left join sdhq.ods_ysapp_prd_al_s_unit_ufd b on a.series_name = b.series_nm
order by
  a.company_nick_no,
  a.factory_no asc,
  a.series_no ;
