/*
 -- 描述：铝厂铝水出货单
 -- 开发者：乔凤 
 -- 开发日期：2025-10-27 
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

-- 删除TargetTable已有数据
truncate table sdhq.dwd_prd_al_lsclsjb_dfd;
-- 将SourceTable数据插入TargetTable
-- 插入数据

INSERT INTO sdhq.dwd_prd_al_lsclsjb_dfd (
    x_xh, -- 序号
    x_czrq, -- 操作日期
    ds, -- 分区日期
    x_czy, -- 操作员
    x_jsdh, -- 结算单号
    x_pm, -- 品名
    x_ywlx, -- 业务类型
    x_kh, -- 客户代码
    x_ch, -- 车号
    x_mz, -- 毛重
    x_mzsby, -- 毛重操作员
    x_mzrq, -- 毛重日期
    x_pz, -- 皮重
    x_pzsby, -- 皮重操作员
    x_pzrq, -- 皮重日期
    x_jz, -- 净重
    x_sfzl, -- 收方重量
    x_cs, -- 差数
    x_ck, -- 仓库
    x_bs, -- 磅室
    x_bc, -- 班次
    x_fgs, -- 分公司
    branch_company_no, -- 分公司编码
    branch_company_nm, -- 分公司名称
    x_bz, -- 备注
    x_sfsg, -- 手工操作
    x_fc, -- 分厂
    x_yspz, -- 原始皮重
    x_kz, -- 扣重
    x_bz2, -- 备注二
    x_wbc, -- 外部车辆
    x_mzsb, -- 毛重司磅员
    x_pzsb, -- 皮重司磅员
    x_jsdh1, -- 结算单号1
    x_nbc, -- 内部车辆
    x_fjbh, -- 槽号明细编号
    x_tid, -- 车辆标识
    x_dy, -- 打印标记
    x_dyczy, -- 打印操作员
    x_dyrq, -- 打印日期
    x_yc, -- 异常标记
    x_icczy, -- 写卡人
    x_shbj, -- 审核标记
    x_shczy, -- 审核操作员
    x_shrq, -- 审核日期
    x_mes, -- 传mes标记
    x_ignore, -- 暂时忽略标记
    x_bh, -- 包号
    x_fhjhh, -- 发货计划号
    x_ckbj, -- 出库标记
    x_ckczy, -- 出库操作员
    x_ckrq, -- 出库日期
    update_by, -- 修改人
    update_time, -- 修改时间
    sys_org_code, -- 组织编码
    del_flag, -- 是否删除
    x_aluminumid -- 槽号明细编号
)
SELECT 
    t1.x_xh, -- 序号
    t1.x_czrq, -- 操作日期
    t1.ds, -- 分区日期
    t1.x_czy, -- 操作员
    t1.x_jsdh, -- 结算单号
    t1.x_pm, -- 品名
    t1.x_ywlx, -- 业务类型
    t1.x_kh, -- 客户代码
    t1.x_ch, -- 车号
    t1.x_mz, -- 毛重
    t1.x_mzsby, -- 毛重操作员
    t1.x_mzrq, -- 毛重日期
    t1.x_pz, -- 皮重
    t1.x_pzsby, -- 皮重操作员
    t1.x_pzrq, -- 皮重日期
    t1.x_jz, -- 净重
    t1.x_sfzl, -- 收方重量
    t1.x_cs, -- 差数
    t1.x_ck, -- 仓库
    t1.x_bs, -- 磅室
    t1.x_bc, -- 班次
    t1.x_fgs, -- 分公司
    t2.branch_company_no, -- 分公司编码
    t2.branch_company_nm, -- 分公司名称
    t1.x_bz, -- 备注
    t1.x_sfsg, -- 手工操作
    t1.x_fc, -- 分厂
    t1.x_yspz, -- 原始皮重
    t1.x_kz, -- 扣重
    t1.x_bz2, -- 备注二
    t1.x_wbc, -- 外部车辆
    t1.x_mzsb, -- 毛重司磅员
    t1.x_pzsb, -- 皮重司磅员
    t1.x_jsdh1, -- 结算单号1
    t1.x_nbc, -- 内部车辆
    t1.x_fjbh, -- 槽号明细编号
    t1.x_tid, -- 车辆标识
    t1.x_dy, -- 打印标记
    t1.x_dyczy, -- 打印操作员
    t1.x_dyrq, -- 打印日期
    t1.x_yc, -- 异常标记
    t1.x_icczy, -- 写卡人
    t1.x_shbj, -- 审核标记
    t1.x_shczy, -- 审核操作员
    t1.x_shrq, -- 审核日期
    t1.x_mes, -- 传mes标记
    t1.x_ignore, -- 暂时忽略标记
    t1.x_bh, -- 包号
    t1.x_fhjhh, -- 发货计划号
    t1.x_ckbj, -- 出库标记
    t1.x_ckczy, -- 出库操作员
    t1.x_ckrq, -- 出库日期
    t1.update_by, -- 修改人
    t1.update_time, -- 修改时间
    t1.sys_org_code, -- 组织编码
    t1.del_flag, -- 是否删除
    t1.x_aluminumid -- 槽号明细编号
FROM (
    SELECT
        x_xh, -- 序号
        x_czrq, -- 操作日期
        ds, -- 分区日期
        x_czy, -- 操作员
        x_jsdh, -- 结算单号
        x_pm, -- 品名
        x_ywlx, -- 业务类型
        x_kh, -- 客户代码
        x_ch, -- 车号
        x_mz, -- 毛重
        x_mzsby, -- 毛重操作员
        x_mzrq, -- 毛重日期
        x_pz, -- 皮重
        x_pzsby, -- 皮重操作员
        x_pzrq, -- 皮重日期
        x_jz, -- 净重
        x_sfzl, -- 收方重量
        x_cs, -- 差数
        x_ck, -- 仓库
        x_bs, -- 磅室
        x_bc, -- 班次
        x_fgs, -- 分公司
        x_bz, -- 备注
        x_sfsg, -- 手工操作
        x_fc, -- 分厂
        x_yspz, -- 原始皮重
        x_kz, -- 扣重
        x_bz2, -- 备注二
        x_wbc, -- 外部车辆
        x_mzsb, -- 毛重司磅员
        x_pzsb, -- 皮重司磅员
        x_jsdh1, -- 结算单号1
        x_nbc, -- 内部车辆
        x_fjbh, -- 槽号明细编号
        x_tid, -- 车辆标识
        x_dy, -- 打印标记
        x_dyczy, -- 打印操作员
        x_dyrq, -- 打印日期
        x_yc, -- 异常标记
        x_icczy, -- 写卡人
        x_shbj, -- 审核标记
        x_shczy, -- 审核操作员
        x_shrq, -- 审核日期
        x_mes, -- 传mes标记
        x_ignore, -- 暂时忽略标记
        x_bh, -- 包号
        x_fhjhh, -- 发货计划号
        x_ckbj, -- 出库标记
        x_ckczy, -- 出库操作员
        x_ckrq, -- 出库日期
        update_by, -- 修改人
        update_time, -- 修改时间
        sys_org_code, -- 组织编码
        del_flag, -- 是否删除
        x_aluminumid -- 槽号明细编号
    FROM sdhq.ods_hqjl_lsclsjb_ufh
) t1
LEFT JOIN (
    SELECT 
        branch_company_no,   
        branch_company_nm,
        mims_branch_company_nm
    FROM sdhq.dim_prd_al_branch_company_mapping_dfd 
) t2 ON t1.x_fgs = t2.mims_branch_company_nm;