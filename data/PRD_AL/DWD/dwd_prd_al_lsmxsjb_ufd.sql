/*
 -- 描述：铝水称重明细
 -- 开发者：乔凤 
 -- 开发日期：2026-01-04
 -- 说明：和报表组织维度进行连接
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE sdhq.dwd_prd_al_lsmxsjb_ufd;   

-- 将SourceTable数据插入TargetTable
INSERT INTO sdhq.dwd_prd_al_lsmxsjb_ufd 
select 
    t1.x_xh, -- 序号
    t1.x_rq, -- 日期
    t3.branch_company_no,
    t3.branch_factory_no,
    t3.workshop_no,
    t3.area_no,
    t3.work_area_no,
    t4.pw_nm, -- 品味名称
    t1.x_ch, -- 槽号
    t3.branch_company_nm,
    t3.branch_factory_nm,
    t3.workshop_nm,
    t3.area_nm,
    t3.work_area_nm,
    t1.x_jsdh, -- 结算单号
    t1.x_bs, -- 磅室
    t1.x_dcjhcl, -- 单槽计划产量
    t1.x_dcsjcl, -- 单槽实际产量
    t1.x_cs, --  差数
    t1.x_qw, -- 区位
    t1.x_cj, -- 车间
    t1.x_bz, -- 备注
    t1.x_czy, -- 操作员
    t1.x_czrq, -- 操作日期
    t1.x_rq1, -- 日期1
    t1.x_czy1, -- 操作员1
    t1.x_fgs, -- 分公司
    t1.x_fc, -- 分厂
    t1.x_fjbh, -- 槽号明细编号
    t1.x_fe, 
    t1.x_si, 
    t1.x_aluminumid, -- 槽号明细编号
    current_timestamp as etl_time -- ETL时间戳 
from(
select
    x_xh, -- 序号
    x_jsdh, -- 结算单号
    x_bs, -- 磅室
    x_ch, -- 槽号
    x_pw, 
    x_dcjhcl, -- 单槽计划产量
    x_dcsjcl, -- 单槽实际产量
    x_cs, -- 差数
    x_qw, -- 区位
    x_cj, -- 车间
    x_bz, -- 备注
    x_rq, -- 日期   --------------------------------
    x_czy, -- 操作员
    x_czrq, -- 操作日期
    x_rq1, -- 日期1
    x_czy1, -- 操作员1
    x_fgs, -- 分公司
    x_fc, -- 分厂
    x_fjbh, -- 槽号明细编号
    x_fe, 
    x_si, 
    x_aluminumid -- 槽号明细编号
from sdhq.ods_hqjl_lsmxsjb_ufh 
)t1
left join(
    select 
        -- branch_company_no,
       -- case when branch_company_no='104009' then 'SDHQ_LYGS_06' -- 云南宏启合并到云南宏泰
       -- when branch_company_no='SDHQ_LYGS_07' then '104009'  -- 云南宏合
       -- else branch_company_no  
       --  end as
        branch_company_no,
        case when branch_company_nm='云南宏启' then '云南宏泰'
        else branch_company_nm
        end as branch_company_nm,
        mims_branch_company_nm
    from sdhq.dim_prd_al_branch_company_mapping_dfd  -- 分公司映射关系表  
)t2  on t1.x_fgs = t2.mims_branch_company_nm
left join(
    select 
        slot_number,
        branch_company_no,
        case when branch_company_nm='铝业四公司（胡集侧）' then '铝业四公司'
        when branch_company_nm='铝业一公司（邹平侧）' then '铝业一公司'
        else branch_company_nm
        end as branch_company_nm,
        branch_factory_no,
        branch_factory_nm,
        workshop_no,
        workshop_nm,
        area_no,
        area_nm,
        work_area_no,
        work_area_nm
    from sdhq.dim_prd_al_slot_number_org_mapping_ufd
    where branch_company_nm <> '铝业四公司（滨州侧）'
)t3 on t2.branch_company_nm = t3.branch_company_nm and t1.x_ch = t3.slot_number
left join
	sdhq.dim_prd_al_lspwdm_mapping_ufd t4
ON t1.x_pw=t4.pw_no
