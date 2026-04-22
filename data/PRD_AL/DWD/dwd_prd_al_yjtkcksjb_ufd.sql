/*
 -- 描述：阳极炭块出库数据表
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 说明：电解铝综合分厂阳极炭块报表使用【流入（块）、流出（块）、流出（吨）】
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE dwd_prd_al_yjtkcksjb_ufd;   

-- 将SourceTable数据插入TargetTable
Insert into dwd_prd_al_yjtkcksjb_ufd
(
id,
	x_date,
	x_jsdh,
	branch_company_no,
	branch_company_nm,
	workshop_no,
	workshop_nm,
	x_cj,
	x_weight,
	x_ggxh,
	x_ywlx,
	x_lybm,
	x_jz,
	x_dj,
	x_czy,
	x_js,
	x_djzl,
	b,
	x_ckzl,
	x_ckje,
	x_yckjs,
	x_yckzl,
	x_ghdwdm,
	x_pzrq,
	x_czrq,
	x_bz,
	x_cklx,
	x_fjk,
	x_hth,
	x_pj,
	x_xsdj1,
	x_xsje,
	nc_h,
	nc_b,
	nc,
	bk,
	kyxm,
	etl_time
)
select
	t1.id,
	t1.x_date,
	t1.x_jsdh,
	t3.branch_company_no,
	t3.branch_company_nm,
	t3.workshop_no,
	t3.workshop_nm,
	t1.x_cj,
	t1.x_weight,
	t1.x_ggxh,
	t1.x_ywlx,
	t1.x_lybm,
	t1.x_jz,
	t1.x_dj,
	t1.x_czy,
	t1.x_js,
	t1.x_djzl,
	t1.b,
	t1.x_ckzl,
	t1.x_ckje,
	t1.x_yckjs,
	t1.x_yckzl,
	t1.x_ghdwdm,
	t1.x_pzrq,
	t1.x_czrq,
	t1.x_bz,
	t1.x_cklx,
	t1.x_fjk,
	t1.x_hth,
	t1.x_pj,
	t1.x_xsdj1,
	t1.x_xsje,
	t1.nc_h,
	t1.nc_b,
	t1.nc,
	t1.bk,
	t1.kyxm,
	now() as etl_time
from
	(
	select
		id,
		x_jsdh,
		x_cj,
		x_date,
		x_weight,
		case
			when x_cj = '1701'
			and trim(x_ggxh) = '' then 'S1650*700*620'   -- 规格型号（阳信：别的公司调来的仓库往系统里录入的时候没有输入型号，应该是S1650*700*620）
			else trim(x_ggxh)
		end as x_ggxh,
		x_ywlx,
		x_lybm,
		x_jz,
		x_dj,
		x_czy,
		x_js,
		x_djzl,
		b,
		x_ckzl,
		x_ckje,
		x_yckjs,
		x_yckzl,
		x_ghdwdm,
		x_pzrq,
		x_czrq,
		x_bz,
		x_cklx,
		x_fjk,
		x_hth,
		x_pj,
		x_xsdj1,
		x_xsje,
		nc_h,
		nc_b,
		nc,
		bk,
		kyxm
	from
		sdhq.ods_mms_yjtkcksjb_ufd
	where
        (x_date <> '2023-06-30 00:00:00'
			or x_cj <> '1402')     -- 铝业四公司（滨州测）阳极二车间
) t1
left join (
	select
		x_dm,
		x_mc
	from
		sdhq.dim_prd_flckdm_ufd
) t2 on
	t1.x_cj = t2.x_dm
left join (
	select
		wzms_workshop_nm,
		branch_company_no,
		branch_company_nm,
		workshop_no,
		workshop_nm
	from
		sdhq.dim_prd_al_mms_company_wksp_rltn_ufd
) t3 on
	t2.x_mc = t3.wzms_workshop_nm;





