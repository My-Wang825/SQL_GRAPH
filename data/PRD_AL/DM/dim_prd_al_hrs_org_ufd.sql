/*
 铝业组织维度模型表
 开发者：乔凤
 开发日期：2026/01/03
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.dim_prd_al_hrs_org_ufd;

-- 将SourceTable数据插入TargetTable
insert into sdhq.dim_prd_al_hrs_org_ufd
--- 工区编码
select
    t1.id,
    t7.company_id as group_no,
    t7.company_name as group_nm,
    t6.company_id as plate_no,
    t6.company_name as plate_nm,
    t5.company_id as branch_company_no,
    t5.company_name as branch_company_nm,
    t4.company_id as branch_factory_no,
    t4.company_name as branch_factory_nm,
    t3.company_id as workshop_no,
    t3.company_name as workshop_nm,
    t2.company_id as area_no,
    t2.company_name as area_nm,
    t1.company_id as work_area_no,
    t1.company_name as work_area_nm,
	t1.unit_remark AS work_sec,
	t3.unit_remark AS workshop_alias,
    concat_ws('/',t7.company_id,t6.company_id,t5.company_id,t4.company_id,t3.company_id,t2.company_id,t1.company_id) as full_path_no,
    concat_ws('/',t7.company_name,t6.company_name,t5.company_name,t4.company_name,t3.company_name,t2.company_name,t1.company_name) as full_path_nm,
    current_timestamp as etl_tm
from(
    select 
        company_id,
        company_name,
        parent_company_id,
		unit_remark,
        id
    from sdhq.ods_ysapp_s_unit_ufd where length(company_id) = 12 and company_id like '1040%' 
   --1：取铝业板块组织；2：取最细设备向上关联，后面可以换成根据company_type取类型
)t1
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd
    
)t2 on t1.parent_company_id = t2.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
		unit_remark,
        id
    from sdhq.ods_ysapp_s_unit_ufd 
)t3 on t2.parent_company_id = t3.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,		
        id
    from sdhq.ods_ysapp_s_unit_ufd
 
)t4 on t3.parent_company_id = t4.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t5 on t4.parent_company_id = t5.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t6 on t5.parent_company_id = t6.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t7 on t6.parent_company_id = t7.id

UNION ALL
--- 动力车间编码
select
    t3.id,
    t7.company_id as group_no,	-- 集团
    t7.company_name as group_nm,
    t6.company_id as plate_no,	-- 板块
    t6.company_name as plate_nm,
    t5.company_id as branch_company_no,		-- 分公司
    t5.company_name as branch_company_nm,
    t4.company_id as branch_factory_no,		-- 分厂（原料、动力、综合）
    t4.company_name as branch_factory_nm,
    t3.company_id as workshop_no,			-- 系列（动力、阳极车间）
    t3.company_name as workshop_nm,
    NULL as area_no,						
    NULL as area_nm,
    NULL as work_area_no,
    NULL as work_area_nm,
	NULL AS work_sec,
	t3.unit_remark AS workshop_alias,
    concat_ws('/',t7.company_id,t6.company_id,t5.company_id,t4.company_id,t3.company_id) as full_path_no,
    concat_ws('/',t7.company_name,t6.company_name,t5.company_name,t4.company_name,t3.company_name) as full_path_nm,
    current_timestamp as etl_tm
from(
    select 
        company_id,
        company_name,
        parent_company_id,
        id,
		unit_remark
    from sdhq.ods_ysapp_s_unit_ufd 
    WHERE length(company_id) = 9 and COMPANY_NAME like '%动力' 
)t3 
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
		unit_remark,		
        id
    from sdhq.ods_ysapp_s_unit_ufd
 
)t4 on t3.parent_company_id = t4.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t5 on t4.parent_company_id = t5.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t6 on t5.parent_company_id = t6.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 
)t7 on t6.parent_company_id = t7.id

UNION ALL
---- 阳级车间编码
select
    t3.id,
    t7.company_id as group_no,
    t7.company_name as group_nm,
    t6.company_id as plate_no,
    t6.company_name as plate_nm,
    t5.company_id as branch_company_no,
    t5.company_name as branch_company_nm,
    t4.company_id as branch_factory_no,
    t4.company_name as branch_factory_nm,
    t3.company_id as workshop_no,
    t3.company_name as workshop_nm,
    NULL as area_no,
    NULL as area_nm,
    NULL as work_area_no,
    NULL as work_area_nm,
	NULL AS work_sec,
	NULL AS workshop_alias,
    concat_ws('/',t7.company_id,t6.company_id,t5.company_id,t4.company_id,t3.company_id) as full_path_no,
    concat_ws('/',t7.company_name,t6.company_name,t5.company_name,t4.company_name,t3.company_name) as full_path_nm,
    current_timestamp as etl_tm
from(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 
    WHERE  length(company_id) = 9 and COMPANY_NAME like '%车间%' 
)t3 
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
		unit_remark,		
        id
    from sdhq.ods_ysapp_s_unit_ufd

)t4 on t3.parent_company_id = t4.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t5 on t4.parent_company_id = t5.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t6 on t5.parent_company_id = t6.id
left join(
    select 
        company_id,
        company_name,
        parent_company_id,
        id
    from sdhq.ods_ysapp_s_unit_ufd 

)t7 on t6.parent_company_id = t7.id

;