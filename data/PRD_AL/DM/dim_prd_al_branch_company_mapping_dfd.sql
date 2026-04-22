/*

 -- 描述：计量系统(铝水称量查询)-分公司映射表
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
-- 删除TargetTable已有数据
truncate table sdhq.dim_prd_al_branch_company_mapping_dfd;
-- 将SourceTable数据插入TargetTable
-- 插入数据
INSERT INTO
  dim_prd_al_branch_company_mapping_dfd
VALUES
  (
    'SDHQ_LYGS_07',
    '云南宏合',
    '云南宏合新型材料有限公司',
    '云南宏合成品仓库',
    CURRENT_TIMESTAMP
  ),
  (
    '104009',
    '云南宏启',
    '云南宏启新型材料有限公司',
    '云南宏启成品仓库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_06',
    '云南宏泰',
    '云南宏泰新型材料有限公司',
    '云南宏泰成品仓库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_05',
    '铝业五公司',
    '铝业四分公司（北海）',
    '北海成品库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_04',
    '铝业四公司',
    '铝业五分公司',
    '惠民成品库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_03',
    '铝业三公司（魏桥侧）',
    '铝业一分公司（魏桥）',
    '宏茂第二成品仓库',
    CURRENT_TIMESTAMP
  ),
  -- 为了区分铝三魏桥和铝三，将公司名写为铝业三公司(魏桥)
  (
    'SDHQ_LYGS_03',
    '铝业三公司',
    '铝业三分公司',
    '汇盛成品仓库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_02',
    '铝业二公司',
    '阳信县汇宏新材料有限公司',
    '阳信成品库',
    CURRENT_TIMESTAMP
  ),
  (
    'SDHQ_LYGS_01',
    '铝业一公司',
    '铝业一分公司',
    '宏正第二成品库',
    CURRENT_TIMESTAMP
  );