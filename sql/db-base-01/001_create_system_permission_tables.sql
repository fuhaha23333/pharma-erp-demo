SET SESSION time_zone = '+00:00';

CREATE TABLE sys_user (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'DISABLED',
    created_by BIGINT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_by BIGINT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),
    version BIGINT NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_user_username
        UNIQUE (username),
    CONSTRAINT ck_sys_user_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    CONSTRAINT ck_sys_user_username_nonblank
        CHECK (CHAR_LENGTH(TRIM(username)) > 0),
    CONSTRAINT ck_sys_user_display_name_nonblank
        CHECK (CHAR_LENGTH(TRIM(display_name)) > 0),
    CONSTRAINT ck_sys_user_password_hash_nonblank
        CHECK (CHAR_LENGTH(TRIM(password_hash)) > 0),
    INDEX idx_sys_user_status (status),
    CONSTRAINT fk_sys_user_created_by
        FOREIGN KEY (created_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE sys_role (
    id BIGINT NOT NULL AUTO_INCREMENT,
    role_code VARCHAR(32) NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    risk_level VARCHAR(16) NOT NULL,
    description VARCHAR(500) NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    is_builtin TINYINT NOT NULL DEFAULT 1,
    created_by BIGINT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_by BIGINT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),
    version BIGINT NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_code
        UNIQUE (role_code),
    CONSTRAINT uk_sys_role_name
        UNIQUE (role_name),
    CONSTRAINT ck_sys_role_risk_level
        CHECK (risk_level IN ('NORMAL', 'HIGH')),
    CONSTRAINT ck_sys_role_status
        CHECK (status IN ('ACTIVE', 'DISABLED')),
    CONSTRAINT ck_sys_role_is_builtin
        CHECK (is_builtin IN (0, 1)),
    INDEX idx_sys_role_status (status),
    CONSTRAINT fk_sys_role_created_by
        FOREIGN KEY (created_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE sys_permission (
    id BIGINT NOT NULL AUTO_INCREMENT,
    permission_code VARCHAR(32) NOT NULL,
    permission_name VARCHAR(160) NOT NULL,
    module_code VARCHAR(16) NOT NULL,
    execution_mode VARCHAR(32) NOT NULL,
    description VARCHAR(500) NULL,
    is_builtin TINYINT NOT NULL DEFAULT 1,
    created_by BIGINT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_by BIGINT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),
    version BIGINT NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_permission_code
        UNIQUE (permission_code),
    CONSTRAINT ck_sys_permission_module
        CHECK (
            module_code IN (
                'SYS',
                'MD',
                'QA',
                'PO',
                'RC',
                'ACPT',
                'INV',
                'SO',
                'OUT',
                'TRACE',
                'QE',
                'GD',
                'DEMO',
                'BAK'
            )
        ),
    CONSTRAINT ck_sys_permission_execution_mode
        CHECK (
            execution_mode IN (
                'ROLE',
                'ROLE_AND_SYSTEM',
                'SYSTEM',
                'PROHIBITED',
                'NOT_OPEN'
            )
        ),
    CONSTRAINT ck_sys_permission_is_builtin
        CHECK (is_builtin IN (0, 1)),
    INDEX idx_sys_permission_module (module_code),
    INDEX idx_sys_permission_mode (execution_mode),
    CONSTRAINT fk_sys_permission_created_by
        FOREIGN KEY (created_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_permission_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE sys_role_assignment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    assignment_no VARCHAR(40) NOT NULL,
    target_user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assignment_type VARCHAR(16) NOT NULL,
    approval_required TINYINT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING_REVIEW',
    requested_by BIGINT NOT NULL,
    requested_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    reviewed_by BIGINT NULL,
    reviewed_at DATETIME(3) NULL,
    review_opinion VARCHAR(1000) NULL,
    approved_by BIGINT NULL,
    approved_at DATETIME(3) NULL,
    approval_opinion VARCHAR(1000) NULL,
    executed_by BIGINT NULL,
    executed_at DATETIME(3) NULL,
    execution_error VARCHAR(1000) NULL,
    valid_from DATETIME(3) NULL,
    valid_to DATETIME(3) NULL,
    reason VARCHAR(500) NOT NULL,
    created_by BIGINT NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_by BIGINT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),
    version BIGINT NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_assignment_no
        UNIQUE (assignment_no),
    CONSTRAINT ck_sys_role_assignment_type
        CHECK (assignment_type IN ('GRANT', 'REVOKE')),
    CONSTRAINT ck_sys_role_assignment_approval
        CHECK (approval_required IN (0, 1)),
    CONSTRAINT ck_sys_role_assignment_status
        CHECK (
            status IN (
                'PENDING_REVIEW',
                'PENDING_APPROVAL',
                'PENDING_EXECUTION',
                'REJECTED',
                'EXECUTED',
                'EXECUTION_FAILED'
            )
        ),
    CONSTRAINT ck_sys_role_assignment_valid_period
        CHECK (
            valid_to IS NULL
            OR (
                valid_from IS NOT NULL
                AND valid_from <= valid_to
            )
        ),
    CONSTRAINT ck_sys_role_assignment_creator
        CHECK (created_by = requested_by),
    CONSTRAINT ck_sys_role_assignment_review_pair
        CHECK ((reviewed_by IS NULL) = (reviewed_at IS NULL)),
    CONSTRAINT ck_sys_role_assignment_approve_pair
        CHECK ((approved_by IS NULL) = (approved_at IS NULL)),
    CONSTRAINT ck_sys_role_assignment_execute_pair
        CHECK ((executed_by IS NULL) = (executed_at IS NULL)),
    CONSTRAINT ck_sys_role_assignment_review_sod
        CHECK (
            reviewed_by IS NULL
            OR (
                reviewed_by <> requested_by
                AND reviewed_by <> target_user_id
            )
        ),
    CONSTRAINT ck_sys_role_assignment_approve_sod
        CHECK (
            approved_by IS NULL
            OR (
                approved_by <> requested_by
                AND approved_by <> target_user_id
            )
        ),
    CONSTRAINT ck_sys_role_assignment_review_approve_sod
        CHECK (
            reviewed_by IS NULL
            OR approved_by IS NULL
            OR reviewed_by <> approved_by
        ),
    CONSTRAINT ck_sys_role_assignment_execute_sod
        CHECK (
            approved_by IS NULL
            OR executed_by IS NULL
            OR approved_by <> executed_by
        ),
    INDEX idx_sys_role_assignment_target_status (target_user_id, status),
    INDEX idx_sys_role_assignment_role_status (role_id, status),
    INDEX idx_sys_role_assignment_status_requested (status, requested_at),
    CONSTRAINT fk_sys_role_assignment_target
        FOREIGN KEY (target_user_id)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_role
        FOREIGN KEY (role_id)
        REFERENCES sys_role (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_requested
        FOREIGN KEY (requested_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_reviewed
        FOREIGN KEY (reviewed_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_approved
        FOREIGN KEY (approved_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_executed
        FOREIGN KEY (executed_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_created
        FOREIGN KEY (created_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_assignment_updated
        FOREIGN KEY (updated_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE sys_user_role (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    valid_from DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    valid_to DATETIME(3) NULL,
    source_assignment_id BIGINT NULL,
    created_by BIGINT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_by BIGINT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
        ON UPDATE CURRENT_TIMESTAMP(3),
    version BIGINT NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_user_role
        UNIQUE (user_id, role_id),
    CONSTRAINT uk_sys_user_role_source_assignment
        UNIQUE (source_assignment_id),
    CONSTRAINT ck_sys_user_role_status
        CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
    CONSTRAINT ck_sys_user_role_valid_period
        CHECK (valid_to IS NULL OR valid_from <= valid_to),
    INDEX idx_sys_user_role_user_status (user_id, status, valid_to),
    INDEX idx_sys_user_role_role_status (role_id, status, valid_to),
    CONSTRAINT fk_sys_user_role_user
        FOREIGN KEY (user_id)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_role
        FOREIGN KEY (role_id)
        REFERENCES sys_role (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_assignment
        FOREIGN KEY (source_assignment_id)
        REFERENCES sys_role_assignment (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_created_by
        FOREIGN KEY (created_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_user_role_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES sys_user (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE sys_role_permission (
    id BIGINT NOT NULL AUTO_INCREMENT,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    source_matrix_version VARCHAR(32) NOT NULL DEFAULT 'v1.1',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (id),
    CONSTRAINT uk_sys_role_permission
        UNIQUE (role_id, permission_id),
    INDEX idx_sys_role_permission_permission (permission_id),
    CONSTRAINT fk_sys_role_permission_role
        FOREIGN KEY (role_id)
        REFERENCES sys_role (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,
    CONSTRAINT fk_sys_role_permission_permission
        FOREIGN KEY (permission_id)
        REFERENCES sys_permission (id)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
