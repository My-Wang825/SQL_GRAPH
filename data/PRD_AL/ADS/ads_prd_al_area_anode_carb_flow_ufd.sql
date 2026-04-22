/*
 -- 描述：综合分厂阳极碳块流量统计
 -- 开发者：乔凤 
 -- 开发日期：2026-01-06
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 */


truncate table sdhq.ads_prd_al_area_anode_carb_flow_ufd;

-- 将SourceTable数据插入TargetTable
INSERT INTO
  ads_prd_al_area_anode_carb_flow_ufd (
    id,
    --  '主键',
    data_dt,
    -- '数据日期',
    company_no,
    ---- '公司编码',
    factory_no,
    ---- '分厂编码',
    series_no,
    -- '系列编码',
    area_no,
    -- '区域编码',
    company_nm,
    ---- '公司名称',
    factory_nm,
    -- '分厂名称',
    series_nm,
    -- '系列名称',
    area_nm,
    -- '区域名称',
    standard,
    -- '规格',
    day_in,
    -- '当日流入-块',
    day_in_t,
    -- '当日流入-吨',
    day_out,
    -- '当日流入-块',
    day_out_t -- '当日流入-吨'
  )
SELECT
  CONCAT_WS(
    '',
    IF(t1.data_dt IS NULL, t2.data_dt, t1.data_dt),
    IF(t1.company_no IS NULL, t2.company_no, t1.company_no),
    IF(t1.factory_no IS NULL, t2.factory_no, t1.factory_no),
    IF(t1.area_no IS NULL, t2.area_no, t1.area_no),
    IF(t1.standard IS NULL, t2.standard, t1.standard)
  ) AS id,
  IF(t1.data_dt IS NULL, t2.data_dt, t1.data_dt) AS data_dt,
  IF(t1.company_no IS NULL, t2.company_no, t1.company_no) AS company_no,
  IF(t1.factory_no IS NULL, t2.factory_no, t1.factory_no) AS factory_no,
  IF(t1.series_no IS NULL, t2.series_no, t1.series_no) AS series_no,
  IF(t1.area_no IS NULL, t2.area_no, t1.area_no) AS area_no,
  IF(t1.company_nm IS NULL, t2.company_nm, t1.company_nm) AS company_nm,
  IF(t1.factory_nm IS NULL, t2.factory_nm, t1.factory_nm) AS factory_nm,
  IF(t1.series_nm IS NULL, t2.series_nm, t1.series_nm) AS series_nm,
  IF(t1.area_nm IS NULL, t2.area_nm, t1.area_nm) AS area_nm,
  IF(t1.standard IS NULL, t2.standard, t1.standard) AS standard,
  IF(t1.day_in IS NULL, 0, t1.day_in) AS day_in,
  IF(t1.day_in_t IS NULL, 0, t1.day_in_t) AS day_in_t,
  IF(t2.day_out IS NULL, 0, t2.day_out) AS day_out,
  IF(t2.day_out_t IS NULL, 0, t2.day_out_t) AS day_out_t
FROM
  (
    SELECT
      SUBSTR(x_rkrq, 1, 10) AS data_dt,
      company_no,
      company_nm,
      workshop_no AS factory_no,
      workshop_nm AS factory_nm,
      workshop_no AS series_no,
      workshop_nm AS series_nm,
      workshop_no AS area_no,
      workshop_nm AS area_nm,
      x_ggxh AS standard,
      SUM(x_js) AS day_in,
      SUM(CAST(x_weight AS DECIMAL(18, 3))) AS day_in_t
    FROM
      sdhq.dwd_prd_al_yjtkrksjb_ufd
    WHERE
      company_no IS NOT NULL
    GROUP BY
      SUBSTR(x_rkrq, 1, 10),
      company_no,
      company_nm,
      workshop_no,
      workshop_nm,
      x_ggxh
  ) t1
FULL JOIN (
    SELECT
      SUBSTR(x_date, 1, 10) AS data_dt,
      branch_company_no AS company_no,
      branch_company_nm AS company_nm,
      workshop_no AS factory_no,
      workshop_nm AS factory_nm,
      workshop_no AS series_no,
      workshop_nm AS series_nm,
      workshop_no AS area_no,
      workshop_nm AS area_nm,
      x_ggxh AS standard,
      SUM(
        CASE
          WHEN (
            SUBSTR(x_date, 1, 10) BETWEEN '2024-12-26' AND '2024-12-27'
            AND branch_company_no = '104006'
            AND x_cklx = '阳极碳块退块出库'
          ) THEN 0
          ELSE x_js
        END
      ) AS day_out,
      SUM(
        CASE
          WHEN (
            SUBSTR(x_date, 1, 10) BETWEEN '2024-12-26' AND '2024-12-27'
            AND branch_company_no = '104006'
            AND x_cklx = '阳极碳块退块出库'
          ) THEN 0
          ELSE CAST(x_ckzl AS DECIMAL(18, 3))
        END
      ) AS day_out_t
    FROM
      sdhq.dwd_prd_al_yjtkcksjb_ufd
    WHERE
      branch_company_no IS NOT NULL
    GROUP BY
      SUBSTR(x_date, 1, 10),
      branch_company_no,
      branch_company_nm,
      workshop_no,
      workshop_nm,
      x_ggxh
  ) t2 ON t1.factory_no = t2.factory_no
  AND t1.area_no = t2.area_no
  AND t1.data_dt = t2.data_dt
  AND t1.standard = t2.standard;