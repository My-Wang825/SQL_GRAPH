/*
 -- 描述：出铝产量统计_IT数据(和电解铝报表新组织维度关联)
 -- 开发者：乔凤 
 -- 开发日期：2026-01-06
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.ads_prd_al_workarea_alumtap_product_new_ufd;
insert into sdhq.ads_prd_al_workarea_alumtap_product_new_ufd 
select
	t1.data_dt,
	t1.prod_y,
	t1.prod_m,
	t2.branch_company_no,
	t2.factory_no,
    t2.series_no,
    t2.area_no,
    t2.work_area_no,
    t1.pw,
    t2.branch_company_nm,
	t2.factory_nm,	
	t2.series_na,	
	t2.area_nm,	
	t2.work_area_nm,
	t1.clcl_d,
	t1.clcl_m,
	t1.clcl_y,
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
from
	(
	select
		branch_company_no,
		branch_company_nm,
		factory_no,
		factory_nm,
		series_no,
		series_na,
		area_no,
		area_nm,
		work_area_no,
		work_area_nm
	from
		sdhq.dim_prd_al_report_org_ufd
	where
        ds = DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd')
		and factory_nm like '%电解%'
		and series_na like '%系列'
        and work_area_NO <>'DJL_YS_DJ_030105'
		and work_area_NO <>'DJL_YS_DJ_030206'
)t2
left join
(
select
		data_dt,
		prod_y,
		prod_m,
		company_no,
		case
			when company_nm = '铝业一公司（邹平侧）' then '铝业一公司'
			when company_nm = '铝业三公司（魏桥侧）' then '铝业三公司'
			when company_nm = '铝业四公司（胡集侧）' then '铝业四公司'
			else company_nm
		end as company_nm,
		branch_factory_no,
		branch_factory_nm,
		series_no,
		series_nm,
		area_no,
		area_nm,
		work_area_no,
		work_area_nm,
		pw,
		clcl_d,
		clcl_m,
		clcl_y
	from
		sdhq.ads_prd_al_workarea_alumtap_product_ufd
	where
		work_area_nm like '%区'
		and company_nm !='铝业四公司（滨州侧）'
)t1
on
	t1.company_nm = t2.branch_company_nm
  AND (
        -- 使用 SUBSTR 替代 RIGHT，取后两个字符
        SUBSTR(t1.branch_factory_nm, LENGTH(t1.branch_factory_nm) - 1, 2)
            = SUBSTR(t2.factory_nm, LENGTH(t2.factory_nm) - 1, 2)
        OR t2.factory_nm LIKE CONCAT('%', t1.branch_factory_nm, '%')
    )
    AND t1.series_nm = t2.series_na  
    AND   (
        -- 使用 SUBSTR 替代 RIGHT，取后两个字符
        SUBSTR(t1.area_nm, LENGTH(t1.area_nm) - 1, 3)
            = SUBSTR(t2.area_nm, LENGTH(t2.area_nm) - 1, 3)
        OR t1.area_nm LIKE CONCAT('%', t2.area_nm, '%')
    )
    AND t1.work_area_nm = t2.work_area_nm;