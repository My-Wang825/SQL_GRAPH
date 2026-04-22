/*
 -- 描述：计算站电压日报表_阿尔惠特系统
 -- 开发者：乔凤 
 -- 开发日期：2025-10-14 
 -- 修改者: 
 -- 修改日期：
 -- 修改记录：
 
 */
-- 删除TargetTable已有数据
truncate table sdhq.dwd_prd_dayrpt_ufh;
-- 将SourceTable数据插入TargetTable
-- 插入数据

INSERT INTO
  sdhq.dwd_prd_dayrpt_ufh (
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
    jlid,
    caoh,
    riq,
    shij,
    chejianh,
    fenzh,
    sheddy,
    pingjdy,
    gongzdy,
    dianl,
    dianz,
    zhenzh,
    baid,
    zonggh,
    xialcsh,
    xiall,
    chulshk,
    huanjshk,
    jiagshk,
    jiuxy,
    jiuhj,
    jiuchl,
    jiujg,
    beizh,
    fuytjcsh,
    dianzl,
    jizhxljg,
    xiajl,
    xiaoyddjg,
    dianyshx,
    dianyxx,
    xildy,
    xiaoyddchx,
    yichchx,
    baidchx,
    shoudchx,
    tongxdchx,
    qianlxlcsh,
    guolxlcsh,
    shanshxyjzh,
    xiaoyzcsh,
    taimxshk,
    gongnjcsh,
    gongnjshj,
    muxwy,
    xiaoycsh,
    xiaoychix,
    xiaoyfy,
    xiaoyjy,
    xiaoygh,
    shedxyddjg,
    xiaoyddshj,
    xiaoyshjddshj,
    etl_tm,
    lianjzht,
    caoqdrq,
    caolchd,
    ds
  )
SELECT
  t2.branch_company_no,
  t2.branch_company_nm,
  t2.branch_factory_no,
  t2.branch_factory_nm,
  t2.workshop_no,
  t2.workshop_nm,
  t2.area_no,
  t2.area_nm,
  t2.work_area_no,
  t2.work_area_nm,
  t1.jlid,
  t1.caoh,
  DATE_FORMAT(STR_TO_DATE(t1.riq, '%Y%m%d'), '%Y-%m-%d'),
  t1.shij,
  t1.chejianh,
  t1.fenzh,
  t1.sheddy,
  t1.pingjdy,
  t1.gongzdy,
  t1.dianl,
  t1.dianz,
  t1.zhenzh,
  t1.baid,
  t1.zonggh,
  t1.xialcsh,
  t1.xiall,
  t1.chulshk,
  t1.huanjshk,
  t1.jiagshk,
  t1.jiuxy,
  t1.jiuhj,
  t1.jiuchl,
  t1.jiujg,
  t1.beizh,
  t1.fuytjcsh,
  t1.dianzl,
  t1.jizhxljg,
  t1.xiajl,
  t1.xiaoyddjg,
  t1.dianyshx,
  t1.dianyxx,
  t1.xildy,
  t1.xiaoyddchx,
  t1.yichchx,
  t1.baidchx,
  t1.shoudchx,
  t1.tongxdchx,
  t1.qianlxlcsh,
  t1.guolxlcsh,
  t1.shanshxyjzh,
  t1.xiaoyzcsh,
  t1.taimxshk,
  t1.gongnjcsh,
  t1.gongnjshj,
  t1.muxwy,
  t1.xiaoycsh,
  t1.xiaoychix,
  t1.xiaoyfy,
  t1.xiaoyjy,
  t1.xiaoygh,
  t1.shedxyddjg,
  t1.xiaoyddshj,
  t1.xiaoyshjddshj,
  NOW(),
  t3.lianjzht,
  CASE
    WHEN t3.caoqdrq LIKE '____-_-_-%'
    AND SUBSTR(t3.caoqdrq, 8, 1) = '-'
    AND RIGHT(t3.caoqdrq, 1) ! = ' ' THEN SUBSTR(t3.caoqdrq, 1, 10)
    WHEN LENGTH(t3.caoqdrq) = 11 THEN CONCAT(
      SUBSTR(t3.caoqdrq, 1, 4),
      '-',
      SUBSTR(t3.caoqdrq, 6, 2),
      '-',
      SUBSTR(t3.caoqdrq, 9, 2)
    )
    WHEN LENGTH(t3.caoqdrq) = 9 THEN CONCAT(
      SUBSTR(t3.caoqdrq, 1, 4),
      '-0',
      SUBSTR(t3.caoqdrq, 6, 1),
      '-0',
      SUBSTR(t3.caoqdrq, 8, 1)
    )
    WHEN (SUBSTR(t3.caoqdrq, 8, 1) = '/')
    OR (SUBSTR(t3.caoqdrq, 8, 1) = '/') THEN CONCAT(
      SUBSTR(t3.caoqdrq, 1, 4),
      '-',
      SUBSTR(t3.caoqdrq, 6, 2),
      '-',
      SUBSTR(t3.caoqdrq, 9, 2)
    )
    WHEN (SUBSTR(t3.caoqdrq, 8, 1) = '/')
    OR (SUBSTR(t3.caoqdrq, 8, 1) = '-') THEN CONCAT(
      SUBSTR(t3.caoqdrq, 1, 4),
      '-',
      SUBSTR(t3.caoqdrq, 6, 2),
      '-0',
      SUBSTR(t3.caoqdrq, 9, 1)
    )
    ELSE CONCAT(
      SUBSTR(t3.caoqdrq, 1, 4),
      '-0',
      SUBSTR(t3.caoqdrq, 6, 1),
      '-',
      SUBSTR(t3.caoqdrq, 8, 2)
    )
  END AS caoqdrq,
  t3.caolchd,
  DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m%d')
