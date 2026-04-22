/*

 -- 描述：铝业各分公司 与 铝电物资管理系统各阳极车间关系对照表
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
-- 铝业生产日报与物资系统阳极车间关系对照表
-- 删除TargetTable已有数据
TRUNCATE TABLE dim_prd_al_mms_company_wksp_rltn_ufd;   


-- 将SourceTable数据插入TargetTable
INSERT INTO
  dim_prd_al_mms_company_wksp_rltn_ufd (
    wzms_workshop_nm,
    branch_company_no,
    factory_no,
    workshop_no,
    branch_company_nm,
    factory_nm,
    workshop_nm,
    etl_time
  )
SELECT
  wzms_workshop_nm,
  branch_company_no,
  factory_no,
  workshop_no,
  branch_company_nm,
  factory_nm,
  workshop_nm,
  CURRENT_TIMESTAMP AS etl_time -- ODS表手动导入
FROM
  ods_mms_company_wksp_rltn_dfd;
