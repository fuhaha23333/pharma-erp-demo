CREATE TABLE drug (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',

    drug_code VARCHAR(32) NOT NULL COMMENT '药品编码，系统内部唯一编码',
    drug_name VARCHAR(100) NOT NULL COMMENT '药品名称，页面展示名称',
    generic_name VARCHAR(100) NOT NULL COMMENT '药品通用名称',
    approval_no VARCHAR(64) NOT NULL COMMENT '批准文号/进口注册证号',
    dosage_form VARCHAR(50) NOT NULL COMMENT '剂型，如片剂、胶囊剂、颗粒剂',
    specification VARCHAR(100) NOT NULL COMMENT '规格，如0.25g*24粒',
    manufacturer VARCHAR(150) NOT NULL COMMENT '生产厂家，第一版先用字符串',
    basic_unit VARCHAR(20) NOT NULL COMMENT '基本单位，如盒、瓶、支',
    storage_condition VARCHAR(50) NOT NULL COMMENT '储存条件，如常温、阴凉、冷藏、冷冻',

    status VARCHAR(20) NOT NULL DEFAULT 'DISABLED' COMMENT '状态：ENABLED启用，DISABLED停用',
    remark VARCHAR(500) DEFAULT NULL COMMENT '备注',

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0未删除，1已删除',

    PRIMARY KEY (id),
    UNIQUE KEY uk_drug_code (drug_code),
    KEY idx_drug_name (drug_name),
    KEY idx_generic_name (generic_name),
    KEY idx_approval_no (approval_no),
    KEY idx_manufacturer (manufacturer),
    KEY idx_status (status),
    KEY idx_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='药品档案表';
