/*
 -- 描述：出铝产量统计_IT数据(取工区、车间、系列、分厂维度的出铝量)
 -- 开发者：乔凤 
 -- 开发日期：2026-01-06
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.ads_prd_al_workarea_alumtap_product_ufd;   

INSERT into  sdhq.ads_prd_al_workarea_alumtap_product_ufd 
SELECT          -- 工区维度
    /*+ COALESCE(1) */
	data_dt,
    prod_y,
    prod_m,
    company_no,
    branch_factory_no,
    series_no,
    area_no,
    work_area_no,
    pw,
    company_nm,
    branch_factory_nm,
    series_nm,
    area_nm,
    work_area_nm,
    clcl_d,
	clcl_m,
	clcl_y,
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
FROM 
	sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp

UNION ALL

SELECT      -- 区域维度
    /*+ COALESCE(1) */
	data_dt,
    prod_y,
    prod_m,
    company_no,
    branch_factory_no,
    series_no,
    area_no,
    area_no AS work_area_no,
    pw,
    company_nm,
    branch_factory_nm, 
    series_nm,
    area_nm,
    area_nm AS work_area_nm,
	SUM(clcl_d),
	SUM(clcl_m),
	SUM(clcl_y),
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
FROM
	sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp
group by
	data_dt,
    prod_y,
    prod_m,
    company_no,
    company_nm,
    branch_factory_no,
    branch_factory_nm,
    series_no,
    series_nm,
    area_no,
    area_nm,
	pw

UNION all
	
SELECT
    /*+ COALESCE(1) */
	data_dt,
    prod_y,
    prod_m,
    company_no,
    branch_factory_no,
    series_no,
    series_no AS area_no,
	series_no AS work_area_no,
    pw,
    company_nm,
    branch_factory_nm,
    series_nm,
    series_nm AS area_nm,
    series_nm AS work_area_nm,
	SUM(clcl_d),
	SUM(clcl_m),
	SUM(clcl_y),
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
FROM
	sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp
WHERE company_no='104004'
group by
	data_dt,
    prod_y,
    prod_m,
    company_no,
    company_nm,
    branch_factory_no,
    branch_factory_nm,
    series_no,
    series_nm,
	pw

UNION all
	
SELECT
    /*+ COALESCE(1) */
	data_dt,
    prod_y,
    prod_m,
    company_no,
    branch_factory_no,
    branch_factory_no as series_no,
    branch_factory_no AS area_no,
    branch_factory_no AS work_area_no,
    pw,
    company_nm,
    branch_factory_nm,   
    branch_factory_nm as series_nm,
    branch_factory_nm AS area_nm,	
    branch_factory_nm AS work_area_nm,
	SUM(clcl_d),
	SUM(clcl_m),
	SUM(clcl_y),
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
FROM
	sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp
group by
	data_dt,
    prod_y,
    prod_m,
    company_no,
    company_nm,
    branch_factory_no,
    branch_factory_nm,
	pw;
