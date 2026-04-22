
/*
 -- 描述：生产域电解铝经济指标
 -- 开发者：马小龙 
 -- 开发日期：2026-03
 -- 说明：1、原辅料耗用量调整前 2、液态铝产量、液态铝99.70产量 3、原辅料补偿量耗用量 4、综合电量耗用量_调整前、光伏、国网 5、原辅料单耗
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
/*清空表数据*/
truncate table sdhq.dwd_prd_al_fact_d_ufd;

/*物资耗用量*/
insert into
    sdhq.dwd_prd_al_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, ao_consumqty_tzq,
     anode_carb_consumqty_tzq, alf3_consumqty_tzq, cryo_consumqty_tzq, electro_consumqty_tzq,
     mgf2_consumqty_tzq, caf2_consumqty_tzq, soda_ash_consumqty_tzq, li2co3_consumqty,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                                   as id,
    metric_time                              as dt_date,
    '电解铝'                                 as business_format,
    al_factory_no                            as branch_factory_code,      -- 分厂编码
    org.branch_factory_nm                    as branch_factory_name,      -- 分厂名称
    Prd_AL_Ao_Outflow_Qty_D                  as ao_consumqty_tzq,         -- 氧化铝耗用量_调整前
    Prd_AL_Carbon_Block_Outflow_Qty_D        as anode_carb_consumqty_tzq, -- 阳极炭块耗用量_调整前
    Prd_AL_Alf3_Outflow_Qty_D                as alf3_consumqty_tzq,       -- 氟化铝耗用量_调整前
    Prd_AL_Cryo_Outflow_Qty_D                as cryo_consumqty_tzq,       -- 冰晶石耗用量_调整前
    Prd_AL_Elect_Powder_Outflow_Qty_D        as electro_consumqty_tzq,    -- 电解质块（粉）耗用量_调整前
    Prd_AL_Mgf2_Outflow_Qty_D                as mgf2_consumqty_tzq,       -- 氟化镁耗用量_调整前
    Prd_AL_Caf2_Outflow_Qty_D                as caf2_consumqty_tzq,       -- 氟化钙耗用量_调整前
    Prd_AL_Soda_Ash_Outflow_Qty_D            as soda_ash_consumqty_tzq,   -- 纯碱耗用量_调整前
    Prd_AL_Li2Co3_Outflow_Qty_D              as li2co3_consumqty,         -- 碳酸锂耗用量
    'aloudatacan'                            as source_system,            -- 来源系统
    'sdhq_prd_al_branch_rpt_comp_rawmtr_out' as source_table_name,        -- 来源表名
    concat(metric_time, al_factory_no)       as source_id,                -- 来源ID
    now()                                    as etl_time
from
    aloudatacan.sdhq_prd_al_branch_rpt_comp_rawmtr_out a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
;
/*液态铝产量*/
insert into
    sdhq.dwd_prd_al_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, liq_alum_prod,
     liq_alum_997_prod, source_system, source_table_name, source_id, etl_time)
select
    uuid()                                   as id,
    metric_time                              as dt_date,
    '电解铝'                                 as business_format,
    al_factory_no                            as branch_factory_code, -- 分厂编码
    org.branch_factory_nm                    as branch_factory_name, -- 分厂名称
    Prd_AL_Alum_Liq_Prod_Total_Qty_D         as liq_alum_prod,       -- 液态铝产量
    Prd_AL_Al9970_Above_Qty_D                as liq_alum_997_prod,   -- 液态铝99.70产量
    'aloudatacan'                            as source_system,       -- 来源系统
    'sdhq_prd_al_branch_rpt_factory_alumtap' as source_table_name,   -- 来源表名
    concat(metric_time, al_factory_no)       as source_id,           -- 来源ID
    now()                                    as etl_time
from
    aloudatacan.sdhq_prd_al_branch_rpt_factory_alumtap a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
;
/*补偿量耗用量*/
insert into
    sdhq.dwd_prd_al_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name,
     ao_compens_qty_consumqty, cryo_compens_qty_consumqty, elect_blk_compens_qty_consumqty,
     alf3_compens_qty_consumqty, mgf2_compens_qty_consumqty, caf2_compens_qty_consumqty,
     soda_ash_compens_qty_consumqty, anode_carb_compens_qty_consumqty,
     ao_end_waste_mat_compens_qty_consumqty, tank_startup_compens_electqty_consumqty,
     tank_shutdown_deduct_electqty_consumqty, tank_shutdown_qty, source_system, source_table_name,
     source_id, etl_time)
