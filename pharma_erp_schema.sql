-- 药品供应链资质审核与追溯系统数据库设计
-- 依据：药品供应链资质审核与追溯系统需求分析.md
-- 数据库：MySQL 8.0.16+
-- 边界：单企业、单体应用；第三阶段多租户 SaaS 仅保留演进空间，本文件不实现租户隔离。
-- 用法：面向空数据库执行。本文件不删除旧表，也不是现有迁移脚本的增量补丁。

CREATE DATABASE IF NOT EXISTS pharma_erp
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE pharma_erp;

SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

-- ============================================================================
-- 1. 组织、用户与 RBAC
-- ============================================================================

CREATE TABLE sys_department (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '部门主键',
    parent_id BIGINT NULL COMMENT '上级部门；根节点代表企业',
    department_code VARCHAR(32) NOT NULL COMMENT '部门编码',
    department_name VARCHAR(100) NOT NULL COMMENT '部门名称',
    department_type VARCHAR(16) NOT NULL DEFAULT 'DEPARTMENT' COMMENT 'ENTERPRISE或DEPARTMENT',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '同级排序',
    created_by BIGINT NULL COMMENT '创建人；初始化阶段允许为空',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_department_code UNIQUE (department_code),
    CONSTRAINT ck_sys_department_type
        CHECK (department_type IN ('ENTERPRISE', 'DEPARTMENT')),
    CONSTRAINT ck_sys_department_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_sys_department_parent_status (parent_id, status),
    CONSTRAINT fk_sys_department_parent
        FOREIGN KEY (parent_id) REFERENCES sys_department (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '企业内部组织与部门树';

CREATE TABLE sys_user (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户主键',
    username VARCHAR(64) NOT NULL COMMENT '登录账号',
    display_name VARCHAR(100) NOT NULL COMMENT '用户姓名',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希，不保存明文密码',
    department_id BIGINT NOT NULL COMMENT '所属部门',
    mobile VARCHAR(32) NULL COMMENT '手机号码',
    email VARCHAR(128) NULL COMMENT '电子邮箱',
    status VARCHAR(16) NOT NULL DEFAULT 'DISABLED' COMMENT 'ACTIVE、DISABLED或LOCKED',
    failed_login_count INT NOT NULL DEFAULT 0 COMMENT '连续登录失败次数',
    locked_until DATETIME(3) NULL COMMENT '账号锁定截止时间（UTC）',
    last_login_at DATETIME(3) NULL COMMENT '最后登录时间（UTC）',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_user_username UNIQUE (username),
    CONSTRAINT ck_sys_user_status
        CHECK (status IN ('ACTIVE', 'DISABLED', 'LOCKED')),
    CONSTRAINT ck_sys_user_failed_login
        CHECK (failed_login_count >= 0),
    INDEX idx_sys_user_department_status (department_id, status),
    INDEX idx_sys_user_status (status),
    CONSTRAINT fk_sys_user_department
        FOREIGN KEY (department_id) REFERENCES sys_department (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_created_by
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_updated_by
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '系统用户';

CREATE TABLE sys_role (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色主键',
    role_code VARCHAR(32) NOT NULL COMMENT '角色编码',
    role_name VARCHAR(100) NOT NULL COMMENT '角色名称',
    risk_level VARCHAR(16) NOT NULL DEFAULT 'NORMAL' COMMENT 'NORMAL或HIGH',
    description VARCHAR(500) NULL COMMENT '角色说明',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    is_builtin TINYINT NOT NULL DEFAULT 0 COMMENT '是否内置角色：0否，1是',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_code UNIQUE (role_code),
    CONSTRAINT uk_sys_role_name UNIQUE (role_name),
    CONSTRAINT ck_sys_role_risk CHECK (risk_level IN ('NORMAL', 'HIGH')),
    CONSTRAINT ck_sys_role_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    CONSTRAINT ck_sys_role_builtin CHECK (is_builtin IN (0, 1)),
    INDEX idx_sys_role_status (status),
    CONSTRAINT fk_sys_role_created_by
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_updated_by
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = 'RBAC角色';

CREATE TABLE sys_permission (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '权限主键',
    parent_id BIGINT NULL COMMENT '父权限，用于菜单与页面层级',
    permission_code VARCHAR(64) NOT NULL COMMENT '权限编码',
    permission_name VARCHAR(160) NOT NULL COMMENT '权限名称',
    permission_type VARCHAR(16) NOT NULL COMMENT 'MENU、PAGE、BUTTON、DATA或ACTION',
    module_code VARCHAR(32) NOT NULL COMMENT '所属业务模块',
    resource_key VARCHAR(160) NULL COMMENT '前端资源或后端鉴权标识',
    route_path VARCHAR(255) NULL COMMENT '前端路由；非页面权限可为空',
    http_method VARCHAR(16) NULL COMMENT 'HTTP方法；接口动作权限可使用',
    api_pattern VARCHAR(255) NULL COMMENT 'API路径模式',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '同级排序',
    description VARCHAR(500) NULL COMMENT '权限说明',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_permission_code UNIQUE (permission_code),
    CONSTRAINT ck_sys_permission_type
        CHECK (permission_type IN ('MENU', 'PAGE', 'BUTTON', 'DATA', 'ACTION')),
    CONSTRAINT ck_sys_permission_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_sys_permission_parent_type (parent_id, permission_type),
    INDEX idx_sys_permission_module_type (module_code, permission_type),
    INDEX idx_sys_permission_resource (resource_key),
    CONSTRAINT fk_sys_permission_parent
        FOREIGN KEY (parent_id) REFERENCES sys_permission (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_permission_created_by
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_permission_updated_by
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '菜单、页面、按钮、数据及操作权限目录';

CREATE TABLE sys_role_assignment (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色授权申请主键',
    assignment_no VARCHAR(40) NOT NULL COMMENT '授权申请编号',
    target_user_id BIGINT NOT NULL COMMENT '被授权用户',
    role_id BIGINT NOT NULL COMMENT '申请授予或撤销的角色',
    assignment_type VARCHAR(16) NOT NULL COMMENT 'GRANT或REVOKE',
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT '申请状态',
    requested_by BIGINT NOT NULL COMMENT '申请人',
    requested_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '申请时间（UTC）',
    approved_by BIGINT NULL COMMENT '负责人审批人',
    approved_at DATETIME(3) NULL COMMENT '审批时间（UTC）',
    approval_result VARCHAR(16) NULL COMMENT 'APPROVED、REJECTED或RETURNED',
    approval_opinion VARCHAR(1000) NULL COMMENT '审批意见或驳回原因',
    executed_by BIGINT NULL COMMENT '管理员授权执行人',
    executed_at DATETIME(3) NULL COMMENT '授权执行时间（UTC）',
    execution_error VARCHAR(1000) NULL COMMENT '授权执行失败原因',
    valid_from DATETIME(3) NULL COMMENT '授权生效时间（UTC）',
    valid_to DATETIME(3) NULL COMMENT '授权失效时间（UTC）；长期授权为空',
    reason VARCHAR(500) NOT NULL COMMENT '申请原因',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_assignment_no UNIQUE (assignment_no),
    CONSTRAINT ck_sys_role_assignment_type
        CHECK (assignment_type IN ('GRANT', 'REVOKE')),
    CONSTRAINT ck_sys_role_assignment_status
        CHECK (status IN (
            'PENDING_APPROVAL', 'PENDING_EXECUTION', 'REJECTED',
            'RETURNED', 'EXECUTED', 'EXECUTION_FAILED', 'CANCELLED'
        )),
    CONSTRAINT ck_sys_role_assignment_result
        CHECK (approval_result IS NULL OR approval_result IN ('APPROVED', 'REJECTED', 'RETURNED')),
    CONSTRAINT ck_sys_role_assignment_validity
        CHECK (valid_to IS NULL OR (valid_from IS NOT NULL AND valid_from <= valid_to)),
    CONSTRAINT ck_sys_role_assignment_approve_pair
        CHECK ((approved_by IS NULL) = (approved_at IS NULL)),
    CONSTRAINT ck_sys_role_assignment_execute_pair
        CHECK ((executed_by IS NULL) = (executed_at IS NULL)),
    CONSTRAINT ck_sys_role_assignment_request_sod
        CHECK (approved_by IS NULL OR approved_by <> requested_by),
    CONSTRAINT ck_sys_role_assignment_execute_sod
        CHECK (approved_by IS NULL OR executed_by IS NULL OR approved_by <> executed_by),
    INDEX idx_sys_role_assignment_target (target_user_id, status),
    INDEX idx_sys_role_assignment_role (role_id, status),
    INDEX idx_sys_role_assignment_status_time (status, requested_at),
    CONSTRAINT fk_sys_role_assignment_target
        FOREIGN KEY (target_user_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_role
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_requester
        FOREIGN KEY (requested_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_approver
        FOREIGN KEY (approved_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_executor
        FOREIGN KEY (executed_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '高风险角色申请、审批与管理员授权记录';

CREATE TABLE sys_user_role (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户角色关系主键',
    user_id BIGINT NOT NULL COMMENT '用户',
    role_id BIGINT NOT NULL COMMENT '角色',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE、REVOKED或EXPIRED',
    valid_from DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '生效时间（UTC）',
    valid_to DATETIME(3) NULL COMMENT '失效时间（UTC）',
    source_assignment_id BIGINT NULL COMMENT '来源授权申请',
    created_by BIGINT NULL COMMENT '授权执行人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_user_role UNIQUE (user_id, role_id),
    CONSTRAINT uk_sys_user_role_assignment UNIQUE (source_assignment_id),
    CONSTRAINT ck_sys_user_role_status
        CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
    CONSTRAINT ck_sys_user_role_validity
        CHECK (valid_to IS NULL OR valid_from <= valid_to),
    INDEX idx_sys_user_role_user (user_id, status, valid_to),
    INDEX idx_sys_user_role_role (role_id, status, valid_to),
    CONSTRAINT fk_sys_user_role_user
        FOREIGN KEY (user_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_role
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_assignment
        FOREIGN KEY (source_assignment_id) REFERENCES sys_role_assignment (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_created_by
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_updated_by
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '用户与角色的有效授权关系';

CREATE TABLE sys_role_permission (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色权限关系主键',
    role_id BIGINT NOT NULL COMMENT '角色',
    permission_id BIGINT NOT NULL COMMENT '权限',
    created_by BIGINT NULL COMMENT '配置人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '配置时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_permission UNIQUE (role_id, permission_id),
    INDEX idx_sys_role_permission_permission (permission_id),
    CONSTRAINT fk_sys_role_permission_role
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_permission_permission
        FOREIGN KEY (permission_id) REFERENCES sys_permission (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_permission_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '角色权限关系';

CREATE TABLE sys_role_conflict (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '互斥规则主键',
    role_a_id BIGINT NOT NULL COMMENT '互斥角色A',
    role_b_id BIGINT NOT NULL COMMENT '互斥角色B',
    conflict_scope VARCHAR(16) NOT NULL DEFAULT 'USER' COMMENT 'USER或BUSINESS',
    reason VARCHAR(500) NOT NULL COMMENT '互斥原因',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_conflict_pair UNIQUE (role_a_id, role_b_id),
    CONSTRAINT ck_sys_role_conflict_order CHECK (role_a_id < role_b_id),
    CONSTRAINT ck_sys_role_conflict_scope
        CHECK (conflict_scope IN ('USER', 'BUSINESS')),
    CONSTRAINT ck_sys_role_conflict_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_sys_role_conflict_b (role_b_id, status),
    CONSTRAINT fk_sys_role_conflict_a
        FOREIGN KEY (role_a_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_conflict_b
        FOREIGN KEY (role_b_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_conflict_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_conflict_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '角色互斥与不相容职责规则';

CREATE TABLE sys_permission_change_log (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '权限变更日志主键',
    change_no VARCHAR(40) NOT NULL COMMENT '变更流水号',
    operator_id BIGINT NOT NULL COMMENT '变更操作人',
    target_type VARCHAR(32) NOT NULL COMMENT 'USER_ROLE、ROLE_PERMISSION、ROLE或PERMISSION',
    target_id BIGINT NOT NULL COMMENT '被变更对象主键',
    change_type VARCHAR(16) NOT NULL COMMENT 'CREATE、UPDATE、GRANT、REVOKE、ENABLE或DISABLE',
    change_reason VARCHAR(500) NOT NULL COMMENT '变更原因',
    before_data JSON NULL COMMENT '变更前快照',
    after_data JSON NULL COMMENT '变更后快照',
    occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发生时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_permission_change_no UNIQUE (change_no),
    CONSTRAINT ck_sys_permission_change_target
        CHECK (target_type IN ('USER_ROLE', 'ROLE_PERMISSION', 'ROLE', 'PERMISSION')),
    CONSTRAINT ck_sys_permission_change_type
        CHECK (change_type IN ('CREATE', 'UPDATE', 'GRANT', 'REVOKE', 'ENABLE', 'DISABLE')),
    INDEX idx_sys_permission_change_target (target_type, target_id, occurred_at),
    INDEX idx_sys_permission_change_operator (operator_id, occurred_at),
    CONSTRAINT fk_sys_permission_change_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '不可覆盖的权限变更日志';

CREATE TABLE sys_attachment (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '附件主键',
    attachment_no VARCHAR(40) NOT NULL COMMENT '附件业务编号',
    business_type VARCHAR(32) NOT NULL COMMENT '关联业务类型',
    business_id BIGINT NOT NULL COMMENT '关联业务主键',
    category VARCHAR(32) NOT NULL COMMENT 'LICENSE、AUTHORIZATION、REVIEW、ACCEPTANCE或OTHER',
    original_name VARCHAR(255) NOT NULL COMMENT '原文件名',
    storage_key VARCHAR(500) NOT NULL COMMENT '对象存储键或受控文件路径',
    content_type VARCHAR(128) NOT NULL COMMENT 'MIME类型',
    file_size BIGINT NOT NULL COMMENT '文件字节数',
    sha256 VARCHAR(64) NOT NULL COMMENT '文件SHA-256摘要',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或INVALIDATED',
    uploaded_by BIGINT NOT NULL COMMENT '上传人',
    uploaded_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '上传时间（UTC）',
    invalidated_by BIGINT NULL COMMENT '作废人',
    invalidated_at DATETIME(3) NULL COMMENT '作废时间（UTC）',
    invalid_reason VARCHAR(500) NULL COMMENT '作废原因',

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_attachment_no UNIQUE (attachment_no),
    CONSTRAINT ck_sys_attachment_category
        CHECK (category IN ('LICENSE', 'AUTHORIZATION', 'REVIEW', 'ACCEPTANCE', 'OTHER')),
    CONSTRAINT ck_sys_attachment_status
        CHECK (status IN ('ACTIVE', 'INVALIDATED')),
    CONSTRAINT ck_sys_attachment_size CHECK (file_size >= 0),
    CONSTRAINT ck_sys_attachment_invalidate_pair
        CHECK ((invalidated_by IS NULL) = (invalidated_at IS NULL)),
    INDEX idx_sys_attachment_business (business_type, business_id, status),
    INDEX idx_sys_attachment_sha256 (sha256),
    CONSTRAINT fk_sys_attachment_uploader
        FOREIGN KEY (uploaded_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_attachment_invalidator
        FOREIGN KEY (invalidated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '资质、授权、审核和验收附件元数据';

CREATE TABLE sys_operation_log (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '操作日志主键',
    request_id VARCHAR(64) NOT NULL COMMENT '请求或链路追踪ID',
    operator_id BIGINT NULL COMMENT '操作人；未认证请求允许为空',
    module_code VARCHAR(32) NOT NULL COMMENT '业务模块',
    operation_type VARCHAR(32) NOT NULL COMMENT 'CREATE、UPDATE、SUBMIT、REVIEW等动作',
    business_type VARCHAR(32) NULL COMMENT '业务对象类型',
    business_id BIGINT NULL COMMENT '业务对象主键',
    operation_summary VARCHAR(500) NOT NULL COMMENT '操作内容摘要',
    before_data JSON NULL COMMENT '修改前数据',
    after_data JSON NULL COMMENT '修改后数据',
    success TINYINT NOT NULL COMMENT '是否成功：0否，1是',
    failure_reason VARCHAR(1000) NULL COMMENT '失败原因',
    client_ip VARCHAR(64) NULL COMMENT '客户端IP',
    user_agent VARCHAR(500) NULL COMMENT '客户端User-Agent',
    occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '操作时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT ck_sys_operation_log_success CHECK (success IN (0, 1)),
    INDEX idx_sys_operation_log_request (request_id),
    INDEX idx_sys_operation_log_operator (operator_id, occurred_at),
    INDEX idx_sys_operation_log_business (business_type, business_id, occurred_at),
    INDEX idx_sys_operation_log_time (occurred_at),
    CONSTRAINT fk_sys_operation_log_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '关键操作追加式审计日志';

CREATE TABLE business_status_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '状态历史主键',
    business_type VARCHAR(32) NOT NULL COMMENT '业务对象类型',
    business_id BIGINT NOT NULL COMMENT '业务对象主键',
    business_no VARCHAR(64) NULL COMMENT '业务编号快照',
    from_status VARCHAR(32) NULL COMMENT '原状态；创建事件可为空',
    to_status VARCHAR(32) NOT NULL COMMENT '新状态',
    change_reason VARCHAR(500) NULL COMMENT '变更原因',
    operator_id BIGINT NULL COMMENT '操作人；系统任务可为空',
    occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发生时间（UTC）',

    PRIMARY KEY (id),
    INDEX idx_business_status_object (business_type, business_id, occurred_at),
    INDEX idx_business_status_operator (operator_id, occurred_at),
    CONSTRAINT fk_business_status_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '关键业务状态变化的不可覆盖历史';

-- ============================================================================
-- 2. 药品、供应商、客户与仓储主数据
-- ============================================================================

CREATE TABLE manufacturer (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '生产企业主键',
    manufacturer_code VARCHAR(32) NOT NULL COMMENT '生产企业编码',
    manufacturer_name VARCHAR(200) NOT NULL COMMENT '生产企业名称',
    unified_social_credit_code VARCHAR(32) NULL COMMENT '统一社会信用代码',
    production_license_no VARCHAR(64) NULL COMMENT '药品生产许可证号',
    contact_name VARCHAR(100) NULL COMMENT '联系人',
    contact_phone VARCHAR(32) NULL COMMENT '联系电话',
    address VARCHAR(500) NULL COMMENT '企业地址',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_manufacturer_code UNIQUE (manufacturer_code),
    CONSTRAINT uk_manufacturer_credit UNIQUE (unified_social_credit_code),
    CONSTRAINT ck_manufacturer_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_manufacturer_name (manufacturer_name),
    CONSTRAINT fk_manufacturer_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_manufacturer_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '药品生产企业档案';

CREATE TABLE drug (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '药品主键',
    drug_code VARCHAR(32) NOT NULL COMMENT '系统药品编码',
    drug_name VARCHAR(160) NOT NULL COMMENT '药品商品名称',
    generic_name VARCHAR(160) NOT NULL COMMENT '药品通用名称',
    approval_no VARCHAR(64) NOT NULL COMMENT '批准文号或进口注册证号',
    dosage_form VARCHAR(64) NOT NULL COMMENT '剂型',
    specification VARCHAR(160) NOT NULL COMMENT '规格',
    manufacturer_id BIGINT NOT NULL COMMENT '生产企业',
    basic_unit VARCHAR(32) NOT NULL COMMENT '基本计量单位',
    storage_condition VARCHAR(100) NOT NULL COMMENT '储存条件',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT、ACTIVE或DISABLED',
    remark VARCHAR(1000) NULL COMMENT '备注',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_drug_code UNIQUE (drug_code),
    CONSTRAINT uk_drug_approval_spec UNIQUE (approval_no, specification),
    CONSTRAINT ck_drug_status CHECK (status IN ('DRAFT', 'ACTIVE', 'DISABLED')),
    INDEX idx_drug_name (drug_name),
    INDEX idx_drug_generic_name (generic_name),
    INDEX idx_drug_manufacturer_status (manufacturer_id, status),
    CONSTRAINT fk_drug_manufacturer
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_drug_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_drug_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '药品主数据';

CREATE TABLE supplier (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商主键',
    supplier_code VARCHAR(32) NOT NULL COMMENT '供应商编码',
    supplier_name VARCHAR(200) NOT NULL COMMENT '企业名称',
    supplier_type VARCHAR(16) NOT NULL COMMENT 'PRODUCTION或WHOLESALE',
    unified_social_credit_code VARCHAR(32) NOT NULL COMMENT '统一社会信用代码',
    contact_name VARCHAR(100) NULL COMMENT '联系人',
    contact_phone VARCHAR(32) NULL COMMENT '联系电话',
    contact_email VARCHAR(128) NULL COMMENT '联系邮箱',
    address VARCHAR(500) NULL COMMENT '企业地址',
    qualification_status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '供应商资质状态',
    approved_at DATETIME(3) NULL COMMENT '最近审核通过时间（UTC）',
    valid_until DATE NULL COMMENT '综合资质有效期截止日',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_supplier_code UNIQUE (supplier_code),
    CONSTRAINT uk_supplier_credit UNIQUE (unified_social_credit_code),
    CONSTRAINT ck_supplier_type
        CHECK (supplier_type IN ('PRODUCTION', 'WHOLESALE')),
    CONSTRAINT ck_supplier_qualification_status
        CHECK (qualification_status IN (
            'DRAFT', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'EXPIRED', 'DISABLED'
        )),
    INDEX idx_supplier_name (supplier_name),
    INDEX idx_supplier_qualification (qualification_status, valid_until),
    CONSTRAINT fk_supplier_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_supplier_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '供应商企业档案及综合资质状态';

CREATE TABLE supplier_qualification (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商资质主键',
    supplier_id BIGINT NOT NULL COMMENT '供应商',
    qualification_type VARCHAR(32) NOT NULL COMMENT '资质类型',
    certificate_no VARCHAR(100) NOT NULL COMMENT '证照或授权文件编号',
    issuing_authority VARCHAR(200) NULL COMMENT '发证机关',
    issued_on DATE NULL COMMENT '发证日期',
    valid_from DATE NULL COMMENT '有效期开始日',
    valid_until DATE NULL COMMENT '有效期截止日；长期有效可为空',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT、VALID、EXPIRED或REVOKED',
    remark VARCHAR(500) NULL COMMENT '备注',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_supplier_qualification_cert
        UNIQUE (supplier_id, qualification_type, certificate_no),
    CONSTRAINT ck_supplier_qualification_type
        CHECK (qualification_type IN (
            'BUSINESS_LICENSE', 'DRUG_PRODUCTION_LICENSE',
            'DRUG_OPERATION_LICENSE', 'AUTHORIZATION', 'OTHER'
        )),
    CONSTRAINT ck_supplier_qualification_state
        CHECK (status IN ('DRAFT', 'VALID', 'EXPIRED', 'REVOKED')),
    CONSTRAINT ck_supplier_qualification_validity
        CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_from <= valid_until),
    INDEX idx_supplier_qualification_expiry (status, valid_until),
    CONSTRAINT fk_supplier_qualification_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_supplier_qualification_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_supplier_qualification_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '供应商营业执照、药品许可及授权文件';

CREATE TABLE supplier_review (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商审核主键',
    review_no VARCHAR(40) NOT NULL COMMENT '审核单号',
    supplier_id BIGINT NOT NULL COMMENT '供应商',
    review_round INT NOT NULL DEFAULT 1 COMMENT '审核轮次',
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING、APPROVED、REJECTED或RETURNED',
    submitted_by BIGINT NOT NULL COMMENT '提交人',
    submitted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '提交时间（UTC）',
    reviewer_id BIGINT NULL COMMENT '审核人',
    reviewed_at DATETIME(3) NULL COMMENT '审核时间（UTC）',
    review_opinion VARCHAR(1000) NULL COMMENT '审核意见',
    rejection_reason VARCHAR(1000) NULL COMMENT '驳回或退回原因',
    qualification_snapshot JSON NOT NULL COMMENT '提交审核时的资质快照',
    approved_valid_until DATE NULL COMMENT '审核确认的综合有效期截止日',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_supplier_review_no UNIQUE (review_no),
    CONSTRAINT uk_supplier_review_round UNIQUE (supplier_id, review_round),
    CONSTRAINT ck_supplier_review_round CHECK (review_round > 0),
    CONSTRAINT ck_supplier_review_status
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'RETURNED')),
    CONSTRAINT ck_supplier_review_pair
        CHECK ((reviewer_id IS NULL) = (reviewed_at IS NULL)),
    CONSTRAINT ck_supplier_review_rejection
        CHECK (status NOT IN ('REJECTED', 'RETURNED') OR rejection_reason IS NOT NULL),
    INDEX idx_supplier_review_status (status, submitted_at),
    INDEX idx_supplier_review_supplier (supplier_id, submitted_at),
    CONSTRAINT fk_supplier_review_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_supplier_review_submitter
        FOREIGN KEY (submitted_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_supplier_review_reviewer
        FOREIGN KEY (reviewer_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '供应商资质提交与审核记录';

CREATE TABLE customer (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '客户主键',
    customer_code VARCHAR(32) NOT NULL COMMENT '客户编码',
    customer_name VARCHAR(200) NOT NULL COMMENT '客户企业名称',
    customer_type VARCHAR(24) NOT NULL COMMENT 'WHOLESALE、RETAIL、MEDICAL或OTHER',
    unified_social_credit_code VARCHAR(32) NOT NULL COMMENT '统一社会信用代码',
    contact_name VARCHAR(100) NULL COMMENT '联系人',
    contact_phone VARCHAR(32) NULL COMMENT '联系电话',
    contact_email VARCHAR(128) NULL COMMENT '联系邮箱',
    address VARCHAR(500) NULL COMMENT '企业地址',
    qualification_status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '客户资质状态',
    approved_at DATETIME(3) NULL COMMENT '最近审核通过时间（UTC）',
    valid_until DATE NULL COMMENT '综合资质有效期截止日',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_customer_code UNIQUE (customer_code),
    CONSTRAINT uk_customer_credit UNIQUE (unified_social_credit_code),
    CONSTRAINT ck_customer_type
        CHECK (customer_type IN ('WHOLESALE', 'RETAIL', 'MEDICAL', 'OTHER')),
    CONSTRAINT ck_customer_qualification_status
        CHECK (qualification_status IN (
            'DRAFT', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'EXPIRED', 'FROZEN', 'DISABLED'
        )),
    INDEX idx_customer_name (customer_name),
    INDEX idx_customer_qualification (qualification_status, valid_until),
    CONSTRAINT fk_customer_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '客户企业档案及综合资质状态';

CREATE TABLE customer_qualification (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '客户资质主键',
    customer_id BIGINT NOT NULL COMMENT '客户',
    qualification_type VARCHAR(40) NOT NULL COMMENT '资质类型',
    certificate_no VARCHAR(100) NOT NULL COMMENT '证照或授权文件编号',
    issuing_authority VARCHAR(200) NULL COMMENT '发证机关',
    issued_on DATE NULL COMMENT '发证日期',
    valid_from DATE NULL COMMENT '有效期开始日',
    valid_until DATE NULL COMMENT '有效期截止日；长期有效可为空',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT、VALID、EXPIRED或REVOKED',
    remark VARCHAR(500) NULL COMMENT '备注',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_customer_qualification_cert
        UNIQUE (customer_id, qualification_type, certificate_no),
    CONSTRAINT ck_customer_qualification_type
        CHECK (qualification_type IN (
            'BUSINESS_LICENSE', 'DRUG_OPERATION_LICENSE',
            'MEDICAL_INSTITUTION_LICENSE', 'PURCHASE_AUTHORIZATION', 'OTHER'
        )),
    CONSTRAINT ck_customer_qualification_state
        CHECK (status IN ('DRAFT', 'VALID', 'EXPIRED', 'REVOKED')),
    CONSTRAINT ck_customer_qualification_validity
        CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_from <= valid_until),
    INDEX idx_customer_qualification_expiry (status, valid_until),
    CONSTRAINT fk_customer_qualification_customer
        FOREIGN KEY (customer_id) REFERENCES customer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_qualification_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_qualification_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '客户经营许可、医疗机构许可及采购授权';

CREATE TABLE customer_review (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '客户审核主键',
    review_no VARCHAR(40) NOT NULL COMMENT '审核单号',
    customer_id BIGINT NOT NULL COMMENT '客户',
    review_round INT NOT NULL DEFAULT 1 COMMENT '审核轮次',
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING、APPROVED、REJECTED或RETURNED',
    submitted_by BIGINT NOT NULL COMMENT '提交人',
    submitted_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '提交时间（UTC）',
    reviewer_id BIGINT NULL COMMENT '审核人',
    reviewed_at DATETIME(3) NULL COMMENT '审核时间（UTC）',
    review_opinion VARCHAR(1000) NULL COMMENT '审核意见',
    rejection_reason VARCHAR(1000) NULL COMMENT '驳回或退回原因',
    qualification_snapshot JSON NOT NULL COMMENT '提交审核时的资质快照',
    approved_valid_until DATE NULL COMMENT '审核确认的综合有效期截止日',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_customer_review_no UNIQUE (review_no),
    CONSTRAINT uk_customer_review_round UNIQUE (customer_id, review_round),
    CONSTRAINT ck_customer_review_round CHECK (review_round > 0),
    CONSTRAINT ck_customer_review_status
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'RETURNED')),
    CONSTRAINT ck_customer_review_pair
        CHECK ((reviewer_id IS NULL) = (reviewed_at IS NULL)),
    CONSTRAINT ck_customer_review_rejection
        CHECK (status NOT IN ('REJECTED', 'RETURNED') OR rejection_reason IS NOT NULL),
    INDEX idx_customer_review_status (status, submitted_at),
    INDEX idx_customer_review_customer (customer_id, submitted_at),
    CONSTRAINT fk_customer_review_customer
        FOREIGN KEY (customer_id) REFERENCES customer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_review_submitter
        FOREIGN KEY (submitted_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_review_reviewer
        FOREIGN KEY (reviewer_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '客户资质提交与审核记录';

CREATE TABLE warehouse (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '仓库主键',
    warehouse_code VARCHAR(32) NOT NULL COMMENT '仓库编码',
    warehouse_name VARCHAR(100) NOT NULL COMMENT '仓库名称',
    department_id BIGINT NOT NULL COMMENT '所属部门',
    manager_user_id BIGINT NULL COMMENT '仓库主管',
    address VARCHAR(500) NULL COMMENT '仓库地址',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_warehouse_code UNIQUE (warehouse_code),
    CONSTRAINT ck_warehouse_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_warehouse_department (department_id, status),
    CONSTRAINT fk_warehouse_department
        FOREIGN KEY (department_id) REFERENCES sys_department (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_warehouse_manager
        FOREIGN KEY (manager_user_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_warehouse_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_warehouse_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '仓库主数据';

CREATE TABLE warehouse_location (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '库位主键',
    warehouse_id BIGINT NOT NULL COMMENT '所属仓库',
    location_code VARCHAR(32) NOT NULL COMMENT '库位编码',
    location_name VARCHAR(100) NOT NULL COMMENT '库位名称',
    location_type VARCHAR(16) NOT NULL DEFAULT 'NORMAL' COMMENT 'NORMAL、QUARANTINE或RETURN',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE或DISABLED',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_warehouse_location_code UNIQUE (warehouse_id, location_code),
    CONSTRAINT ck_warehouse_location_type
        CHECK (location_type IN ('NORMAL', 'QUARANTINE', 'RETURN')),
    CONSTRAINT ck_warehouse_location_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    INDEX idx_warehouse_location_type (warehouse_id, location_type, status),
    CONSTRAINT fk_warehouse_location_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_warehouse_location_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_warehouse_location_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '仓库库位；隔离与退货使用独立库位类型';

CREATE TABLE sys_role_data_scope (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '角色数据范围主键',
    role_id BIGINT NOT NULL COMMENT '角色',
    data_permission_id BIGINT NOT NULL COMMENT 'DATA类型权限',
    scope_type VARCHAR(16) NOT NULL COMMENT 'ALL、ENTERPRISE、DEPARTMENT、SELF或CUSTOM',
    department_id BIGINT NULL COMMENT '部门范围；不适用时为空',
    warehouse_id BIGINT NULL COMMENT '仓库范围；不适用时为空',
    created_by BIGINT NULL COMMENT '配置人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '配置时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT ck_sys_role_data_scope_type
        CHECK (scope_type IN ('ALL', 'ENTERPRISE', 'DEPARTMENT', 'SELF', 'CUSTOM')),
    CONSTRAINT ck_sys_role_data_scope_target
        CHECK (
            (scope_type IN ('ALL', 'ENTERPRISE', 'SELF')
                AND department_id IS NULL AND warehouse_id IS NULL)
            OR (scope_type = 'DEPARTMENT'
                AND department_id IS NOT NULL AND warehouse_id IS NULL)
            OR (scope_type = 'CUSTOM'
                AND (department_id IS NOT NULL OR warehouse_id IS NOT NULL))
        ),
    CONSTRAINT uk_sys_role_data_scope
        UNIQUE (role_id, data_permission_id, scope_type, department_id, warehouse_id),
    INDEX idx_sys_role_data_scope_permission (data_permission_id, scope_type),
    CONSTRAINT fk_sys_role_data_scope_role
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_data_scope_permission
        FOREIGN KEY (data_permission_id) REFERENCES sys_permission (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_data_scope_department
        FOREIGN KEY (department_id) REFERENCES sys_department (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_data_scope_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_data_scope_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '角色的数据查看范围';

CREATE TABLE drug_batch (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '药品批次主键',
    batch_code VARCHAR(40) NOT NULL COMMENT '系统批次编码',
    drug_id BIGINT NOT NULL COMMENT '药品',
    manufacturer_id BIGINT NOT NULL COMMENT '生产企业',
    batch_no VARCHAR(100) NOT NULL COMMENT '生产批号',
    production_date DATE NULL COMMENT '生产日期',
    expiry_date DATE NOT NULL COMMENT '有效期截止日',
    quality_status VARCHAR(24) NOT NULL DEFAULT 'PENDING_INSPECTION' COMMENT '批次质量状态',
    stock_status VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING、ACTIVE、FROZEN或DEPLETED',
    created_by BIGINT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_drug_batch_code UNIQUE (batch_code),
    CONSTRAINT uk_drug_batch_identity
        UNIQUE (drug_id, manufacturer_id, batch_no, expiry_date),
    CONSTRAINT ck_drug_batch_dates
        CHECK (production_date IS NULL OR production_date <= expiry_date),
    CONSTRAINT ck_drug_batch_quality
        CHECK (quality_status IN (
            'PENDING_INSPECTION', 'QUALIFIED', 'QUARANTINED', 'UNQUALIFIED', 'EXPIRED'
        )),
    CONSTRAINT ck_drug_batch_stock
        CHECK (stock_status IN ('PENDING', 'ACTIVE', 'FROZEN', 'DEPLETED')),
    INDEX idx_drug_batch_batch_no (batch_no),
    INDEX idx_drug_batch_drug_expiry (drug_id, expiry_date, quality_status),
    INDEX idx_drug_batch_status (quality_status, stock_status, expiry_date),
    CONSTRAINT fk_drug_batch_drug
        FOREIGN KEY (drug_id) REFERENCES drug (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_drug_batch_manufacturer
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_drug_batch_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_drug_batch_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '药品批次主数据与质量、库存启用状态';

-- ============================================================================
-- 3. 采购订单与采购审批
-- ============================================================================

CREATE TABLE purchase_order (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '采购订单主键',
    order_no VARCHAR(40) NOT NULL COMMENT '采购订单号',
    supplier_id BIGINT NOT NULL COMMENT '供应商',
    supplier_review_id BIGINT NOT NULL COMMENT '下单时采用的供应商审核记录',
    purchaser_id BIGINT NOT NULL COMMENT '采购员',
    order_date DATE NOT NULL COMMENT '采购日期',
    expected_arrival_date DATE NULL COMMENT '预计到货日期',
    status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '采购订单状态',
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0 COMMENT '订单总金额',
    remark VARCHAR(1000) NULL COMMENT '备注',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_purchase_order_no UNIQUE (order_no),
    CONSTRAINT ck_purchase_order_status
        CHECK (status IN (
            'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED',
            'PARTIALLY_RECEIVED', 'COMPLETED', 'CANCELLED'
        )),
    CONSTRAINT ck_purchase_order_amount CHECK (total_amount >= 0),
    CONSTRAINT ck_purchase_order_arrival
        CHECK (expected_arrival_date IS NULL OR expected_arrival_date >= order_date),
    INDEX idx_purchase_order_supplier (supplier_id, status, order_date),
    INDEX idx_purchase_order_purchaser (purchaser_id, status, order_date),
    CONSTRAINT fk_purchase_order_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_supplier_review
        FOREIGN KEY (supplier_review_id) REFERENCES supplier_review (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_purchaser
        FOREIGN KEY (purchaser_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '采购订单；创建前必须校验供应商审核通过且资质有效';

CREATE TABLE purchase_order_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '采购明细主键',
    purchase_order_id BIGINT NOT NULL COMMENT '采购订单',
    line_no INT NOT NULL COMMENT '订单行号',
    drug_id BIGINT NOT NULL COMMENT '药品',
    manufacturer_id BIGINT NOT NULL COMMENT '生产企业',
    batch_no VARCHAR(100) NOT NULL COMMENT '采购约定批号',
    expiry_date DATE NOT NULL COMMENT '采购约定有效期',
    ordered_quantity DECIMAL(18, 4) NOT NULL COMMENT '采购数量',
    received_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '累计收货数量',
    unit_price DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '采购单价',
    line_amount DECIMAL(18, 2) NOT NULL DEFAULT 0 COMMENT '行金额',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_purchase_order_item_line UNIQUE (purchase_order_id, line_no),
    CONSTRAINT ck_purchase_order_item_line CHECK (line_no > 0),
    CONSTRAINT ck_purchase_order_item_quantity
        CHECK (
            ordered_quantity > 0
            AND received_quantity >= 0
            AND received_quantity <= ordered_quantity
        ),
    CONSTRAINT ck_purchase_order_item_amount
        CHECK (unit_price >= 0 AND line_amount >= 0),
    INDEX idx_purchase_order_item_drug (drug_id, batch_no, expiry_date),
    CONSTRAINT fk_purchase_order_item_order
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_item_drug
        FOREIGN KEY (drug_id) REFERENCES drug (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_item_manufacturer
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '采购订单药品、规格对应主数据、数量、批号和有效期明细';

CREATE TABLE purchase_order_review (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '采购审批记录主键',
    purchase_order_id BIGINT NOT NULL COMMENT '采购订单',
    review_round INT NOT NULL DEFAULT 1 COMMENT '审批轮次',
    reviewer_id BIGINT NOT NULL COMMENT '采购经理或授权审批人',
    review_result VARCHAR(16) NOT NULL COMMENT 'APPROVED、REJECTED或RETURNED',
    review_opinion VARCHAR(1000) NULL COMMENT '审批意见',
    reviewed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '审批时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_purchase_order_review_round
        UNIQUE (purchase_order_id, review_round),
    CONSTRAINT ck_purchase_order_review_round CHECK (review_round > 0),
    CONSTRAINT ck_purchase_order_review_result
        CHECK (review_result IN ('APPROVED', 'REJECTED', 'RETURNED')),
    INDEX idx_purchase_order_review_reviewer (reviewer_id, reviewed_at),
    CONSTRAINT fk_purchase_order_review_order
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_purchase_order_review_user
        FOREIGN KEY (reviewer_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '采购订单逐轮审批记录';

-- ============================================================================
-- 4. 到货、验收与入库
-- ============================================================================

CREATE TABLE goods_receipt (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '收货记录主键',
    receipt_no VARCHAR(40) NOT NULL COMMENT '收货单号',
    purchase_order_id BIGINT NOT NULL COMMENT '采购订单',
    warehouse_id BIGINT NOT NULL COMMENT '到货仓库',
    delivery_document_no VARCHAR(100) NULL COMMENT '随货同行单号',
    received_by BIGINT NOT NULL COMMENT '收货人',
    received_at DATETIME(3) NOT NULL COMMENT '实际收货时间（UTC）',
    status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '收货状态',
    transport_condition VARCHAR(32) NULL COMMENT '运输条件检查结果',
    remark VARCHAR(1000) NULL COMMENT '收货备注与异常摘要',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_goods_receipt_no UNIQUE (receipt_no),
    CONSTRAINT ck_goods_receipt_status
        CHECK (status IN (
            'DRAFT', 'RECEIVING', 'PENDING_ACCEPTANCE', 'COMPLETED', 'CANCELLED'
        )),
    CONSTRAINT ck_goods_receipt_transport
        CHECK (transport_condition IS NULL OR transport_condition IN ('PASS', 'FAIL', 'NOT_APPLICABLE')),
    INDEX idx_goods_receipt_order (purchase_order_id, status),
    INDEX idx_goods_receipt_warehouse (warehouse_id, status, received_at),
    CONSTRAINT fk_goods_receipt_purchase_order
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_receiver
        FOREIGN KEY (received_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '采购到货与收货记录；收货不直接增加可销售库存';

CREATE TABLE goods_receipt_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '收货明细主键',
    goods_receipt_id BIGINT NOT NULL COMMENT '收货记录',
    line_no INT NOT NULL COMMENT '收货行号',
    purchase_order_item_id BIGINT NOT NULL COMMENT '采购订单明细',
    drug_batch_id BIGINT NOT NULL COMMENT '到货批次；初始为待验状态',
    received_quantity DECIMAL(18, 4) NOT NULL COMMENT '本次收货数量',
    package_condition VARCHAR(16) NOT NULL COMMENT 'PASS或FAIL',
    information_match TINYINT NOT NULL COMMENT '随货信息是否与订单一致：0否，1是',
    discrepancy_description VARCHAR(1000) NULL COMMENT '数量、包装、批号或资料差异说明',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_goods_receipt_item_line UNIQUE (goods_receipt_id, line_no),
    CONSTRAINT ck_goods_receipt_item_line CHECK (line_no > 0),
    CONSTRAINT ck_goods_receipt_item_quantity CHECK (received_quantity > 0),
    CONSTRAINT ck_goods_receipt_item_package
        CHECK (package_condition IN ('PASS', 'FAIL')),
    CONSTRAINT ck_goods_receipt_item_match CHECK (information_match IN (0, 1)),
    INDEX idx_goods_receipt_item_purchase (purchase_order_item_id),
    INDEX idx_goods_receipt_item_batch (drug_batch_id),
    CONSTRAINT fk_goods_receipt_item_receipt
        FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipt (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_item_purchase
        FOREIGN KEY (purchase_order_item_id) REFERENCES purchase_order_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_receipt_item_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '逐批收货明细与包装、资料一致性初检';

CREATE TABLE acceptance_record (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '验收记录主键',
    acceptance_no VARCHAR(40) NOT NULL COMMENT '验收单号',
    goods_receipt_id BIGINT NOT NULL COMMENT '来源收货记录',
    inspector_id BIGINT NOT NULL COMMENT '验收员；必须与收货人职责分离',
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT '验收状态',
    started_at DATETIME(3) NULL COMMENT '开始验收时间（UTC）',
    completed_at DATETIME(3) NULL COMMENT '完成验收时间（UTC）',
    overall_conclusion VARCHAR(16) NULL COMMENT 'PASSED、PARTIAL或FAILED',
    conclusion_remark VARCHAR(1000) NULL COMMENT '验收结论说明',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_acceptance_record_no UNIQUE (acceptance_no),
    CONSTRAINT uk_acceptance_record_receipt UNIQUE (goods_receipt_id),
    CONSTRAINT ck_acceptance_record_status
        CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_acceptance_record_conclusion
        CHECK (overall_conclusion IS NULL OR overall_conclusion IN ('PASSED', 'PARTIAL', 'FAILED')),
    CONSTRAINT ck_acceptance_record_time
        CHECK (completed_at IS NULL OR (started_at IS NOT NULL AND started_at <= completed_at)),
    INDEX idx_acceptance_record_inspector (inspector_id, status, created_at),
    CONSTRAINT fk_acceptance_record_receipt
        FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipt (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_record_inspector
        FOREIGN KEY (inspector_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_record_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_record_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '独立验收单；收货人与验收员的职责分离由服务层校验';

CREATE TABLE acceptance_record_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '验收明细主键',
    acceptance_record_id BIGINT NOT NULL COMMENT '验收记录',
    goods_receipt_item_id BIGINT NOT NULL COMMENT '来源收货明细',
    drug_batch_id BIGINT NOT NULL COMMENT '验收批次',
    inspected_quantity DECIMAL(18, 4) NOT NULL COMMENT '验收数量',
    qualified_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '合格数量',
    unqualified_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '不合格数量',
    drug_information_passed TINYINT NOT NULL COMMENT '药品信息一致性：0否，1是',
    quantity_passed TINYINT NOT NULL COMMENT '数量检查：0否，1是',
    package_passed TINYINT NOT NULL COMMENT '包装检查：0否，1是',
    batch_passed TINYINT NOT NULL COMMENT '批号检查：0否，1是',
    expiry_passed TINYINT NOT NULL COMMENT '有效期检查：0否，1是',
    result VARCHAR(16) NOT NULL COMMENT 'PASSED、PARTIAL或FAILED',
    result_description VARCHAR(1000) NULL COMMENT '逐批验收说明',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_acceptance_record_item_receipt UNIQUE (goods_receipt_item_id),
    CONSTRAINT ck_acceptance_record_item_quantity
        CHECK (
            inspected_quantity > 0
            AND qualified_quantity >= 0
            AND unqualified_quantity >= 0
            AND qualified_quantity + unqualified_quantity = inspected_quantity
        ),
    CONSTRAINT ck_acceptance_record_item_checks
        CHECK (
            drug_information_passed IN (0, 1)
            AND quantity_passed IN (0, 1)
            AND package_passed IN (0, 1)
            AND batch_passed IN (0, 1)
            AND expiry_passed IN (0, 1)
        ),
    CONSTRAINT ck_acceptance_record_item_result
        CHECK (
            (result = 'PASSED' AND qualified_quantity = inspected_quantity AND unqualified_quantity = 0)
            OR (result = 'PARTIAL' AND qualified_quantity > 0 AND unqualified_quantity > 0)
            OR (result = 'FAILED' AND qualified_quantity = 0 AND unqualified_quantity = inspected_quantity)
        ),
    INDEX idx_acceptance_record_item_record (acceptance_record_id, result),
    INDEX idx_acceptance_record_item_batch (drug_batch_id, result),
    CONSTRAINT fk_acceptance_record_item_record
        FOREIGN KEY (acceptance_record_id) REFERENCES acceptance_record (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_record_item_receipt
        FOREIGN KEY (goods_receipt_item_id) REFERENCES goods_receipt_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_record_item_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '逐批验收检查项、合格数量和不合格数量';

CREATE TABLE acceptance_exception (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '验收异常主键',
    exception_no VARCHAR(40) NOT NULL COMMENT '异常编号',
    acceptance_record_item_id BIGINT NOT NULL COMMENT '验收明细',
    exception_type VARCHAR(32) NOT NULL COMMENT 'INFO、QUANTITY、PACKAGE、BATCH、EXPIRY或OTHER',
    description VARCHAR(1000) NOT NULL COMMENT '异常说明',
    disposition VARCHAR(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING、RETURN或QUARANTINE',
    status VARCHAR(16) NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN、PROCESSING或CLOSED',
    handled_by BIGINT NULL COMMENT '处置人',
    handled_at DATETIME(3) NULL COMMENT '处置时间（UTC）',
    handling_result VARCHAR(1000) NULL COMMENT '处置结果',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_acceptance_exception_no UNIQUE (exception_no),
    CONSTRAINT ck_acceptance_exception_type
        CHECK (exception_type IN ('INFO', 'QUANTITY', 'PACKAGE', 'BATCH', 'EXPIRY', 'OTHER')),
    CONSTRAINT ck_acceptance_exception_disposition
        CHECK (disposition IN ('PENDING', 'RETURN', 'QUARANTINE')),
    CONSTRAINT ck_acceptance_exception_status
        CHECK (status IN ('OPEN', 'PROCESSING', 'CLOSED')),
    CONSTRAINT ck_acceptance_exception_handle_pair
        CHECK ((handled_by IS NULL) = (handled_at IS NULL)),
    INDEX idx_acceptance_exception_item (acceptance_record_item_id, status),
    CONSTRAINT fk_acceptance_exception_item
        FOREIGN KEY (acceptance_record_item_id) REFERENCES acceptance_record_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_exception_handler
        FOREIGN KEY (handled_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_exception_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_acceptance_exception_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '验收失败后的退货或隔离处置';

CREATE TABLE stock_in_order (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '入库单主键',
    stock_in_no VARCHAR(40) NOT NULL COMMENT '入库单号',
    acceptance_record_id BIGINT NOT NULL COMMENT '来源验收单',
    warehouse_id BIGINT NOT NULL COMMENT '入库仓库',
    status VARCHAR(16) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT、PENDING_POST、POSTED或CANCELLED',
    operator_id BIGINT NOT NULL COMMENT '入库操作人',
    posted_by BIGINT NULL COMMENT '过账人',
    posted_at DATETIME(3) NULL COMMENT '入库过账时间（UTC）',
    remark VARCHAR(1000) NULL COMMENT '备注',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_stock_in_order_no UNIQUE (stock_in_no),
    CONSTRAINT uk_stock_in_order_acceptance UNIQUE (acceptance_record_id),
    CONSTRAINT ck_stock_in_order_status
        CHECK (status IN ('DRAFT', 'PENDING_POST', 'POSTED', 'CANCELLED')),
    CONSTRAINT ck_stock_in_order_post_pair
        CHECK ((posted_by IS NULL) = (posted_at IS NULL)),
    INDEX idx_stock_in_order_warehouse (warehouse_id, status, created_at),
    CONSTRAINT fk_stock_in_order_acceptance
        FOREIGN KEY (acceptance_record_id) REFERENCES acceptance_record (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_poster
        FOREIGN KEY (posted_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '验收合格数量的入库单；过账必须与库存流水同事务';

CREATE TABLE stock_in_order_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '入库明细主键',
    stock_in_order_id BIGINT NOT NULL COMMENT '入库单',
    line_no INT NOT NULL COMMENT '入库行号',
    acceptance_record_item_id BIGINT NOT NULL COMMENT '来源验收明细',
    drug_batch_id BIGINT NOT NULL COMMENT '合格药品批次',
    warehouse_location_id BIGINT NOT NULL COMMENT '目标库位',
    stock_in_quantity DECIMAL(18, 4) NOT NULL COMMENT '入库数量',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_stock_in_order_item_line UNIQUE (stock_in_order_id, line_no),
    CONSTRAINT uk_stock_in_order_item_acceptance UNIQUE (acceptance_record_item_id),
    CONSTRAINT ck_stock_in_order_item_line CHECK (line_no > 0),
    CONSTRAINT ck_stock_in_order_item_quantity CHECK (stock_in_quantity > 0),
    INDEX idx_stock_in_order_item_batch (drug_batch_id),
    INDEX idx_stock_in_order_item_location (warehouse_location_id),
    CONSTRAINT fk_stock_in_order_item_order
        FOREIGN KEY (stock_in_order_id) REFERENCES stock_in_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_item_acceptance
        FOREIGN KEY (acceptance_record_item_id) REFERENCES acceptance_record_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_item_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_stock_in_order_item_location
        FOREIGN KEY (warehouse_location_id) REFERENCES warehouse_location (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '合格批次数量与目标库位明细';

-- ============================================================================
-- 5. 批号库存与库存流水
-- ============================================================================

CREATE TABLE inventory_balance (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '库存余额主键',
    drug_batch_id BIGINT NOT NULL COMMENT '药品批次',
    warehouse_id BIGINT NOT NULL COMMENT '仓库',
    warehouse_location_id BIGINT NOT NULL COMMENT '库位',
    total_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '账面总数量',
    available_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '可销售数量',
    reserved_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '销售占用数量',
    quarantined_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '隔离数量',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE、FROZEN或CLOSED',
    last_ledger_id BIGINT NULL COMMENT '最后一笔库存流水；不设外键以避免建表循环',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '库存并发控制版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_inventory_balance_dimension
        UNIQUE (drug_batch_id, warehouse_id, warehouse_location_id),
    CONSTRAINT ck_inventory_balance_quantity
        CHECK (
            total_quantity >= 0
            AND available_quantity >= 0
            AND reserved_quantity >= 0
            AND quarantined_quantity >= 0
            AND total_quantity = available_quantity + reserved_quantity + quarantined_quantity
        ),
    CONSTRAINT ck_inventory_balance_status
        CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    INDEX idx_inventory_balance_available (warehouse_id, status, available_quantity),
    INDEX idx_inventory_balance_batch (drug_batch_id, status),
    CONSTRAINT fk_inventory_balance_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_balance_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_balance_location
        FOREIGN KEY (warehouse_location_id) REFERENCES warehouse_location (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '药品、批号、仓库和库位维度的当前库存余额';

CREATE TABLE inventory_ledger (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '库存流水主键',
    ledger_no VARCHAR(48) NOT NULL COMMENT '库存流水号',
    idempotency_key VARCHAR(100) NOT NULL COMMENT '业务幂等键',
    inventory_balance_id BIGINT NOT NULL COMMENT '库存余额',
    drug_batch_id BIGINT NOT NULL COMMENT '药品批次快照',
    warehouse_id BIGINT NOT NULL COMMENT '仓库快照',
    warehouse_location_id BIGINT NOT NULL COMMENT '库位快照',
    transaction_type VARCHAR(24) NOT NULL COMMENT 'INBOUND、RESERVE、RELEASE、OUTBOUND、QUARANTINE或RETURN',
    movement_mode VARCHAR(16) NOT NULL COMMENT 'INCREASE、DECREASE或TRANSFER',
    quantity DECIMAL(18, 4) NOT NULL COMMENT '本次业务数量，始终为正数',
    before_total_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更前总数量',
    after_total_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更后总数量',
    before_available_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更前可用数量',
    after_available_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更后可用数量',
    before_reserved_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更前占用数量',
    after_reserved_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更后占用数量',
    before_quarantined_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更前隔离数量',
    after_quarantined_quantity DECIMAL(18, 4) NOT NULL COMMENT '变更后隔离数量',
    source_business_type VARCHAR(32) NOT NULL COMMENT '来源业务类型',
    source_business_id BIGINT NOT NULL COMMENT '来源业务主键',
    source_business_no VARCHAR(64) NOT NULL COMMENT '来源业务编号快照',
    operator_id BIGINT NULL COMMENT '操作人；系统任务可为空',
    occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发生时间（UTC）',
    remark VARCHAR(500) NULL COMMENT '流水说明',

    PRIMARY KEY (id),
    CONSTRAINT uk_inventory_ledger_no UNIQUE (ledger_no),
    CONSTRAINT uk_inventory_ledger_idempotency UNIQUE (idempotency_key),
    CONSTRAINT ck_inventory_ledger_type
        CHECK (transaction_type IN (
            'INBOUND', 'RESERVE', 'RELEASE', 'OUTBOUND', 'QUARANTINE', 'RETURN'
        )),
    CONSTRAINT ck_inventory_ledger_mode
        CHECK (movement_mode IN ('INCREASE', 'DECREASE', 'TRANSFER')),
    CONSTRAINT ck_inventory_ledger_quantity CHECK (quantity > 0),
    CONSTRAINT ck_inventory_ledger_before
        CHECK (
            before_total_quantity >= 0
            AND before_available_quantity >= 0
            AND before_reserved_quantity >= 0
            AND before_quarantined_quantity >= 0
            AND before_total_quantity = before_available_quantity
                + before_reserved_quantity + before_quarantined_quantity
        ),
    CONSTRAINT ck_inventory_ledger_after
        CHECK (
            after_total_quantity >= 0
            AND after_available_quantity >= 0
            AND after_reserved_quantity >= 0
            AND after_quarantined_quantity >= 0
            AND after_total_quantity = after_available_quantity
                + after_reserved_quantity + after_quarantined_quantity
        ),
    INDEX idx_inventory_ledger_balance (inventory_balance_id, occurred_at),
    INDEX idx_inventory_ledger_batch (drug_batch_id, occurred_at),
    INDEX idx_inventory_ledger_source (source_business_type, source_business_id),
    INDEX idx_inventory_ledger_time (occurred_at),
    CONSTRAINT fk_inventory_ledger_balance
        FOREIGN KEY (inventory_balance_id) REFERENCES inventory_balance (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_ledger_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_ledger_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_ledger_location
        FOREIGN KEY (warehouse_location_id) REFERENCES warehouse_location (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_ledger_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '库存数量与状态变化的追加式流水，禁止修改和删除';

ALTER TABLE inventory_balance
    ADD CONSTRAINT fk_inventory_balance_last_ledger
        FOREIGN KEY (last_ledger_id) REFERENCES inventory_ledger (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================================
-- 6. 销售、库存占用、出库与复核
-- ============================================================================

CREATE TABLE sales_order (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '销售订单主键',
    order_no VARCHAR(40) NOT NULL COMMENT '销售订单号',
    customer_id BIGINT NOT NULL COMMENT '客户',
    customer_review_id BIGINT NOT NULL COMMENT '下单时采用的客户审核记录',
    warehouse_id BIGINT NOT NULL COMMENT '计划出库仓库',
    salesperson_id BIGINT NOT NULL COMMENT '销售人员',
    order_date DATE NOT NULL COMMENT '销售日期',
    status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '销售订单状态',
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0 COMMENT '订单总金额',
    receiver_name VARCHAR(100) NULL COMMENT '收货联系人',
    receiver_phone VARCHAR(32) NULL COMMENT '收货联系电话',
    delivery_address VARCHAR(500) NULL COMMENT '交付地址',
    remark VARCHAR(1000) NULL COMMENT '备注',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sales_order_no UNIQUE (order_no),
    CONSTRAINT ck_sales_order_status
        CHECK (status IN (
            'DRAFT', 'PENDING_CUSTOMER_CHECK', 'PENDING_APPROVAL', 'APPROVED',
            'ALLOCATED', 'PENDING_OUTBOUND', 'COMPLETED', 'REJECTED', 'CANCELLED'
        )),
    CONSTRAINT ck_sales_order_amount CHECK (total_amount >= 0),
    INDEX idx_sales_order_customer (customer_id, status, order_date),
    INDEX idx_sales_order_salesperson (salesperson_id, status, order_date),
    INDEX idx_sales_order_warehouse (warehouse_id, status, order_date),
    CONSTRAINT fk_sales_order_customer
        FOREIGN KEY (customer_id) REFERENCES customer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_customer_review
        FOREIGN KEY (customer_review_id) REFERENCES customer_review (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_salesperson
        FOREIGN KEY (salesperson_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售订单；提交前必须校验客户资质、状态和经营范围';

CREATE TABLE sales_order_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '销售订单明细主键',
    sales_order_id BIGINT NOT NULL COMMENT '销售订单',
    line_no INT NOT NULL COMMENT '订单行号',
    drug_id BIGINT NOT NULL COMMENT '药品',
    ordered_quantity DECIMAL(18, 4) NOT NULL COMMENT '销售数量',
    allocated_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '已分配批次数量',
    outbound_quantity DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '累计出库数量',
    unit_price DECIMAL(18, 4) NOT NULL DEFAULT 0 COMMENT '销售单价',
    line_amount DECIMAL(18, 2) NOT NULL DEFAULT 0 COMMENT '行金额',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_sales_order_item_line UNIQUE (sales_order_id, line_no),
    CONSTRAINT ck_sales_order_item_line CHECK (line_no > 0),
    CONSTRAINT ck_sales_order_item_quantity
        CHECK (
            ordered_quantity > 0
            AND allocated_quantity >= 0
            AND outbound_quantity >= 0
            AND outbound_quantity <= allocated_quantity
            AND allocated_quantity <= ordered_quantity
        ),
    CONSTRAINT ck_sales_order_item_amount
        CHECK (unit_price >= 0 AND line_amount >= 0),
    INDEX idx_sales_order_item_drug (drug_id),
    CONSTRAINT fk_sales_order_item_order
        FOREIGN KEY (sales_order_id) REFERENCES sales_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_item_drug
        FOREIGN KEY (drug_id) REFERENCES drug (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售订单药品、数量和金额明细';

CREATE TABLE sales_order_review (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '销售审批记录主键',
    sales_order_id BIGINT NOT NULL COMMENT '销售订单',
    review_round INT NOT NULL DEFAULT 1 COMMENT '审批轮次',
    reviewer_id BIGINT NOT NULL COMMENT '销售经理或授权审批人',
    review_result VARCHAR(16) NOT NULL COMMENT 'APPROVED、REJECTED或RETURNED',
    review_opinion VARCHAR(1000) NULL COMMENT '审批意见',
    reviewed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '审批时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_sales_order_review_round
        UNIQUE (sales_order_id, review_round),
    CONSTRAINT ck_sales_order_review_round CHECK (review_round > 0),
    CONSTRAINT ck_sales_order_review_result
        CHECK (review_result IN ('APPROVED', 'REJECTED', 'RETURNED')),
    INDEX idx_sales_order_review_reviewer (reviewer_id, reviewed_at),
    CONSTRAINT fk_sales_order_review_order
        FOREIGN KEY (sales_order_id) REFERENCES sales_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_sales_order_review_user
        FOREIGN KEY (reviewer_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售订单逐轮审批记录';

CREATE TABLE inventory_reservation (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '库存占用主键',
    reservation_no VARCHAR(48) NOT NULL COMMENT '库存占用编号',
    sales_order_item_id BIGINT NOT NULL COMMENT '销售订单明细',
    inventory_balance_id BIGINT NOT NULL COMMENT '占用的库存余额',
    drug_batch_id BIGINT NOT NULL COMMENT '占用批次',
    reserved_quantity DECIMAL(18, 4) NOT NULL COMMENT '占用数量',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE、RELEASED或CONSUMED',
    reserved_by BIGINT NOT NULL COMMENT '发起占用的操作人',
    reserved_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '占用时间（UTC）',
    released_by BIGINT NULL COMMENT '释放人',
    released_at DATETIME(3) NULL COMMENT '释放时间（UTC）',
    release_reason VARCHAR(500) NULL COMMENT '释放原因',
    consumed_at DATETIME(3) NULL COMMENT '出库消耗时间（UTC）',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_inventory_reservation_no UNIQUE (reservation_no),
    CONSTRAINT uk_inventory_reservation_dimension
        UNIQUE (sales_order_item_id, inventory_balance_id),
    CONSTRAINT ck_inventory_reservation_quantity CHECK (reserved_quantity > 0),
    CONSTRAINT ck_inventory_reservation_status
        CHECK (status IN ('ACTIVE', 'RELEASED', 'CONSUMED')),
    CONSTRAINT ck_inventory_reservation_release_pair
        CHECK ((released_by IS NULL) = (released_at IS NULL)),
    INDEX idx_inventory_reservation_sales (sales_order_item_id, status),
    INDEX idx_inventory_reservation_balance (inventory_balance_id, status),
    INDEX idx_inventory_reservation_batch (drug_batch_id, status),
    CONSTRAINT fk_inventory_reservation_sales_item
        FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_reservation_balance
        FOREIGN KEY (inventory_balance_id) REFERENCES inventory_balance (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_reservation_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_reservation_reserver
        FOREIGN KEY (reserved_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_inventory_reservation_releaser
        FOREIGN KEY (released_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售订单到合格批号库存的占用关系';

CREATE TABLE outbound_order (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库单主键',
    outbound_no VARCHAR(40) NOT NULL COMMENT '出库单号',
    sales_order_id BIGINT NOT NULL COMMENT '销售订单',
    warehouse_id BIGINT NOT NULL COMMENT '出库仓库',
    status VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '出库状态',
    prepared_by BIGINT NOT NULL COMMENT '备货人',
    submitted_for_review_at DATETIME(3) NULL COMMENT '提交复核时间（UTC）',
    outbound_by BIGINT NULL COMMENT '实际出库执行人',
    outbound_at DATETIME(3) NULL COMMENT '实际出库时间（UTC）',
    delivery_document_no VARCHAR(100) NULL COMMENT '出库或配送单号',
    remark VARCHAR(1000) NULL COMMENT '备注',
    created_by BIGINT NOT NULL COMMENT '创建人',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',
    updated_by BIGINT NULL COMMENT '最后修改人',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间（UTC）',
    version BIGINT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',

    PRIMARY KEY (id),
    CONSTRAINT uk_outbound_order_no UNIQUE (outbound_no),
    CONSTRAINT ck_outbound_order_status
        CHECK (status IN (
            'DRAFT', 'PICKING', 'PENDING_REVIEW', 'REVIEW_FAILED',
            'APPROVED', 'OUTBOUNDED', 'CANCELLED'
        )),
    CONSTRAINT ck_outbound_order_execute_pair
        CHECK ((outbound_by IS NULL) = (outbound_at IS NULL)),
    INDEX idx_outbound_order_sales (sales_order_id, status),
    INDEX idx_outbound_order_warehouse (warehouse_id, status, created_at),
    CONSTRAINT fk_outbound_order_sales
        FOREIGN KEY (sales_order_id) REFERENCES sales_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_preparer
        FOREIGN KEY (prepared_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_executor
        FOREIGN KEY (outbound_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_creator
        FOREIGN KEY (created_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_updater
        FOREIGN KEY (updated_by) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售备货、独立复核与实际出库单';

CREATE TABLE outbound_order_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库明细主键',
    outbound_order_id BIGINT NOT NULL COMMENT '出库单',
    line_no INT NOT NULL COMMENT '出库行号',
    sales_order_item_id BIGINT NOT NULL COMMENT '销售订单明细',
    inventory_reservation_id BIGINT NOT NULL COMMENT '库存占用记录',
    inventory_balance_id BIGINT NOT NULL COMMENT '库存余额',
    drug_batch_id BIGINT NOT NULL COMMENT '出库批次',
    warehouse_location_id BIGINT NOT NULL COMMENT '出库库位',
    outbound_quantity DECIMAL(18, 4) NOT NULL COMMENT '出库数量',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_outbound_order_item_line UNIQUE (outbound_order_id, line_no),
    CONSTRAINT uk_outbound_order_item_reservation
        UNIQUE (outbound_order_id, inventory_reservation_id),
    CONSTRAINT ck_outbound_order_item_line CHECK (line_no > 0),
    CONSTRAINT ck_outbound_order_item_quantity CHECK (outbound_quantity > 0),
    INDEX idx_outbound_order_item_sales (sales_order_item_id),
    INDEX idx_outbound_order_item_batch (drug_batch_id),
    CONSTRAINT fk_outbound_order_item_order
        FOREIGN KEY (outbound_order_id) REFERENCES outbound_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_item_sales
        FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_item (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_item_reservation
        FOREIGN KEY (inventory_reservation_id) REFERENCES inventory_reservation (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_item_balance
        FOREIGN KEY (inventory_balance_id) REFERENCES inventory_balance (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_item_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_item_location
        FOREIGN KEY (warehouse_location_id) REFERENCES warehouse_location (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '销售订单、库存占用、药品批次与出库数量的关联';

CREATE TABLE outbound_order_review (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库复核记录主键',
    outbound_order_id BIGINT NOT NULL COMMENT '出库单',
    review_round INT NOT NULL DEFAULT 1 COMMENT '复核轮次',
    reviewer_id BIGINT NOT NULL COMMENT '独立出库复核人',
    review_result VARCHAR(16) NOT NULL COMMENT 'APPROVED或REJECTED',
    review_opinion VARCHAR(1000) NULL COMMENT '复核意见或问题说明',
    reviewed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '复核时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_outbound_order_review_round
        UNIQUE (outbound_order_id, review_round),
    CONSTRAINT ck_outbound_order_review_round CHECK (review_round > 0),
    CONSTRAINT ck_outbound_order_review_result
        CHECK (review_result IN ('APPROVED', 'REJECTED')),
    INDEX idx_outbound_order_review_user (reviewer_id, reviewed_at),
    CONSTRAINT fk_outbound_order_review_order
        FOREIGN KEY (outbound_order_id) REFERENCES outbound_order (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_outbound_order_review_user
        FOREIGN KEY (reviewer_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '出库独立复核的逐轮记录；复核人与备货人不得相同';

-- ============================================================================
-- 7. 批号全生命周期追溯
-- ============================================================================

CREATE TABLE batch_trace_event (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '追溯事件主键',
    event_no VARCHAR(48) NOT NULL COMMENT '追溯事件编号',
    drug_batch_id BIGINT NOT NULL COMMENT '药品批次',
    event_type VARCHAR(24) NOT NULL COMMENT '生命周期事件类型',
    supplier_id BIGINT NULL COMMENT '上游供应商；采购到入库阶段使用',
    customer_id BIGINT NULL COMMENT '下游客户；销售出库阶段使用',
    warehouse_id BIGINT NULL COMMENT '事件仓库',
    warehouse_location_id BIGINT NULL COMMENT '事件库位',
    inventory_ledger_id BIGINT NULL COMMENT '关联库存流水',
    business_type VARCHAR(32) NOT NULL COMMENT '来源业务类型',
    business_id BIGINT NOT NULL COMMENT '来源业务主键',
    business_no VARCHAR(64) NOT NULL COMMENT '来源业务编号快照',
    quantity DECIMAL(18, 4) NULL COMMENT '事件数量；无数量事件可为空',
    event_data JSON NULL COMMENT '事件证据快照',
    operator_id BIGINT NULL COMMENT '操作人；系统事件可为空',
    occurred_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发生时间（UTC）',

    PRIMARY KEY (id),
    CONSTRAINT uk_batch_trace_event_no UNIQUE (event_no),
    CONSTRAINT ck_batch_trace_event_type
        CHECK (event_type IN (
            'PURCHASED', 'RECEIVED', 'ACCEPTED', 'STOCKED_IN',
            'INVENTORY_CHANGED', 'RESERVED', 'RELEASED',
            'OUTBOUNDED', 'RETURNED', 'QUARANTINED'
        )),
    CONSTRAINT ck_batch_trace_event_quantity
        CHECK (quantity IS NULL OR quantity > 0),
    INDEX idx_batch_trace_event_batch (drug_batch_id, occurred_at),
    INDEX idx_batch_trace_event_supplier (supplier_id, occurred_at),
    INDEX idx_batch_trace_event_customer (customer_id, occurred_at),
    INDEX idx_batch_trace_event_business (business_type, business_id),
    INDEX idx_batch_trace_event_ledger (inventory_ledger_id),
    CONSTRAINT fk_batch_trace_event_batch
        FOREIGN KEY (drug_batch_id) REFERENCES drug_batch (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_customer
        FOREIGN KEY (customer_id) REFERENCES customer (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_location
        FOREIGN KEY (warehouse_location_id) REFERENCES warehouse_location (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_ledger
        FOREIGN KEY (inventory_ledger_id) REFERENCES inventory_ledger (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_batch_trace_event_operator
        FOREIGN KEY (operator_id) REFERENCES sys_user (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci
  COMMENT = '以药品批号为主线的采购、验收、库存、销售和客户去向事件';

-- ============================================================================
-- 8. 必须由应用服务和数据库权限共同保证的跨表规则
-- ============================================================================

-- 1. 采购订单只能引用同一供应商最近有效且 APPROVED 的 supplier_review；
--    supplier.qualification_status 必须为 APPROVED，valid_until 不得早于下单日。
-- 2. 销售订单只能引用同一客户有效且 APPROVED 的 customer_review；
--    customer.qualification_status 必须为 APPROVED，且经营范围必须覆盖所购药品。
-- 3. purchase_order_item、goods_receipt_item、acceptance_record_item 中的药品、
--    生产企业、批号和有效期必须保持一致；发现差异只能生成异常记录，不得覆盖原始值。
-- 4. acceptance_record.inspector_id 不得等于 goods_receipt.received_by；
--    只有 acceptance_record_item.qualified_quantity 可以进入 stock_in_order_item。
-- 5. 入库过账、inventory_balance 更新、inventory_ledger 写入、drug_batch 状态更新和
--    batch_trace_event 写入必须处于同一事务，并使用 idempotency_key 防止重复入库。
-- 6. 禁止绕过 inventory_ledger 直接修改 inventory_balance；并发扣减必须锁定余额行或
--    使用 version 进行乐观锁校验，任何数量字段不得出现负数。
-- 7. 库存占用仅允许 quality_status=QUALIFIED、stock_status=ACTIVE、未过期且未冻结的批次；
--    占用数量不得超过 available_quantity，占用与流水必须同事务写入。
-- 8. 出库前必须存在 APPROVED 的 outbound_order_review，复核人不得等于 prepared_by；
--    实际出库数量不得超过有效占用数量，扣减与追溯事件必须同事务完成。
-- 9. sys_operation_log、sys_permission_change_log、business_status_history、
--    inventory_ledger 和 batch_trace_event 均为追加式记录。生产数据库账号应撤销这些表的
--    UPDATE、DELETE 权限；纠错通过新增冲正或补充记录完成，不能覆盖历史。
-- 10. sys_attachment、sys_operation_log、business_status_history 等通用表使用
--     business_type + business_id 关联业务对象，应用服务必须校验对象存在且类型匹配。
-- 11. 关键业务记录不做物理删除；撤销、驳回、失效、冻结和关闭均通过状态及状态历史表达。
-- 12. 所有服务端时间按 UTC 写入，展示时再按用户时区转换。
-- 13. sys_department 与 sys_permission 的父子关系不得指向自身或形成环；MySQL 不允许
--     CHECK 引用自增主键，因此该规则由服务层在保存树节点时校验。
