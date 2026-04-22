/*
 
 -- 描述：产销量及能耗统计表
 -- 开发者：乔凤 
 -- 开发日期：2025-10-31 
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */

 truncate table sdhq.ads_prd_al_comp_prod_cons_day_ufd;
-- 将SourceTable数据插入TargetTable
-- 插入数据
INSERT INTO
  sdhq.ads_prd_al_comp_prod_cons_day_ufd(
      data_dt,
      branch_company_no,
      branch_company_nm,
      factory_no,
      factory_nm,
      to_workshop,
      export_water,
      to_hz,
      weiwai,
      weituo,
      xcl_qlhl,
      ht_to_hq
  )
    SELECT
      t1.data_dt,
      t1.branch_company_no,
      t1.branch_company_nm,
      case
        when t1.branch_company_no = '104009'
        and t1.branch_company_nm = '云南宏启' then '综合分厂'
        else t2.factory_no
      end as factory_no,
      case
        when t1.branch_company_no = '104009'
        and t1.branch_company_nm = '云南宏启' then '综合分厂'
        else t2.factory_nm
      end as factory_nm,
      t1.to_workshop,
      t1.export_water,
      t1.to_hz,
      t1.weiwai_water as weiwai,
      t1.weituo_water as weituo,
      t1.xcl_qlhl,
      t1.ht_to_hq
from
  (
    SELECT
      t1.data_dt,
      t1.branch_company_no,
      t1.branch_company_nm,
      t1.to_workshop,
      t1.export_water,
      t2.to_hz,
      t1.weiwai_water,
      t1.weituo_water,
      t1.xcl_qlhl,
      t1.ht_to_hq
    from
      (
        SELECT
          substr(
            from_unixtime(
              unix_timestamp(x_pzrq, 'yyyy-MM-dd HH:mm:ss') - 28800
            ),
            1,
            10
          ) as data_dt,
          branch_company_no,
          branch_company_nm,
          case
            when branch_company_no = 'SDHQ_LYGS_03'
            and branch_company_nm = '铝业三公司' then sum(if(x_ywlx in ('内转铸造'), x_jz, 0))
            when branch_company_no = 'SDHQ_LYGS_04' then sum(if(x_ywlx in ('内转铸造'), x_jz, 0))
            else sum(if(x_ywlx in ('受托加工出库', '内转铸造'), x_jz, 0))
          end as to_workshop,
          case
            when branch_company_no = 'SDHQ_LYGS_03'
            and branch_company_nm = '铝业三公司' then sum(if(x_ywlx in ('外销'), x_jz, 0))
            else sum(if(x_ywlx in ('外销', '外销1'), x_jz, 0))
          end as export_water,
          sum(if(x_ywlx in ('委外加工'), x_jz, 0)) as weiwai_water,
          sum(if(x_ywlx in ('受托加工出库'), x_jz, 0)) as weituo_water,
          sum(if(x_ywlx in ('外销1'), x_jz, 0)) as xcl_qlhl,
          case
            when branch_company_no = 'SDHQ_LYGS_06' then sum(
              if(
                x_ywlx in ('外销'),
                if(x_kh in ('1010101030101'), x_jz, 0),
                0
              )
            )
          end as ht_to_hq
        from
          sdhq.dwd_prd_al_lsclsjb_dfd
        where
          ds = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)
          and branch_company_no is not null
          and x_kh <> '11938'
        group by
          substr(
            from_unixtime(
              unix_timestamp(x_pzrq, 'yyyy-MM-dd HH:mm:ss') - 28800
            ),
            1,
            10
          ),
          branch_company_no,
          branch_company_nm
      ) t1
      left join(
        SELECT
          substr(
            from_unixtime(
              unix_timestamp(x_pzrq, 'yyyy-MM-dd HH:mm:ss') - 28800
            ),
            1,
            10
          ) as data_dt,
          branch_company_no,
          branch_company_nm,
          sum(if(x_ywlx in ('外销', '外销1'), x_jz, 0)) as to_hz
        from
          sdhq.dwd_prd_al_lsclsjb_dfd
        where
          ds = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)
          and branch_company_no is not null
          and x_kh = '11938'
        group by
          substr(
            from_unixtime(
              unix_timestamp(x_pzrq, 'yyyy-MM-dd HH:mm:ss') - 28800
            ),
            1,
            10
          ),
          branch_company_no,
          branch_company_nm
      ) t2 on t1.data_dt = t2.data_dt
      and t1.branch_company_no = t2.branch_company_no
  ) t1
  left join (
    SELECT
      distinct branch_company_no,
      case
        when branch_company_no = 'SDHQ_LYGS_03'
        and factory_nm like '魏桥%' then '铝业三公司（魏桥侧）'
        else branch_company_nm
      end as branch_company_nm,
      factory_no,
      factory_nm
    from
      sdhq.dim_prd_al_report_org_ufd
    where
      factory_nm like '%综合%'
  ) t2 on t1.branch_company_no = t2.branch_company_no
  and t1.branch_company_nm = t2.branch_company_nm