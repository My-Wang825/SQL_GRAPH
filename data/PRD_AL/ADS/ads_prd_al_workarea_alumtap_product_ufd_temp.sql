/*
 -- 描述：出铝产量统计_IT数据临时表01
 -- 开发者：乔凤 
 -- 开发日期：2026-01-06
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
truncate table sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp;


insert into sdhq.ads_prd_al_workarea_alumtap_product_ufd_temp
select 
    data_dt,
    prod_y,
    prod_m,
    company_no,
    branch_factory_no,
    series_no,area_no,work_area_no,
    pw,
    company_nm,
    branch_factory_nm,
    series_nm,
    area_nm,    
    work_area_nm,    
    clcl_d,
    sum(clcl_d) over(partition by prod_m, company_no, branch_factory_no, series_no, area_no, work_area_no ,pw order by data_dt) as clcl_m,
    sum(clcl_d) over(partition by prod_y, company_no, branch_factory_no,  series_no, area_no, work_area_no ,pw order by data_dt) as clcl_y,
    CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
    from
(select 
    /*+ COALESCE(3) */
	a.data_dt
	,a.prod_y
    ,a.prod_m
	,a.branch_company_no as company_no
    ,a.branch_factory_no
    ,a.workshop_no as series_no
    ,a.area_no
    ,a.work_area_no
    ,a.pw_nm AS pw
    ,a.branch_company_nm as company_nm
    ,a.branch_factory_nm
    ,a.workshop_nm as series_nm
    ,a.area_nm
    ,a.work_area_nm
	,COALESCE(b.clcl_d, 0) AS clcl_d
   -- ,CURRENT_TIMESTAMP AS etl_time  -- 使用当前时间
FROM
(	
	SELECT
		data_dt
		,prod_y
		,prod_ym AS prod_m
		,branch_company_no
		,branch_factory_no
        ,workshop_no
        ,area_no
        ,work_area_no
        ,pw_nm
		,branch_company_nm
		,branch_factory_nm
		,workshop_nm
		,area_nm
		,work_area_nm
	FROM
		sdhq.dim_prd_al_company_lspwdm_ufd
	WHERE 
-- 	data_dt between concat($[yyyy]-1, '-11-25') 
-- 	and concat_ws('-', substr($[yyyyMMdd-1], 1, 4), substr($[yyyyMMdd-1], 5, 2), substr($[yyyyMMdd-1], 7, 2))
	data_dt BETWEEN 
            CONCAT(YEAR(CURDATE()) - 1, '-11-25')
            AND DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d')
	and if(branch_company_no <> '104003' , pw_nm<>'AL99.90' ,1=1)
)  a
LEFT JOIN	
     (
    select 
    substr(from_unixtime(unix_timestamp(x_rq,'yyyy-MM-dd HH:mm:ss') - 28800),1,10) as data_dt,
    branch_company_no,
    branch_factory_no,
    workshop_no,
    area_no,
    work_area_no,
    x_pw as pw,
    branch_company_nm,
    branch_factory_nm,
    workshop_nm,
    area_nm,
    work_area_nm,
    sum(x_dcsjcl) as clcl_d
from sdhq.dwd_prd_al_lsmxsjb_ufd where  branch_company_no is not null
group by 
    substr(from_unixtime(unix_timestamp(x_rq,'yyyy-MM-dd HH:mm:ss') - 28800),1,10),
    x_pw,
    branch_company_no,
    branch_company_nm,
    branch_factory_no,
    branch_factory_nm,
    workshop_no,
    workshop_nm,
    area_no,
    area_nm,
    work_area_no,
    work_area_nm
    ) b
ON a.data_dt=b.data_dt AND a.branch_company_no=b.branch_company_no AND a.branch_factory_no=b.branch_factory_no 
AND a.workshop_no=b.workshop_no AND a.area_no=b.area_no AND a.work_area_no=b.work_area_no AND a.pw_nm=b.pw
)t2
where  -- 过滤云南宏泰未投产的厂区，后期此处添加 是否投产 标识
    -- work_area_no <> '10400801AX05'                  -- 原料一厂5区
    -- AND work_area_no <> '10400801AD06'         -- 原料一厂6区
    t2.work_area_no <> '10400803CX05'         -- 原料三厂5区
    AND t2.work_area_no <> '10400803CD06'          -- 原料三厂6区
    -- AND branch_factory_no <> '10400804'           -- 原料四厂
    -- AND branch_factory_no <> '10400805'           -- 原料五厂    20230809 张瑞
    --
    -- AND work_area_no <> '10400806FX03'          -- 原料六厂  三区 
    -- AND work_area_no <> '10400806FD04'           -- 原料六厂  四区
    -- AND work_area_no <> '10400806FX05'          -- 原料六厂  五区
    -- AND work_area_no <> '10400806FD06'          -- 原料六厂  六区

;