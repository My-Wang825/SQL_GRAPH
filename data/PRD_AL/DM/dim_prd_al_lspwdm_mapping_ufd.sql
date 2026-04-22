/*
 
 -- 描述：铝业品位映射表(计量系统)
 -- 开发者：乔凤 
 -- 开发日期：2026-01-03
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.dim_prd_al_lspwdm_mapping_ufd;
-- 将SourceTable数据插入TargetTable
INSERT INTO
  sdhq.dim_prd_al_lspwdm_mapping_ufd
select
  x_dm as pw_no,
  x_mc as pw_nm,
  current_timestamp as etl_time
from
  sdhq.ods_hqjl_lspwdm_ufh;