select
    uuid()                             as id,
    metric_time                        as dt_date,
    '电解铝'                           as business_format,
    al_factory_no                      as branch_factory_code,                     -- 分厂编码
    org.branch_factory_nm              as branch_factory_name,                     -- 分厂名称
    ao_compens_qty                     as ao_compens_qty_consumqty,                --  氧化铝补偿量耗用量
    cryo_compens_qty                   as cryo_compens_qty_consumqty,              -- 冰晶石补偿量耗用量
    elect_powder_compens_qty           as elect_blk_compens_qty_consumqty,         -- 电解质块补偿量耗用量
    alf3_compens_qty                   as alf3_compens_qty_consumqty,              -- 氟化铝补偿量耗用量
    mgf2_compens_qty                   as mgf2_compens_qty_consumqty,              -- 氟化镁补偿量耗用量
    caf2_compens_qty                   as caf2_compens_qty_consumqty,              -- 氟化钙补偿量耗用量
    soda_ash_compens_qty               as soda_ash_compens_qty_consumqty,          -- 纯碱补偿量耗用量
    anode_carb_compens_qty             as anode_carb_compens_qty_consumqty,        -- 阳极炭块补偿量耗用量
    waste_mat_compens_ao               as ao_end_waste_mat_compens_qty_consumqty,  -- 氧化铝末端废料补偿量耗用量
    tank_startup_compens_electqty      as tank_startup_compens_electqty_consumqty, -- 启动槽补偿电量耗用量
    tank_shutdown_deduct_electqty      as tank_shutdown_deduct_electqty_consumqty, -- 停槽扣除电量耗用量
    tank_shutdown_tank_qty             as tank_shutdown_qty,                       -- 停槽数量
    'aloudatacan'                      as source_system,                           -- 来源系统
    'sdhq_prd_al_other_econ_index'     as source_table_name,                       -- 来源表名
    concat(metric_time, al_factory_no) as source_id,                               -- 来源ID
    now()                              as etl_time
from
    aloudatacan.sdhq_prd_al_other_econ_index a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
;
/*综合电量耗用量_调整前*/
insert into
    sdhq.dwd_prd_al_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name,
     compre_electqty_consumqty_tzq, photovol_elect_consumqty, stategrid_elect_consumqty,
     source_system, source_table_name, source_id, etl_time)
select
    uuid()                             as id,
    metric_time                        as dt_date,
    '电解铝'                           as business_format,
    al_factory_no                      as branch_factory_code,           -- 分厂编码
    org.branch_factory_nm              as branch_factory_name,           -- 分厂名称
    CASE al_company_no -- 实际整流电量+生产动力电量
        WHEN 'SDHQ_LYGS_02'
            THEN ifnull(actual_rectif_electqty, 0) + ifnull(manufa_pow_electqty_al2, 0)
        WHEN 'SDHQ_LYGS_04'
            THEN ifnull(actual_rectif_electqty, 0) + ifnull(manufa_pow_electqty_al4, 0)
        ELSE ifnull(actual_rectif_electqty, 0) + ifnull(manufa_pow_electqty, 0)
        END                            as compre_electqty_consumqty_tzq, -- 综合电量耗用量_调整前
    photovol_electconqty               as photovol_elect_consumqty,      -- 光伏电量耗用量
    stategrid_elect                    as stategrid_elect_consumqty,     -- 国网电量耗用量
    'aloudatacan'                      as source_system,                 -- 来源系统
    'sdhq_prd_al_pow_electqty'         as source_table_name,             -- 来源表名
    concat(metric_time, al_factory_no) as source_id,                     -- 来源ID
    now()                              as etl_time
from
    aloudatacan.sdhq_prd_al_pow_electqty a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
;
/*单耗*/
insert into
    sdhq.dwd_prd_al_fact_d_ufd
    (id, dt_date, business_format, branch_factory_code, branch_factory_name, ao_unconsum,
     anode_carb_unconsum, alf3_unconsum, additive_unconsum, source_system, source_table_name,
     source_id, etl_time)
select
    uuid()                                    as id,
    metric_time                               as dt_date,
    '电解铝'                                  as business_format,
    al_factory_no                             as branch_factory_code, -- 分厂编码
    org.branch_factory_nm                     as branch_factory_name, -- 分厂名称
    Prd_AL_Ao_Unconsum_Fty_Qty_D              as ao_unconsum,         -- 氧化铝单耗
    Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D    as anode_carb_unconsum, -- 阳极炭块单耗
    Prd_AL_Alf3_Unconsum_Fty_Qty_D            as alf3_unconsum,       -- 氟化铝单耗
    Prd_AL_Additive_Unconsum_Fty_Qty_D        as additive_unconsum,   -- 添加剂单耗
    'aloudatacan'                             as source_system,       -- 来源系统
    'sdhq_prd_al_branch_rpt_factory_econ_al1' as source_table_name,   -- 来源表名
    concat(metric_time, al_factory_no)        as source_id,           -- 来源ID
    now()                                     as etl_time
from
    (
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al1
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al2_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al2
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al3_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al3zp
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_Al3wq_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al3wq
        where
            al_factory_no = 'SDHQ_LYGS_0307'
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al4
        union all
        select
            metric_time,
            al_factory_no,
            Prd_AL_Ao_Unconsum_Fty_Qty_D,
            Prd_AL_Carbon_Block_Unconsum_Fty_Qty_D,
            Prd_AL_Alf3_Unconsum_Fty_Qty_D,
            Prd_AL_Additive_Unconsum_Fty_Qty_D
        from
            aloudatacan.sdhq_prd_al_branch_rpt_factory_econ_al5
        ) a
    left join sdhq.dim_prd_org_flatten_ufd org on a.al_factory_no = org.branch_factory_no
;