FROM
  (
    -- 铝一三厂日报表数据
    SELECT
      t1.jlid,
      t1.caoh,
      t1.riq,
      t1.shij,
      t1.chejianh,
      t1.fenzh,
      t1.sheddy,
      t1.pingjdy,
      t1.gongzdy,
      t1.dianl,
      t1.dianz,
      t1.zhenzh,
      t1.baid,
      t1.zonggh,
      t1.xialcsh,
      t1.xiall,
      t1.chulshk,
      t1.huanjshk,
      t1.jiagshk,
      t1.jiuxy,
      t1.jiuhj,
      t1.jiuchl,
      t1.jiujg,
      t1.beizh,
      t1.fuytjcsh,
      t1.dianzl,
      t1.jizhxljg,
      t1.xiajl,
      t1.xiaoyddjg,
      t1.dianyshx,
      t1.dianyxx,
      t1.xildy,
      t1.xiaoyddchx,
      t1.yichchx,
      t1.baidchx,
      t1.shoudchx,
      t1.tongxdchx,
      t1.qianlxlcsh,
      t1.guolxlcsh,
      t1.shanshxyjzh,
      t2.xiaoyzcsh,
      t1.taimxshk,
      t1.gongnjcsh,
      t1.gongnjshj,
      t1.muxwy,
      t3.xiaoycsh,
      t2.xiaoychix,
      t2.xiaoyfy,
      t2.xiaoyjy,
      t2.xiaoygh,
      t2.shedxyddjg,
      t2.xiaoyddshj,
      t1.xiaoyshjddshj,
      t1.branch_company_no
    FROM
      (
        SELECT
                  jlid, --记录号
        caoh, --槽号
        riq, --日期
        shij, --时间
        chejianh, --车间号
        fenzh, --分组
        sheddy, --设定电压
        pingjdy, --平均电压
        gongzdy, --工作电压
        dianl, --电流
        dianz, --电阻
        zhenzh, --针振
        baid, --摆动
        zonggh, --总功耗
        xialcsh, --下料次数
        xiall, --下料量
        chulshk, -- 出铝时刻
        huanjshk, --换极时刻
        jiagshk, --边加工时刻
        jiuxy, --效应距今
        jiuhj, --换极距今
        jiuchl, --出铝距今
        jiujg, --边加工距今
        beizh, --备注
        fuytjcsh, --氟盐添加次数
        dianzl, --电阻率
        jizhxljg, --基准下料间隔
        xiajl, --下降量
        xiaoyddjg, --效应等待间隔
        dianyshx, --电压上限
        dianyxx, --电压下限
        xildy, --系列电压
        xiaoyddchx, --效应等待持续
        yichchx, --异常持续
        baidchx, --摆动持续
        shoudchx, --手动持续
        tongxdchx, --通讯断持续
        qianlxlcsh, --欠量下料次数
        guolxlcsh, --过量下料次数
        shanshxyjzh, --闪烁效应基准
        taimxshk, --~抬母线时刻
        gongnjcsh, --功能急键次数
        gongnjshj, --功能键时间
        muxwy, --母线位移
        -- ifnull(xiaoycsh), --效应次数
        -- xiaoychix, --效应持续
        -- xiaoyfy, --效应峰压
        -- xiaoyjy, --效应均压
        -- xiaoygh, --效应功耗
        -- shedxyddjg, --设定效应等待间隔
        -- xiaoyddshj, --效应等待时间
        xiaoyshjddshj, --效应实际等待时间
        branch_company_no
        FROM
          sdhq.ods_ckxt_l1zpa_aeht_dayrpt
        WHERE
          ds = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m%d')
      ) t1
      LEFT JOIN (
        SELECT
          CAOH,
          RIQ,
          COUNT(*) AS xiaoycsh
        FROM
          sdhq.ods_ckxt_l1zpa_aeht_effectrpt
        WHERE
          ds = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m%d')
          AND CHIX >= 75
          AND FENGZHDY >= 8
        GROUP BY
          CAOH,
          RIQ
      ) t3 ON t1.caoh = t3.CAOH
      AND t1.riq = t3.RIQ
      LEFT JOIN (
        SELECT
          CAOH,
          RIQ,
          SUM(CHIX) AS xiaoychix,
          AVG(FENGZHDY) AS xiaoyfy,
          AVG(PINGJDY) AS xiaoyjy,
          SUM(GONGH) / 10 AS xiaoygh,
          SUM(XIAOYDDSHJ) AS xiaoyddshj,
          AVG(shedxyddjk) AS shedxyddjg,
          SUM(xiaoyshjddshj) AS xiaoyshjddshj,
          COUNT(*) AS xiaoyzcsh
        FROM
          sdhq.ods_ckxt_l1zpa_aeht_effectrpt
        WHERE
          ds = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m%d')
        GROUP BY
          CAOH,
          RIQ
      ) t2 ON t1.caoh = t2.CAOH
      AND t1.riq = t2.RIQ
  ) t1
  LEFT JOIN (
   SELECT
    a.caoh,        -- 槽号
    a.caoqdrq,     -- 槽启动日期
    a.lianjzht,    -- 槽状态
    a.caolchd,
    a.branch_company_no, -- 分公司编码
    CONCAT(SUBSTRING(a.ds, 1, 4), '-', SUBSTRING(a.ds, 5, 2), '-', SUBSTRING(a.ds, 7, 2)) as ds
FROM
    (
        SELECT 
            caoh,        -- 槽号
            caoqdrq,     -- 槽启动日期
            lianjzht,    -- 槽状态
            caolchd,
            branch_company_no, -- 分公司编码
            ds
        FROM 
            sdhq.ods_ckxt_l1zpa_aeht_caotxhdzhb
        WHERE ds = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m%d')
    ) 
  ) t3 ON t1.caoh = t3.caoh 
  AND t1.branch_company_no = t3.branch_company_no
  LEFT JOIN (
    SELECT
      slot_number,
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
    FROM
      sdhq.dim_ly_slot_org_mapping_dfd
  ) t2 ON t1.caoh = t2.slot_number
  AND t1.branch_company_no = t2.branch_company_no;