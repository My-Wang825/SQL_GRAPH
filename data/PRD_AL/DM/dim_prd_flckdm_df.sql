/*

 -- 描述：铝电物资管理系统-车间代码表 
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 描述：
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE dim_prd_flckdm_ufd;

-- 将SourceTable数据插入TargetTable
INSERT INTO
  dim_prd_flckdm_ufd (x_dm, x_mc, x_gs, bk, etl_time)
SELECT
  x_dm,
  x_mc,
  x_gs,
  bk,
  CURRENT_TIMESTAMP AS etl_time
FROM
  ods_ht_mms_flckdm_ufd;