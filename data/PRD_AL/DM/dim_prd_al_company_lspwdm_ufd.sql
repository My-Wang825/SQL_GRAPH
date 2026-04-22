/*
 -- 描述：企业生产日期公共维表
 -- 开发者：乔凤 
 -- 开发日期：2026-01-03
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.dim_prd_al_company_lspwdm_ufd;   

INSERT into sdhq.dim_prd_al_company_lspwdm_ufd
SELECT
	 t1.data_dt
	,t1.prod_y
	,t1.prod_ym
	,t2.branch_company_no
    ,t2.branch_factory_no
    ,t2.workshop_no
    ,t2.area_no
    ,t2.work_area_no
    ,t3.pw_nm
    ,t2.branch_company_nm
    ,t2.branch_factory_nm
    ,t2.workshop_nm
    ,t2.area_nm
    ,t2.work_area_nm
    ,current_timestamp as etl_time
    -- ,case  when  t2.branch_company_no = '104003' and t1.data_dt >= '2024-07-18'  then  t4.pw_nm  else t3.pw_nm end as pw_nm
FROM
(
select 
    data_dt
	,prod_y
	,concat(prod_y,'-',lpad(prod_m,2,'0')) AS prod_ym
from 
    sdhq.dim_prd_date_ufy
where data_dt BETWEEN '2021-11-25' AND '2034-11-24'
) t1 
left JOIN
(
select 
    branch_company_no
    ,branch_company_nm
    ,branch_factory_no
    ,branch_factory_nm
    ,workshop_no
    ,workshop_nm
    ,area_no
    ,area_nm
    ,work_area_no
    ,work_area_nm
 from 
sdhq.dim_prd_al_hrs_org_ufd  where work_area_nm like '%区'
) t2 on 1=1
LEFT JOIN(
select 	
    pw_nm  
from 
    sdhq.dim_prd_al_lspwdm_mapping_ufd 
where pw_nm <> '一等外' AND pw_nm <> 'AL99.70A' ) t3
 on 1=1;