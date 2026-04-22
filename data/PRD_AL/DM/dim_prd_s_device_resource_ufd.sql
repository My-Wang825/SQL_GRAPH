/*
 设备资源信息表
 开发者：乔凤
 开发日期：2026/01/03
 生产域的设备信息
 */

-- 删除TargetTable已有数据
TRUNCATE TABLE dim_prd_s_device_resource_ufd;

-- 将SourceTable数据插入TargetTable
insert into sdhq.dim_prd_s_device_resource_ufd
SELECT
    ID,                                    -- 主键
    DEVICE_ID,                             -- 设备ID
    DEVICE_NAME,                           -- 设备名称
    PARENT_DEVICE_ID,                      -- 父设备标识;默认-1:无父级关系
    COMPANY_ID,                            -- 所属公司/车间ID;默认-1：无所属公司/车间关系
    FULL_COMPANY_ID,                       -- 所属公司/车间名称;默认-1：无所属公司/车间关系
    DEVICE_CODE,                           -- 设备编码
    DEVICE_SERIAL_NO,                      -- 设备序列号
    DEVICE_MODEL,                          -- 设备型号
    DEVICE_MANUFACT,                       -- 生产厂商
    DEVICE_PRICE,                          -- 设备价格
    MADE_TIME,                             -- 生产日期
    USING_TIME,                            -- 投产日期
    FIX_TIME,                              -- 保修期至
    FIX_CYCLE,                             -- 大修周期
    LIFE_EXPECTANCY,                       -- 预计寿命
    DEVICE_STATUS,                         -- 状态;0有效，1删除
    SERIAL_NUMBER,                         -- 出厂编号
    MAJOR_TYPE,                            -- 重要类型
    DEVICE_TYPE,                           -- 设备类别
    PARA_TYPE,                             -- 参数类别
    CREATE_TIME,                           -- 创建时间
    CREATE_OPER,                           -- 创建人
    UPDATE_TIME,                           -- 更新时间
    UPDATE_OPER,                           -- 最后修改人
    CURRENT_TIMESTAMP AS etl_time          -- ETL同步时间
FROM
  sdhq.ods_ysapp_s_device_resource_ufd;