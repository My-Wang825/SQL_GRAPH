/*
 -- 描述：铝业_槽号组织映射关系
 -- 开发者：乔凤 
 -- 开发日期：2026-01-03
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：

 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.dim_prd_al_slot_number_org_mapping_ufd;   


---- 槽号组织关系模型数据生成
insert into  sdhq.dim_prd_al_slot_number_org_mapping_ufd
select 
    t1.device_name as slot_number,
    t2.group_no,
    t2.plate_no,
    t2.branch_company_no,
    t2.branch_factory_no,
    t2.workshop_no,
    t2.area_no,
    t2.work_area_no,
    t2.group_nm,
    t2.plate_nm,
    t2.branch_company_nm,
    t2.branch_factory_nm,
    t2.workshop_nm,
    t2.area_nm,
    t2.work_area_nm,
    t1.device_manufact,
    t2.full_path_no,
    t2.full_path_nm, 
    current_timestamp as etl_time
from(
    select  
        device_name,
        company_id,
		device_manufact     -- 生产厂家 2023-04-19 新增
    from  sdhq.dim_prd_s_device_resource_ufd  --后面还需要根据device_type过滤取电解槽设备
	where full_company_id like '%铝业公司%' and full_company_id not like '%动力分厂%'
)t1
left join(
    select 
        id,
        group_no,
        group_nm,
        plate_no,
        plate_nm,
        branch_company_no,
        branch_company_nm,
        branch_factory_no,
        branch_factory_nm,
        workshop_no,
        workshop_nm,
        area_no,
        area_nm,
        work_area_no,
        work_area_nm,
        full_path_no,
        full_path_nm
    from sdhq.dim_prd_al_hrs_org_ufd
)t2 on t1.company_id = t2.id
WHERE t2.group_nm is not null;