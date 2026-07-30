
# DB-BASE-01：系统权限数据库基线

> **文档定位：** 本文件是 `DB-BASE-01` 的正式实施规格，用于关闭六张系统权限表物理字段、角色—权限关系和MySQL物理约束命名的实施阻塞。它不是DDL、不是已完成证明，也不修改冻结业务设计。

## 1. 文档信息

| 项目           | 内容                                                          |
| -------------- | ------------------------------------------------------------- |
| 文档版本       | v1.0                                                          |
| 文档状态       | 执行规格                                                      |
| 制定日期       | 2026-07-29                                                    |
| 适用项目       | `pharma-erp-demo`                                           |
| Goal编号       | `DB-BASE-01`                                                |
| Goal名称       | 系统权限数据库基线                                            |
| 所属里程碑     | M1                                                            |
| Goal类型       | 数据库、种子数据、数据库验证                                  |
| 当前状态       | 准备中                                                        |
| 预期分支       | `feat/database-baseline`                                    |
| Goal起始基线   | `9575856`                                                   |
| 主线冻结基线   | `cef15bc`                                                   |
| 规格审查       | 已完成物理字段、RBAC映射、MySQL 8.4约束边界和验证安全规则审查 |
| 提交与push授权 | 默认不得commit、不得push、不得合并、不得创建标签              |

## 2. 目标与业务价值

### 2.1 目标

从隔离空Schema建立以下六张系统权限表，并形成可重复验证证据：

```text
sys_user
sys_role
sys_permission
sys_role_assignment
sys_user_role
sys_role_permission
```

### 2.2 业务价值

本Goal只建立后续登录、权限阻断、角色分配和审计所需的数据库基础，不实现登录框架或业务接口。

### 2.3 实施与完成边界

本Goal只交付系统权限数据库基础结构、基础种子数据和数据库验证证据。

本Goal包含：

- 六张系统权限相关表的DDL；
- 10个正式角色种子；
- 160个权限目录种子；
- 233条角色—权限关系种子；
- 数据库约束、索引和负向场景验证。

本Goal不实现：

- 用户登录和密码校验；
- Token或Sa-Token接入；
- 后端权限拦截；
- 角色申请、审核、批准和执行的Java Service；
- HTTP接口和前端页面；
- 公共审计表；
- 演示用户和密码。

本Goal完成只能证明：

- 六表DDL可在隔离空Schema执行；
- 10个冻结角色、160个权限和233条角色权限关系可机械核对；
- 关键主键、外键、唯一约束、CHECK和索引有效；
- 验证脚本可以重复运行；
- 没有修改Drug模块，也没有创建其余45张候选表。

本Goal不能证明登录、权限拦截、审批Service、HTTP接口、前端或业务合规已经实现。

### 2.4 数据库基础与后续业务守卫边界

本Goal中的`sys_role_permission`只保存角色参与某个权限动作族的**粗粒度资格**，不代表该角色可以执行该权限编号下的全部阶段动作。

例如，同一权限可能同时包含：

```text
业务角色发起
→ 质量管理员审核
→ 质量负责人批准
→ 系统管理员技术执行
```

附录A会为参与该动作族的明确正式角色建立关系；后续Service仍必须结合：

```text
当前登录角色
+
业务对象状态
+
本次具体动作阶段
+
数据范围
+
申请、审核、批准、执行职责冲突
```

进行第二层守卫。后续接口不得只依赖一个`permission_code`就放行多阶段高风险动作。

`sys_role_assignment`在本Goal中只交付：

- 持久化字段；
- 行内状态值；
- 同一行可表达的CHECK；
- 外键和索引。

以下规则涉及其他表状态或业务流程，MySQL行级CHECK无法完整表达，留给`AUTH-BASE-01`的Service和集成测试：

- `role_id`对应高风险角色时必须`approval_required = 1`；
- 只有`EXECUTED`角色分配记录才能驱动`sys_user_role`；
- 具体状态转换是否合法；
- 谁可以执行审核、批准和技术执行；
- 授权、撤销与当前角色关系如何原子更新。

DB-BASE-01不得通过触发器或额外工作流表提前实现上述业务。

## 3. 权威依据与优先级

按以下优先级执行：

1. 本文件经人工批准后的明确实施决策；
2. `docs/DEMO_SCOPE.md` v1.1；
3. `docs/BUSINESS_FLOW.md` v1.0；
4. `docs/BUSINESS_STATE_MACHINE.md` v1.1；
5. `docs/ROLE_PERMISSION_MATRIX.md` v1.1；
6. `docs/DATABASE_DESIGN_DEMO.md` v1.0；
7. `docs/DEMO_PLAN.md` v1.0中的`DB-BASE-01`；
8. `docs/CURRENT_STATE.md` v2.0；
9. `docs/GOAL_TEMPLATE.md` v1.0；
10. 根目录`AGENTS.md`；
11. 经当前仓库重新核验后仍有效的`docs/TECH_DEBT.md`条目。

发现冲突时停止实施并报告，不得修改冻结文档迁就DDL。

## 4. 开始前事实检查

预期：

```text
分支：feat/database-baseline
HEAD：本文件提交后的最新分支HEAD
工作区：干净
```

必须执行：

```bash
git branch --show-current
git status --short
git rev-parse --short HEAD
git log --oneline --decorate -n 8
find .. -name AGENTS.md -not -path '*/.git/*' -print
```

开始条件不符合时停止，不清理现场、不切换分支、不改写历史。

## 5. 实施前决策点

### 5.1 DP-01：SQL文件和执行顺序

本Goal不引入Flyway、Liquibase或其他完整迁移平台。长期迁移机制留给`DB-MIG-01`。

允许新增：

```text
sql/db-base-01/001_create_system_permission_tables.sql
sql/db-base-01/002_seed_system_permission_data.sql
scripts/verify_db_base_01.sh
```

固定顺序：

```text
创建隔离Schema
→ 执行001建表
→ 执行002种子
→ 执行验证断言
→ 成功后删除隔离Schema
```

`001`和`002`只面向空Schema，不使用大量`IF NOT EXISTS`掩盖重复执行错误。脚本内容一旦验收并进入后续迁移机制，不得直接改写历史版本。

### 5.2 DP-02：角色与权限种子

采用仓库内显式、可逐行审查的SQL：

- 10个角色；
- 160个权限；
- 233条角色权限关系；
- 不创建用户、用户角色或角色分配业务数据；
- 不使用通配权限；
- 不由Java启动时动态生成权限目录；
- 不保存演示密码或明文密码。

`permission_code`直接使用权限矩阵编号，例如`SYS-001`、`MD-001`、`BAK-010`。

种子脚本不得假定自增主键固定为某些数字。`sys_role_permission`必须通过`role_code`和`permission_code`解析实际主键后插入。

附录A是本Goal中角色—权限关系的唯一种子来源；实施时不得再次解析权限矩阵自然语言并生成另一套结果。

### 5.3 DP-03：隔离Schema和连接方式

固定Schema：

```text
pharma_erp_db_base_01_test
```

连接要求：

- 必须使用本地`mysql_config_editor`保存的login-path；
- 环境变量`DB_BASE_01_MYSQL_LOGIN_PATH`指定login-path名称；
- login-path名称必须匹配`^[A-Za-z0-9_.-]+$`，否则立即退出；
- 不在仓库、命令行参数、日志或脚本中保存密码；
- 不在验证输出中执行或展示`mysql_config_editor print --all`；
- 连接账号必须具有创建、删除该测试Schema、执行DDL/DML和读取Information Schema的权限；
- 不创建或修改数据库账号。

安全规则：

- 脚本只能创建和删除精确名称`pharma_erp_db_base_01_test`；
- 执行任何`DROP DATABASE`前，环境变量`DB_BASE_01_CONFIRM_DROP`必须精确等于`pharma_erp_db_base_01_test`；
- 检测到其他Schema名称立即退出；
- 禁止连接或修改`pharma_erp`；
- 每次从空Schema开始；
- 验证成功后删除测试Schema；
- 验证失败时保留测试Schema并输出名称，便于人工检查；下次运行先经精确名称守卫后重建。

## 6. 文件、数据库和配置授权

### 6.1 允许新增文件

```text
sql/db-base-01/001_create_system_permission_tables.sql
sql/db-base-01/002_seed_system_permission_data.sql
scripts/verify_db_base_01.sh
```

### 6.2 允许修改文件

不允许修改现有文件。

### 6.3 允许删除文件

不允许。

### 6.4 允许修改数据库对象

只允许在`pharma_erp_db_base_01_test`中创建、写入、验证和删除：

```text
sys_user
sys_role
sys_permission
sys_role_assignment
sys_user_role
sys_role_permission
```

### 6.5 依赖和配置

不允许修改：

```text
backend/pom.xml
backend/src/main/resources/application.yml
任何Java文件
任何前端文件
```

不引入Flyway、Sa-Token或其他依赖。

## 7. 明确不包含与禁止事项

明确不包含：

- Drug模块与旧`drug`表迁移；
- 其余45张候选表；
- 登录、会话和权限拦截；
- 公共审计表；
- 角色分配Java Service；
- HTTP接口和前端；
- 演示用户、账号和密码；
- 完整数据库迁移平台；
- 采购、收货、验收、库存、销售、出库和追溯实现。

禁止：

- 修改冻结设计文档；
- 修改旧`sql/001_create_drug_table.sql`；
- 修改Drug模块；
- 在`pharma_erp`上运行验证；
- 关闭`foreign_key_checks`绕过正常建表或种子顺序；
- 使用`CASCADE`删除角色、权限或用户关系；
- 使用MySQL`ENUM`保存状态；
- 使用通配权限；
- 把系统动作分配给虚构角色；
- 写入明文密码；
- commit、push、合并或打标签。

## 8. 数据库统一规则

- MySQL：8.4.x，当前验证环境目标为8.4.10；
- 引擎：InnoDB；
- Schema字符集：utf8mb4；
- Schema排序规则：utf8mb4_0900_ai_ci；
- 会话时区：`+00:00`；
- SQL Mode至少包含：`ONLY_FULL_GROUP_BY`、`STRICT_TRANS_TABLES`、`NO_ZERO_IN_DATE`、`NO_ZERO_DATE`、`ERROR_FOR_DIVISION_BY_ZERO`、`NO_ENGINE_SUBSTITUTION`；
- 主键：`BIGINT AUTO_INCREMENT`；
- 状态：`VARCHAR`加命名CHECK，不使用MySQL ENUM；
- 业务时刻：`DATETIME(3)`；
- 外键默认：`ON DELETE RESTRICT ON UPDATE RESTRICT`；
- 主键遵循MySQL固定物理名称`PRIMARY`；其余唯一约束、CHECK、普通索引和外键必须显式命名；`pk_*`仅作为本文档逻辑标签；
- 正常验证保持外键检查开启；
- DDL中不得创建本Goal范围外表；
- CHECK只表达同一行内、确定性的条件，不引用其他表，不使用`NOW()`等非确定函数；
- 跨表业务不变量必须在后续Service和集成测试中验证，不得伪称已由本Goal的CHECK保证；
- `DROP DATABASE`会删除测试Schema内全部表，只允许在固定Schema和双重名称守卫通过后执行。

## 9. 六张表物理定义

### sys_user

| 字段          | 类型         | NULL / 默认                                                          | 用途                                           |
| ------------- | ------------ | -------------------------------------------------------------------- | ---------------------------------------------- |
| id            | BIGINT       | NOT NULL AUTO_INCREMENT                                              | 内部主键                                       |
| username      | VARCHAR(64)  | NOT NULL                                                             | 登录名；大小写唯一性由 utf8mb4_0900_ai_ci 决定 |
| display_name  | VARCHAR(100) | NOT NULL                                                             | 演示显示名                                     |
| password_hash | VARCHAR(255) | NOT NULL                                                             | 只保存哈希编码；算法留待 AUTH-BASE-01          |
| status        | VARCHAR(32)  | NOT NULL DEFAULT 'DISABLED'                                          | ACTIVE / DISABLED                              |
| created_by    | BIGINT       | NULL                                                                 | 创建人；启动阶段允许为空；自引用 sys_user.id   |
| created_at    | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | UTC会话下写入                                  |
| updated_by    | BIGINT       | NULL                                                                 | 更新人；自引用 sys_user.id                     |
| updated_at    | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) | UTC会话下写入                                  |
| version       | BIGINT       | NOT NULL DEFAULT 0                                                   | 乐观版本                                       |

### sys_role

| 字段        | 类型         | NULL / 默认                                                          | 用途                     |
| ----------- | ------------ | -------------------------------------------------------------------- | ------------------------ |
| id          | BIGINT       | NOT NULL AUTO_INCREMENT                                              | 内部主键                 |
| role_code   | VARCHAR(32)  | NOT NULL                                                             | 固定英文角色代码         |
| role_name   | VARCHAR(100) | NOT NULL                                                             | 冻结中文角色名称         |
| risk_level  | VARCHAR(16)  | NOT NULL                                                             | NORMAL / HIGH            |
| description | VARCHAR(500) | NULL                                                                 | 角色职责摘要             |
| status      | VARCHAR(32)  | NOT NULL DEFAULT 'ACTIVE'                                            | ACTIVE / DISABLED        |
| is_builtin  | TINYINT      | NOT NULL DEFAULT 1                                                   | 0 / 1；10个冻结角色均为1 |
| created_by  | BIGINT       | NULL                                                                 | 创建人；引用 sys_user.id |
| created_at  | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | UTC会话下写入            |
| updated_by  | BIGINT       | NULL                                                                 | 更新人；引用 sys_user.id |
| updated_at  | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) | UTC会话下写入            |
| version     | BIGINT       | NOT NULL DEFAULT 0                                                   | 乐观版本                 |

### sys_permission

| 字段            | 类型         | NULL / 默认                                                          | 用途                                                    |
| --------------- | ------------ | -------------------------------------------------------------------- | ------------------------------------------------------- |
| id              | BIGINT       | NOT NULL AUTO_INCREMENT                                              | 内部主键                                                |
| permission_code | VARCHAR(32)  | NOT NULL                                                             | 直接使用矩阵权限编号                                    |
| permission_name | VARCHAR(160) | NOT NULL                                                             | 矩阵“业务对象与动作”                                  |
| module_code     | VARCHAR(16)  | NOT NULL                                                             | 权限编号前缀                                            |
| execution_mode  | VARCHAR(32)  | NOT NULL                                                             | ROLE / ROLE_AND_SYSTEM / SYSTEM / PROHIBITED / NOT_OPEN |
| description     | VARCHAR(500) | NULL                                                                 | 首版可为空                                              |
| is_builtin      | TINYINT      | NOT NULL DEFAULT 1                                                   | 0 / 1；160个冻结权限均为1                               |
| created_by      | BIGINT       | NULL                                                                 | 创建人；引用 sys_user.id                                |
| created_at      | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | UTC会话下写入                                           |
| updated_by      | BIGINT       | NULL                                                                 | 更新人；引用 sys_user.id                                |
| updated_at      | DATETIME(3)  | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) | UTC会话下写入                                           |
| version         | BIGINT       | NOT NULL DEFAULT 0                                                   | 乐观版本                                                |

### sys_role_assignment

| 字段              | 类型          | NULL / 默认                                                          | 用途                       |
| ----------------- | ------------- | -------------------------------------------------------------------- | -------------------------- |
| id                | BIGINT        | NOT NULL AUTO_INCREMENT                                              | 内部主键                   |
| assignment_no     | VARCHAR(40)   | NOT NULL                                                             | 角色分配业务编号           |
| target_user_id    | BIGINT        | NOT NULL                                                             | 被授权或被撤销角色的用户   |
| role_id           | BIGINT        | NOT NULL                                                             | 目标角色                   |
| assignment_type   | VARCHAR(16)   | NOT NULL                                                             | GRANT / REVOKE             |
| approval_required | TINYINT       | NOT NULL                                                             | 0 / 1；高风险角色为1       |
| status            | VARCHAR(32)   | NOT NULL DEFAULT 'PENDING_REVIEW'                                    | 见状态集合                 |
| requested_by      | BIGINT        | NOT NULL                                                             | 申请人                     |
| requested_at      | DATETIME(3)   | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | 申请时间                   |
| reviewed_by       | BIGINT        | NULL                                                                 | 质量管理员审核人           |
| reviewed_at       | DATETIME(3)   | NULL                                                                 | 审核时间                   |
| review_opinion    | VARCHAR(1000) | NULL                                                                 | 审核意见                   |
| approved_by       | BIGINT        | NULL                                                                 | 高风险角色批准人           |
| approved_at       | DATETIME(3)   | NULL                                                                 | 批准时间                   |
| approval_opinion  | VARCHAR(1000) | NULL                                                                 | 批准意见                   |
| executed_by       | BIGINT        | NULL                                                                 | 技术执行人                 |
| executed_at       | DATETIME(3)   | NULL                                                                 | 执行时间                   |
| execution_error   | VARCHAR(1000) | NULL                                                                 | 执行失败原因               |
| valid_from        | DATETIME(3)   | NULL                                                                 | 授权生效时间；撤销时可为空 |
| valid_to          | DATETIME(3)   | NULL                                                                 | 授权失效时间               |
| reason            | VARCHAR(500)  | NOT NULL                                                             | 申请原因                   |
| created_by        | BIGINT        | NOT NULL                                                             | 必须等于 requested_by      |
| created_at        | DATETIME(3)   | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | 创建时间                   |
| updated_by        | BIGINT        | NULL                                                                 | 最后更新人                 |
| updated_at        | DATETIME(3)   | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) | 更新时间                   |
| version           | BIGINT        | NOT NULL DEFAULT 0                                                   | 乐观版本                   |

### sys_user_role

| 字段                 | 类型        | NULL / 默认                                                          | 用途                               |
| -------------------- | ----------- | -------------------------------------------------------------------- | ---------------------------------- |
| id                   | BIGINT      | NOT NULL AUTO_INCREMENT                                              | 内部主键                           |
| user_id              | BIGINT      | NOT NULL                                                             | 用户                               |
| role_id              | BIGINT      | NOT NULL                                                             | 角色                               |
| status               | VARCHAR(32) | NOT NULL DEFAULT 'ACTIVE'                                            | ACTIVE / REVOKED / EXPIRED         |
| valid_from           | DATETIME(3) | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | 生效时间                           |
| valid_to             | DATETIME(3) | NULL                                                                 | 失效时间                           |
| source_assignment_id | BIGINT      | NULL                                                                 | 产生或最后变更该关系的角色分配记录 |
| created_by           | BIGINT      | NULL                                                                 | 创建人；引用 sys_user.id           |
| created_at           | DATETIME(3) | NOT NULL DEFAULT CURRENT_TIMESTAMP(3)                                | 创建时间                           |
| updated_by           | BIGINT      | NULL                                                                 | 更新人；引用 sys_user.id           |
| updated_at           | DATETIME(3) | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) | 更新时间                           |
| version              | BIGINT      | NOT NULL DEFAULT 0                                                   | 乐观版本                           |

### sys_role_permission

| 字段                  | 类型        | NULL / 默认                           | 用途         |
| --------------------- | ----------- | ------------------------------------- | ------------ |
| id                    | BIGINT      | NOT NULL AUTO_INCREMENT               | 内部主键     |
| role_id               | BIGINT      | NOT NULL                              | 角色         |
| permission_id         | BIGINT      | NOT NULL                              | 权限         |
| source_matrix_version | VARCHAR(32) | NOT NULL DEFAULT 'v1.1'               | 来源矩阵版本 |
| created_at            | DATETIME(3) | NOT NULL DEFAULT CURRENT_TIMESTAMP(3) | 创建时间     |

## 10. 约束、索引与外键

> **MySQL主键命名说明：** 六张表都使用`PRIMARY KEY (id)`。在MySQL 8.4的索引元数据中，主键名称固定为`PRIMARY`，不能物理命名为`pk_sys_user`等名称。下表中的`pk_*`仅用于文档阅读、审查和跨数据库概念对照，不得写入需要在MySQL元数据中出现的验收条件。

| 表                  | 物理名称 / 文档逻辑标签                     | 定义                                                                                                         | 目的                             |
| ------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| sys_user            | PRIMARY（逻辑标签：pk_sys_user）            | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_user            | uk_sys_user_username                        | UNIQUE (username)                                                                                            | 用户名唯一                       |
| sys_user            | ck_sys_user_status                          | status IN ('ACTIVE','DISABLED')                                                                              | 账号状态                         |
| sys_user            | ck_sys_user_username_nonblank               | CHAR_LENGTH(TRIM(username)) > 0                                                                              | 用户名非空白                     |
| sys_user            | ck_sys_user_display_name_nonblank           | CHAR_LENGTH(TRIM(display_name)) > 0                                                                          | 显示名非空白                     |
| sys_user            | ck_sys_user_password_hash_nonblank          | CHAR_LENGTH(TRIM(password_hash)) > 0                                                                         | 哈希非空白                       |
| sys_user            | idx_sys_user_status                         | INDEX (status)                                                                                               | 状态查询                         |
| sys_user            | fk_sys_user_created_by                      | created_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 自引用                           |
| sys_user            | fk_sys_user_updated_by                      | updated_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 自引用                           |
| sys_role            | PRIMARY（逻辑标签：pk_sys_role）            | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_role            | uk_sys_role_code                            | UNIQUE (role_code)                                                                                           | 角色代码唯一                     |
| sys_role            | uk_sys_role_name                            | UNIQUE (role_name)                                                                                           | 中文名称唯一                     |
| sys_role            | ck_sys_role_risk_level                      | risk_level IN ('NORMAL','HIGH')                                                                              | 风险级别                         |
| sys_role            | ck_sys_role_status                          | status IN ('ACTIVE','DISABLED')                                                                              | 角色状态                         |
| sys_role            | ck_sys_role_is_builtin                      | is_builtin IN (0,1)                                                                                          | 内置标识                         |
| sys_role            | idx_sys_role_status                         | INDEX (status)                                                                                               | 状态查询                         |
| sys_role            | fk_sys_role_created_by                      | created_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 创建人                           |
| sys_role            | fk_sys_role_updated_by                      | updated_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 更新人                           |
| sys_permission      | PRIMARY（逻辑标签：pk_sys_permission）      | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_permission      | uk_sys_permission_code                      | UNIQUE (permission_code)                                                                                     | 权限代码唯一                     |
| sys_permission      | ck_sys_permission_module                    | module_code IN ('SYS','MD','QA','PO','RC','ACPT','INV','SO','OUT','TRACE','QE','GD','DEMO','BAK')            | 模块代码                         |
| sys_permission      | ck_sys_permission_execution_mode            | execution_mode IN ('ROLE','ROLE_AND_SYSTEM','SYSTEM','PROHIBITED','NOT_OPEN')                                | 执行模式                         |
| sys_permission      | ck_sys_permission_is_builtin                | is_builtin IN (0,1)                                                                                          | 内置标识                         |
| sys_permission      | idx_sys_permission_module                   | INDEX (module_code)                                                                                          | 模块查询                         |
| sys_permission      | idx_sys_permission_mode                     | INDEX (execution_mode)                                                                                       | 模式查询                         |
| sys_permission      | fk_sys_permission_created_by                | created_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 创建人                           |
| sys_permission      | fk_sys_permission_updated_by                | updated_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 更新人                           |
| sys_role_assignment | PRIMARY（逻辑标签：pk_sys_role_assignment） | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_role_assignment | uk_sys_role_assignment_no                   | UNIQUE (assignment_no)                                                                                       | 业务编号唯一                     |
| sys_role_assignment | ck_sys_role_assignment_type                 | assignment_type IN ('GRANT','REVOKE')                                                                        | 申请类型                         |
| sys_role_assignment | ck_sys_role_assignment_approval             | approval_required IN (0,1)                                                                                   | 是否需批准                       |
| sys_role_assignment | ck_sys_role_assignment_status               | status IN ('PENDING_REVIEW','PENDING_APPROVAL','PENDING_EXECUTION','REJECTED','EXECUTED','EXECUTION_FAILED') | 状态集合                         |
| sys_role_assignment | ck_sys_role_assignment_valid_period         | valid_to IS NULL OR (valid_from IS NOT NULL AND valid_from <= valid_to)                                      | 有效期                           |
| sys_role_assignment | ck_sys_role_assignment_creator              | created_by = requested_by                                                                                    | 创建人与申请人一致               |
| sys_role_assignment | ck_sys_role_assignment_review_pair          | (reviewed_by IS NULL) = (reviewed_at IS NULL)                                                                | 审核人时间成对                   |
| sys_role_assignment | ck_sys_role_assignment_approve_pair         | (approved_by IS NULL) = (approved_at IS NULL)                                                                | 批准人时间成对                   |
| sys_role_assignment | ck_sys_role_assignment_execute_pair         | (executed_by IS NULL) = (executed_at IS NULL)                                                                | 执行人时间成对                   |
| sys_role_assignment | ck_sys_role_assignment_review_sod           | reviewed_by IS NULL OR (reviewed_by <> requested_by AND reviewed_by <> target_user_id)                       | 审核职责分离                     |
| sys_role_assignment | ck_sys_role_assignment_approve_sod          | approved_by IS NULL OR (approved_by <> requested_by AND approved_by <> target_user_id)                       | 批准职责分离                     |
| sys_role_assignment | ck_sys_role_assignment_review_approve_sod   | reviewed_by IS NULL OR approved_by IS NULL OR reviewed_by <> approved_by                                     | 审核与批准分离                   |
| sys_role_assignment | ck_sys_role_assignment_execute_sod          | approved_by IS NULL OR executed_by IS NULL OR approved_by <> executed_by                                     | 批准与执行分离                   |
| sys_role_assignment | idx_sys_role_assignment_target_status       | INDEX (target_user_id, status)                                                                               | 用户任务查询                     |
| sys_role_assignment | idx_sys_role_assignment_role_status         | INDEX (role_id, status)                                                                                      | 角色任务查询                     |
| sys_role_assignment | idx_sys_role_assignment_status_requested    | INDEX (status, requested_at)                                                                                 | 队列查询                         |
| sys_role_assignment | fk_sys_role_assignment_target               | target_user_id -> sys_user.id RESTRICT/RESTRICT                                                              | 目标用户                         |
| sys_role_assignment | fk_sys_role_assignment_role                 | role_id -> sys_role.id RESTRICT/RESTRICT                                                                     | 角色                             |
| sys_role_assignment | fk_sys_role_assignment_requested            | requested_by -> sys_user.id RESTRICT/RESTRICT                                                                | 申请人                           |
| sys_role_assignment | fk_sys_role_assignment_reviewed             | reviewed_by -> sys_user.id RESTRICT/RESTRICT                                                                 | 审核人                           |
| sys_role_assignment | fk_sys_role_assignment_approved             | approved_by -> sys_user.id RESTRICT/RESTRICT                                                                 | 批准人                           |
| sys_role_assignment | fk_sys_role_assignment_executed             | executed_by -> sys_user.id RESTRICT/RESTRICT                                                                 | 执行人                           |
| sys_role_assignment | fk_sys_role_assignment_created              | created_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 创建人                           |
| sys_role_assignment | fk_sys_role_assignment_updated              | updated_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 更新人                           |
| sys_user_role       | PRIMARY（逻辑标签：pk_sys_user_role）       | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_user_role       | uk_sys_user_role                            | UNIQUE (user_id, role_id)                                                                                    | 当前角色关系唯一                 |
| sys_user_role       | uk_sys_user_role_source_assignment          | UNIQUE (source_assignment_id)                                                                                | 一个分配记录最多驱动一个当前关系 |
| sys_user_role       | ck_sys_user_role_status                     | status IN ('ACTIVE','REVOKED','EXPIRED')                                                                     | 关系状态                         |
| sys_user_role       | ck_sys_user_role_valid_period               | valid_to IS NULL OR valid_from <= valid_to                                                                   | 有效期                           |
| sys_user_role       | idx_sys_user_role_user_status               | INDEX (user_id, status, valid_to)                                                                            | 用户有效角色查询                 |
| sys_user_role       | idx_sys_user_role_role_status               | INDEX (role_id, status, valid_to)                                                                            | 角色成员查询                     |
| sys_user_role       | fk_sys_user_role_user                       | user_id -> sys_user.id RESTRICT/RESTRICT                                                                     | 用户                             |
| sys_user_role       | fk_sys_user_role_role                       | role_id -> sys_role.id RESTRICT/RESTRICT                                                                     | 角色                             |
| sys_user_role       | fk_sys_user_role_assignment                 | source_assignment_id -> sys_role_assignment.id RESTRICT/RESTRICT                                             | 来源申请                         |
| sys_user_role       | fk_sys_user_role_created_by                 | created_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 创建人                           |
| sys_user_role       | fk_sys_user_role_updated_by                 | updated_by -> sys_user.id RESTRICT/RESTRICT                                                                  | 更新人                           |
| sys_role_permission | PRIMARY（逻辑标签：pk_sys_role_permission） | PRIMARY KEY (id)                                                                                             | 主键                             |
| sys_role_permission | uk_sys_role_permission                      | UNIQUE (role_id, permission_id)                                                                              | 角色权限唯一                     |
| sys_role_permission | idx_sys_role_permission_permission          | INDEX (permission_id)                                                                                        | 反向查询                         |
| sys_role_permission | fk_sys_role_permission_role                 | role_id -> sys_role.id RESTRICT/RESTRICT                                                                     | 角色                             |
| sys_role_permission | fk_sys_role_permission_permission           | permission_id -> sys_permission.id RESTRICT/RESTRICT                                                         | 权限                             |

### 10.1 建表顺序

```text
1. sys_user
2. sys_role
3. sys_permission
4. sys_role_assignment
5. sys_user_role
6. sys_role_permission
```

`sys_user`中的`created_by`和`updated_by`是自引用外键。`sys_user_role.source_assignment_id`允许为空，用于后续启动账号或受控迁移场景；正常角色分配执行应写入来源记录。

### 10.2 sys_role_assignment状态与转换

状态集合：

```text
PENDING_REVIEW
PENDING_APPROVAL
PENDING_EXECUTION
REJECTED
EXECUTED
EXECUTION_FAILED
```

转换规则：

```text
提交角色分配申请
→ PENDING_REVIEW

审核拒绝
→ REJECTED

审核通过且approval_required = 1
→ PENDING_APPROVAL

审核通过且approval_required = 0
→ PENDING_EXECUTION

批准拒绝
→ REJECTED

批准通过
→ PENDING_EXECUTION

技术执行成功
→ EXECUTED

技术执行失败
→ EXECUTION_FAILED
```

业务语义规定只有`EXECUTED`状态的申请可以驱动`sys_user_role`写入或更新。

该条件依赖`sys_role_assignment.status`与另一张表的写入关系，不能由本Goal的单行CHECK完整强制。DB-BASE-01只保证：

- `source_assignment_id`存在时必须引用真实角色分配记录；
- 一个角色分配记录最多成为一个当前用户角色关系的来源；
- 用户和角色组合唯一。

“来源申请必须为`EXECUTED`”由`AUTH-BASE-01`的同一公开Service事务和数据库集成测试保证，不得在DB-BASE-01验收中表述为已由数据库阻断。

`sys_user_role`是当前角色关系投影，不是审批历史表。授权或撤销历史由`sys_role_assignment`保留；同一用户和角色后续重新授权时更新当前关系，而不是插入第二条相同组合。

### 10.3 数据库约束与Service守卫清单

#### 本Goal由数据库直接保证

- 主键、唯一约束、外键和必要索引；
- 状态、风险级别、执行模式和布尔标记的允许值；
- 有效期先后关系；
- 同一行中的审核人/时间、批准人/时间、执行人/时间成对；
- 申请、审核、批准、执行之间可由同一行判断的职责分离；
- 角色、权限、用户角色和角色权限关系的结构完整性。

#### 后续Goal必须由Service保证

- 角色风险级别与`approval_required`的一致性；
- 允许的状态转换路径；
- 审核人、批准人、执行人的实际角色和权限；
- 只有`EXECUTED`申请可以变更当前角色关系；
- GRANT与REVOKE如何更新`sys_user_role`；
- 多阶段权限在具体接口上的角色、阶段和状态守卫；
- 角色硬隔离组合和同一业务实例的自我审批阻断；
- 审计事件、失败证据和事务原子性。

DB-BASE-01不得使用数据库触发器冒充上述Service闭环。

## 11. 角色种子

| role_code            | 角色名称   | risk_level | 说明                                                   |
| -------------------- | ---------- | ---------- | ------------------------------------------------------ |
| SYSTEM_ADMIN         | 系统管理员 | HIGH       | 维护Demo用户、角色和技术配置；不自动获得业务高风险权限 |
| PURCHASER            | 采购员     | NORMAL     | 维护采购侧资料、首营申请和采购订单                     |
| RECEIVER             | 收货员     | NORMAL     | 登记到货并形成待验批次                                 |
| ACCEPTANCE_INSPECTOR | 验收员     | HIGH       | 逐批验收并提交质量结论                                 |
| QUALITY_MANAGER      | 质量管理员 | HIGH       | 质量审核、调查和处置建议                               |
| QUALITY_HEAD         | 质量负责人 | HIGH       | 首营和重大质量处置最终批准                             |
| WAREHOUSE_OPERATOR   | 仓库管理员 | NORMAL     | 入库、库存作业、备货、发运和签收                       |
| SALES_OPERATOR       | 销售员     | NORMAL     | 客户资料、销售订单和库存占用申请                       |
| OUTBOUND_REVIEWER    | 出库复核员 | HIGH       | 独立复核并触发出库                                     |
| AUDIT_VIEWER         | 审计查看员 | HIGH       | 只读审计、追溯和任务执行证据                           |

高风险角色必须与权限矩阵一致：

```text
SYSTEM_ADMIN
ACCEPTANCE_INSPECTOR
QUALITY_MANAGER
QUALITY_HEAD
OUTBOUND_REVIEWER
AUDIT_VIEWER
```

## 12. 权限种子规则

### 12.1 权限代码

```text
permission_code = ROLE_PERMISSION_MATRIX中的权限编号
```

权限总数：160，编号重复数：0。

### 12.2 模块数量

| module_code | 权限数量 |
| ----------- | -------- |
| SYS         | 16       |
| MD          | 11       |
| QA          | 16       |
| PO          | 9        |
| RC          | 9        |
| ACPT        | 10       |
| INV         | 12       |
| SO          | 14       |
| OUT         | 12       |
| TRACE       | 6        |
| QE          | 13       |
| GD          | 17       |
| DEMO        | 5        |
| BAK         | 10       |

### 12.3 execution_mode

| execution_mode  | 数量 | 是否生成角色关系         |
| --------------- | ---- | ------------------------ |
| ROLE            | 110  | 是，按附录明确角色生成   |
| ROLE_AND_SYSTEM | 17   | 是，同时允许系统事件执行 |
| SYSTEM          | 7    | 否                       |
| PROHIBITED      | 22   | 否                       |
| NOT_OPEN        | 4    | 否                       |

含义：

- `ROLE`：由一个或多个正式角色发起或执行；
- `ROLE_AND_SYSTEM`：既有明确角色参与，也有系统事件或适配器执行；
- `SYSTEM`：只有系统事件、调度或适配器执行；
- `PROHIBITED`：矩阵明确禁止，不产生角色关系；
- `NOT_OPEN`：当前Demo不开放，不产生角色关系。

## 13. 角色—权限关系规则

1. “全部已登录角色”展开为10个正式角色；
2. “全部业务角色”展开为8个业务角色，不含`SYSTEM_ADMIN`和`AUDIT_VIEWER`；
3. 允许角色文本中明确出现的正式角色全部生成关系；
4. 允许文本同时包含系统动作和正式角色时，`execution_mode=ROLE_AND_SYSTEM`，只为明确正式角色生成关系；
5. 只有系统动作、系统调度或Mock适配器且无正式角色时，`execution_mode=SYSTEM`，不生成关系；
6. “无”“原则禁止”使用`PROHIBITED`，不生成关系；
7. “当前Demo不开放”“首版不开放”使用`NOT_OPEN`，不生成关系；
8. “申请人”“本人业务”“授权人员”“外部签收人”等数据主体称谓不创建新角色；
9. 同一权限中分别承担触发、审核、批准或执行的正式角色均生成粗粒度关系；
10. 具体阶段、来源状态、数据范围、本人业务、脱敏和职责冲突由后续Service守卫处理；
11. “明确禁止角色”如果表达对整个权限动作的绝对禁止，不得生成角色关系；如果同一角色在允许角色栏中具有明确的发起、协作、审核、批准或执行职责，而禁止栏只限制特定阶段、状态、数据范围或操作方式，则保留粗粒度角色关系，由后续Service守卫阻断具体动作；
12. 附录出现的角色列表是本Goal唯一允许的角色—权限种子结果，不允许实施时重新猜测。

预期关系总数：233。

这233条关系表示角色对权限动作族的粗粒度参与资格，不表示所有关联角色拥有相同阶段能力。以下类型必须由后续Service进一步区分：

- 发起人与审核人共用一个权限编号；
- 审核人与批准人共用一个权限编号；
- 业务角色触发、系统执行；
- 技术执行人与业务审核角色共同参与；
- 只允许查看摘要、本人业务或脱敏数据。

未来Java实现不得把`sys_role_permission`查询结果等同于最终业务授权结论。

### 13.1 每个角色预期关联数

| role_code            | 预期关联数 |
| -------------------- | ---------- |
| SYSTEM_ADMIN         | 27         |
| PURCHASER            | 21         |
| RECEIVER             | 12         |
| ACCEPTANCE_INSPECTOR | 14         |
| QUALITY_MANAGER      | 53         |
| QUALITY_HEAD         | 29         |
| WAREHOUSE_OPERATOR   | 25         |
| SALES_OPERATOR       | 24         |
| OUTBOUND_REVIEWER    | 8          |
| AUDIT_VIEWER         | 20         |

### 13.2 特殊权限语义决议

以下决议用于消除权限矩阵自然语言与粗粒度RBAC种子之间的歧义。

#### 13.2.1 直接修改与受控更正

以下权限继续保持`PROHIBITED`，不生成任何角色关系：

```text
PO-007
RC-008
SO-012
```

这些权限编号表达的是对已进入受控阶段核心数据的**直接修改**。权限矩阵保留的“受控更正”不是对原动作的角色授权，而是后续通过独立的更正申请、审核、批准、技术执行和不可变审计链完成。

因此：

- 不得给采购员、收货员、销售员、质量管理员、质量负责人或系统管理员授予上述三个直接修改权限；
- 后续受控更正能力必须在独立Goal中定义专用状态、Service守卫和审计证据；
- 不得通过把上述权限改成`ROLE`来提前实现受控更正。

#### 13.2.2 QA-016申请人查看本人结果

`QA-016`的粗粒度角色关系增加：

```text
PURCHASER
SALES_OPERATOR
```

最终关系为：

```text
PURCHASER
QUALITY_MANAGER
QUALITY_HEAD
SALES_OPERATOR
AUDIT_VIEWER
```

后续Service必须按业务来源和数据范围限制：

- `PURCHASER`只能查看本人提交的首营企业和首营品种申请结果摘要；
- `SALES_OPERATOR`只能查看本人提交的客户资质申请结果摘要；
- 申请人不得借`QA-016`查看其他申请人的完整意见；
- `QUALITY_MANAGER`、`QUALITY_HEAD`、`AUDIT_VIEWER`按冻结权限矩阵和数据范围查看完整或审计所需内容；
- 字段脱敏和完整意见范围不能仅由`sys_role_permission`决定。

#### 13.2.3 阶段性禁止不等于动作族绝对禁止

`SO-009`和`OUT-010`保留现有粗粒度角色关系：

```text
SO-009
WAREHOUSE_OPERATOR
SALES_OPERATOR

OUT-010
QUALITY_MANAGER
QUALITY_HEAD
WAREHOUSE_OPERATOR
```

相关角色确实参与动作族，但只能执行其职责对应阶段：

- `SO-009`中，销售员只能提出释放，仓库管理员或系统执行实际释放；
- `OUT-010`中，质量管理员负责调查，质量负责人负责重大批准，仓库管理员只执行已批准措施；
- 被禁止的是越过阶段、状态或职责边界的具体操作，不是角色参与整个动作族的资格。

因此后续Service必须区分发起、审核、批准和执行，不能只凭一个`permission_code`完成放行。

## 14. 三个实施文件职责

### 14.1 001_create_system_permission_tables.sql

必须：

- 设置或验证会话时区为`+00:00`；
- 创建六张表；
- 按第9、10章使用精确字段；六张表主键统一写为`PRIMARY KEY (id)`，其物理名称由MySQL固定为`PRIMARY`；除主键外，其余唯一约束、CHECK、普通索引和外键使用第10章的精确名称；
- 每表显式指定InnoDB和utf8mb4_0900_ai_ci；
- 不创建Schema；
- 不创建范围外对象；
- 不插入种子数据。

### 14.2 002_seed_system_permission_data.sql

必须：

- 只插入10个角色、160个权限和233条关系；
- 使用显式INSERT数据；
- 不插入用户、用户角色或角色分配记录；
- 不插入密码；
- 角色和权限顺序固定；
- 任何重复或缺失应使脚本失败；
- 角色权限关系必须通过`role_code`和`permission_code`查找实际ID，不得硬编码自增ID；
- 每条角色权限关系写入`source_matrix_version = 'v1.1'`；
- 不使用`INSERT IGNORE`、`REPLACE`或`ON DUPLICATE KEY UPDATE`掩盖错误。

### 14.3 verify_db_base_01.sh

必须：

- 使用`set -euo pipefail`；
- 校验`DB_BASE_01_MYSQL_LOGIN_PATH`非空且只含安全字符；
- 校验`DB_BASE_01_CONFIRM_DROP`精确等于固定测试Schema名称；
- 固定并再次校验Schema名称；
- 检查MySQL版本、SQL Mode和会话时区；
- 精确创建测试Schema及字符集/排序规则；
- 执行001和002；
- 执行第15章全部断言；
- 使用专门的`expect_mysql_failure`辅助函数执行预期失败语句，校验命令失败且数据不变量保持；
- 负向测试支撑数据使用`__DB_BASE_01_TEST__`前缀，并按外键逆序显式清理；
- 不假设重复键、CHECK或外键失败会自动回滚同一事务中的其他成功语句；
- 成功时删除测试Schema；
- 失败时保留测试Schema并打印检查命令；
- 不输出密码或连接秘密。

## 15. 验证场景与断言

### 15.1 结构断言

1. Schema字符集为utf8mb4；
2. Schema排序规则为utf8mb4_0900_ai_ci；
3. 表数量精确为6；
4. 表名集合与本Goal完全一致；
5. 六表引擎全部为InnoDB；
6. 列定义、NULL、默认值与第9章一致；
7. 六张表主键列均为`id`，`SHOW INDEX`和`INFORMATION_SCHEMA.STATISTICS`中的主键名称均为`PRIMARY`；除主键外，唯一约束、CHECK、普通索引和外键名称与第10章一致；
8. 不存在`drug`或其余45张候选表；
9. 外键检查保持开启；
10. `SHOW CREATE TABLE`可见命名CHECK和唯一约束。

### 15.2 种子断言

1. `sys_user`为0行；
2. `sys_user_role`为0行；
3. `sys_role_assignment`为0行；
4. `sys_role`为10行且代码集合精确匹配；
5. 高风险角色集合精确匹配；
6. `sys_permission`为160行；
7. 权限编号全部唯一；
8. 模块数量与第12.2节一致；
9. execution_mode数量与第12.3节一致；
10. `sys_role_permission`为233行；
11. 每个角色关系数与第13.1节一致；
12. `SYSTEM`、`PROHIBITED`、`NOT_OPEN`权限没有角色关系；
13. 每个`ROLE`和`ROLE_AND_SYSTEM`权限至少有一条角色关系；
14. 所有角色关系均在附录A中存在。

### 15.3 负向数据库测试

验证脚本必须使用明确的`__DB_BASE_01_TEST__`前缀创建支撑数据。每个预期失败语句必须单独检查失败结果和数据不变量。

不得把“某条语句失败”解释为“整个显式事务已经自动回滚”。完成每组测试后，必须按外键逆序显式删除成功插入的支撑数据；验证成功前再次确认10/160/233基线数量未被测试数据污染：

| 场景                             | 预期         |
| -------------------------------- | ------------ |
| 重复username                     | 错误1062     |
| 非法sys_user.status              | CHECK拒绝    |
| 空白password_hash                | CHECK拒绝    |
| 重复role_code                    | 错误1062     |
| 非法risk_level                   | CHECK拒绝    |
| 重复permission_code              | 错误1062     |
| 非法execution_mode               | CHECK拒绝    |
| 不存在user_id写sys_user_role     | 外键错误1452 |
| 重复(user_id, role_id)           | 错误1062     |
| valid_from晚于valid_to           | CHECK拒绝    |
| 重复(role_id, permission_id)     | 错误1062     |
| assignment_type非法              | CHECK拒绝    |
| assignment status非法            | CHECK拒绝    |
| 审核人等于申请人                 | CHECK拒绝    |
| 批准人等于目标用户               | CHECK拒绝    |
| 审核人与批准人相同               | CHECK拒绝    |
| 批准人与执行人相同               | CHECK拒绝    |
| reviewed_by与reviewed_at只填一个 | CHECK拒绝    |
| approved_by与approved_at只填一个 | CHECK拒绝    |
| executed_by与executed_at只填一个 | CHECK拒绝    |

### 15.4 敏感数据断言

- `sys_user`不存在`password`、`plain_password`或类似明文列；
- 唯一密码字段是`password_hash`；
- 本Goal种子SQL不包含用户INSERT；
- 仓库差异中不出现真实密码、密钥或数据库登录秘密。

### 15.5 后端回归

实施后必须执行：

```bash
mvn -f backend/pom.xml -DskipTests compile
mvn -f backend/pom.xml test
```

预期现有测试至少保持：

```text
Tests run: 1
Failures: 0
Errors: 0
Skipped: 0
```

本Goal没有Java改动，Maven结果只能证明旧后端仍可编译和加载Spring上下文。

## 16. Git差异检查

必须执行：

```bash
git status --short
git diff --name-status
git diff --check
git diff --stat

git ls-files --others --exclude-standard | sort
```

三个实施文件在未暂存时属于未跟踪文件，普通`git diff`、`git diff --check`和`git diff --stat`不会检查其正文。因此还必须逐个执行：

```bash
check_new_file() {
  local file="$1"
  set +e
  git diff --no-index --check /dev/null "$file"
  local rc=$?
  set -e

  # 对非空新文件，无空白错误时git diff --no-index返回1；
  # 其他返回值视为检查失败。
  if [ "$rc" -ne 1 ]; then
    echo "new-file whitespace check failed: $file (rc=$rc)" >&2
    return 1
  fi
}

check_new_file sql/db-base-01/001_create_system_permission_tables.sql
check_new_file sql/db-base-01/002_seed_system_permission_data.sql
check_new_file scripts/verify_db_base_01.sh

wc -l   sql/db-base-01/001_create_system_permission_tables.sql   sql/db-base-01/002_seed_system_permission_data.sql   scripts/verify_db_base_01.sh
```

必须确认：

```text
?? sql/db-base-01/001_create_system_permission_tables.sql
?? sql/db-base-01/002_seed_system_permission_data.sql
?? scripts/verify_db_base_01.sh
```

且`git ls-files --others --exclude-standard`的集合精确等于上述三个文件。

普通`git diff --stat`在文件未跟踪时可能无输出，不能据此声称没有内容变化。

最终差异只能包含上述三个新增文件。不得修改：

```text
AGENTS.md
docs/
backend/
frontend/
sql/001_create_drug_table.sql
```

## 17. 停止条件

出现以下任一情况立即停止：

- 冻结文档与本文件存在直接冲突；
- MySQL 8.4不接受某个物理定义；
- 160个权限或233条关系无法按附录生成；
- 需要新增角色、权限、状态或表；
- 需要修改POM、application.yml、Java或Drug模块；
- 需要引入Flyway或其他依赖；
- 需要关闭外键检查才能成功；
- 需要依赖触发器才能表达本Goal未授权的跨表业务守卫；
- 需要连接非固定测试Schema；
- 测试结果与预期数量不一致；
- 发现密码、密钥或真实经营数据。

停止后只报告证据和所需人工决定，不通过放宽约束绕过问题。

## 18. 最低验收条件

全部满足后，Codex自检状态只能标记为`待验收`：

- 三个获准文件已生成；
- 空Schema执行成功；
- 六表结构和约束全部通过；
- 10个角色精确；
- 160个权限精确；
- 233条角色权限关系精确；
- 所有负向测试得到预期数据库拒绝，且支撑数据已显式清理；
- 不存在明文密码或用户种子；
- 不存在范围外表；
- Drug和旧SQL未修改；
- 后端编译和现有测试通过；
- 已对三个未跟踪新文件执行`git diff --no-index --check`并得到预期返回值；
- `git diff --check`无输出，但不把它当作未跟踪文件正文检查证据；
- 工作区未跟踪文件集合只有三个获准文件；
- 未commit、未push、未合并、未打标签。

只有人工审查SQL、种子、验证结果和Git差异后，Goal才能标记为`已完成`。

## 19. 最终回复格式

Codex最终回复必须列出：

1. 三个新增文件；
2. 六张表和建表顺序；
3. 字段、状态、约束、索引和外键；
4. 10个角色、160个权限和233条关系统计；
5. 正向和负向数据库测试；
6. Maven编译测试结果；
7. 数据库版本、Schema、字符集、排序规则和时区；
8. 未完成项和不能证明的内容；
9. 停止条件是否触发；
10. 最终Git状态；
11. 明确说明没有commit、push、合并或打标签。

## 附录A：160个权限与角色关系唯一清单

> 本附录是`002_seed_system_permission_data.sql`的唯一映射依据。实施时不得重新解释矩阵文本。

| permission_code | module_code | permission_name                        | execution_mode  | role_codes                                                                                                                                                  | 矩阵允许角色原文                                                                         |
| --------------- | ----------- | -------------------------------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| SYS-001         | SYS         | 查看本人账号与角色                     | ROLE            | SYSTEM_ADMIN, PURCHASER, RECEIVER, ACCEPTANCE_INSPECTOR, QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR, OUTBOUND_REVIEWER, AUDIT_VIEWER | 全部已登录角色                                                                           |
| SYS-002         | SYS         | 创建演示用户                           | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| SYS-003         | SYS         | 启用、停用用户                         | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| SYS-004         | SYS         | 重置用户密码                           | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| SYS-005         | SYS         | 提交角色分配申请                       | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| SYS-006         | SYS         | 审核业务角色权限                       | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| SYS-007         | SYS         | 批准高风险角色分配                     | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| SYS-008         | SYS         | 技术执行角色分配                       | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| SYS-009         | SYS         | 查看权限目录                           | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, QUALITY_HEAD, AUDIT_VIEWER                                                                                                   | 系统管理员、质量管理员、质量负责人、审计查看员                                           |
| SYS-010         | SYS         | 修改权限目录                           | NOT_OPEN        | —                                                                                                                                                          | 当前 Demo 不开放在线修改                                                                 |
| SYS-011         | SYS         | 查看审计日志                           | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, QUALITY_HEAD, AUDIT_VIEWER                                                                                                   | 质量管理员、质量负责人、审计查看员；系统管理员仅看技术日志                               |
| SYS-012         | SYS         | 修改或删除审计日志                     | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| SYS-013         | SYS         | 切换NATIONAL_DEFAULT / GD_DEMO_PROFILE | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER                                                                                                                               | 系统管理员执行，质量管理员审核                                                           |
| SYS-014         | SYS         | 修改关键质量控制配置                   | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, QUALITY_HEAD                                                                                                                 | 系统管理员技术执行，质量管理员审核，重大变更质量负责人批准                               |
| SYS-015         | SYS         | 查看系统健康和版本                     | ROLE            | SYSTEM_ADMIN, AUDIT_VIEWER                                                                                                                                  | 系统管理员、审计查看员                                                                   |
| SYS-016         | SYS         | 查看本人操作日志                       | ROLE            | PURCHASER, RECEIVER, ACCEPTANCE_INSPECTOR, QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR, OUTBOUND_REVIEWER                             | 全部业务角色                                                                             |
| MD-001          | MD          | 创建药品档案草稿                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| MD-002          | MD          | 编辑药品档案草稿或待完善资料           | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| MD-003          | MD          | 完成药品档案资料检查                   | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| MD-004          | MD          | 启用或停用药品档案                     | ROLE            | QUALITY_MANAGER, QUALITY_HEAD                                                                                                                               | 质量管理员；重大争议由质量负责人裁决                                                     |
| MD-005          | MD          | 创建供应商资料草稿                     | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| MD-006          | MD          | 编辑供应商未审核资料                   | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| MD-007          | MD          | 查看供应商完整资质                     | ROLE            | PURCHASER, QUALITY_MANAGER, QUALITY_HEAD, AUDIT_VIEWER                                                                                                      | 采购员、质量管理员、质量负责人、审计查看员                                               |
| MD-008          | MD          | 创建客户资料草稿                       | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| MD-009          | MD          | 编辑客户未审核资料                     | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| MD-010          | MD          | 查看客户资质                           | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, SALES_OPERATOR, AUDIT_VIEWER                                                                                                 | 销售员、质量管理员、质量负责人、审计查看员                                               |
| MD-011          | MD          | 删除已提交或已使用的基础档案           | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| QA-001          | QA          | 创建首营企业申请                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| QA-002          | QA          | 提交首营企业审核                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| QA-003          | QA          | 撤回本人未处理申请                     | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| QA-004          | QA          | 审核首营企业                           | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QA-005          | QA          | 批准或驳回首营企业                     | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QA-006          | QA          | 标记首营企业失效                       | ROLE_AND_SYSTEM | QUALITY_MANAGER                                                                                                                                             | 系统按有效期自动；质量管理员人工确认                                                     |
| QA-007          | QA          | 创建首营品种申请                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| QA-008          | QA          | 审核首营品种                           | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QA-009          | QA          | 批准或驳回首营品种                     | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QA-010          | QA          | 失效或触发重新审核首营品种             | ROLE_AND_SYSTEM | QUALITY_MANAGER                                                                                                                                             | 质量管理员；系统按关联状态触发                                                           |
| QA-011          | QA          | 提交客户资质审核                       | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| QA-012          | QA          | 审核客户合法性、范围和人员资格         | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QA-013          | QA          | 冻结客户                               | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QA-014          | QA          | 解除客户冻结                           | ROLE            | QUALITY_MANAGER, QUALITY_HEAD                                                                                                                               | 质量管理员；重大争议由质量负责人裁决                                                     |
| QA-015          | QA          | 系统执行资质到期失效                   | ROLE_AND_SYSTEM | QUALITY_MANAGER                                                                                                                                             | 系统动作；质量管理员确认异常                                                             |
| QA-016          | QA          | 查看质量审批完整意见                   | ROLE            | PURCHASER, QUALITY_MANAGER, QUALITY_HEAD, SALES_OPERATOR, AUDIT_VIEWER                                                                                      | 质量管理员、质量负责人、审计查看员；申请人可看与本人申请相关结果                         |
| PO-001          | PO          | 创建采购订单草稿                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| PO-002          | PO          | 编辑采购订单草稿                       | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| PO-003          | PO          | 确认采购订单                           | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| PO-004          | PO          | 关闭未确认草稿                         | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| PO-005          | PO          | 受控关闭已确认未收货订单               | ROLE            | PURCHASER                                                                                                                                                   | 采购员                                                                                   |
| PO-006          | PO          | 终止部分收货后的未收数量               | ROLE            | PURCHASER, QUALITY_MANAGER                                                                                                                                  | 采购员；质量异常时质量管理员参与                                                         |
| PO-007          | PO          | 修改已确认订单核心数据                 | PROHIBITED      | —                                                                                                                                                          | 原则禁止；如更正需受控更正流程                                                           |
| PO-008          | PO          | 查看采购订单                           | ROLE            | PURCHASER, RECEIVER, ACCEPTANCE_INSPECTOR, QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, AUDIT_VIEWER                                                  | 采购员、收货员、验收员、质量管理员、质量负责人、审计查看员；仓库管理员按后续业务查看摘要 |
| PO-009          | PO          | 删除采购订单                           | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| RC-001          | RC          | 创建收货记录                           | ROLE            | RECEIVER                                                                                                                                                    | 收货员                                                                                   |
| RC-002          | RC          | 开始收货                               | ROLE            | RECEIVER                                                                                                                                                    | 收货员                                                                                   |
| RC-003          | RC          | 登记到货、包装、运输和随货异常         | ROLE            | RECEIVER                                                                                                                                                    | 收货员                                                                                   |
| RC-004          | RC          | 处理一般收货差异                       | ROLE            | RECEIVER, QUALITY_MANAGER                                                                                                                                   | 收货员；涉及质量风险时质量管理员介入                                                     |
| RC-005          | RC          | 完成收货                               | ROLE            | RECEIVER                                                                                                                                                    | 收货员                                                                                   |
| RC-006          | RC          | 生成待验批次                           | ROLE_AND_SYSTEM | RECEIVER                                                                                                                                                    | 收货员触发，系统生成                                                                     |
| RC-007          | RC          | 取消未进入验收的收货记录               | ROLE            | PURCHASER, RECEIVER                                                                                                                                         | 收货员，必要时采购员确认                                                                 |
| RC-008          | RC          | 修改已进入验收的收货记录               | PROHIBITED      | —                                                                                                                                                          | 原则禁止；更正需质量管理员审核                                                           |
| RC-009          | RC          | 作出质量合格或不合格结论               | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员，不属于收货权限                                                                   |
| ACPT-001        | ACPT        | 查看待验批次和相关资料                 | ROLE            | ACCEPTANCE_INSPECTOR, QUALITY_MANAGER, QUALITY_HEAD, AUDIT_VIEWER                                                                                           | 验收员、质量管理员、质量负责人、审计查看员                                               |
| ACPT-002        | ACPT        | 开始逐批验收                           | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-003        | ACPT        | 录入验收检查项和数量                   | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-004        | ACPT        | 提交质量介入                           | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-005        | ACPT        | 给出质量处理意见并退回验收             | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| ACPT-006        | ACPT        | 提交合格结论                           | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-007        | ACPT        | 提交部分合格结论                       | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-008        | ACPT        | 提交不合格结论                         | ROLE            | ACCEPTANCE_INSPECTOR                                                                                                                                        | 验收员                                                                                   |
| ACPT-009        | ACPT        | 修改已完成验收结论                     | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, QUALITY_HEAD                                                                                                                 | 质量管理员审核，质量负责人批准重大更正，系统管理员仅技术执行不得改业务                   |
| ACPT-010        | ACPT        | 删除验收记录                           | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| INV-001         | INV         | 查看批号库存、质量结论和冻结摘要       | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR, OUTBOUND_REVIEWER, AUDIT_VIEWER                                                          | 仓库管理员、质量管理员、质量负责人、出库复核员、审计查看员；销售员仅查看可售摘要         |
| INV-002         | INV         | 指定或确认入库库位                     | ROLE            | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员                                                                               |
| INV-003         | INV         | 根据合格验收确认入库                   | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员触发，系统在事务中生成库存和流水                                               |
| INV-004         | INV         | 自动生成入库库存流水                   | SYSTEM          | —                                                                                                                                                          | 系统动作                                                                                 |
| INV-005         | INV         | 直接修改库存总数                       | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| INV-006         | INV         | 发起人工库存数量调整                   | NOT_OPEN        | —                                                                                                                                                          | 无，首版不开放                                                                           |
| INV-007         | INV         | 审核人工库存数量调整                   | NOT_OPEN        | —                                                                                                                                                          | 无，首版不开放                                                                           |
| INV-008         | INV         | 批准人工库存数量调整                   | NOT_OPEN        | —                                                                                                                                                          | 无，首版不开放                                                                           |
| INV-009         | INV         | 查看库存流水和质量历史                 | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR, AUDIT_VIEWER                                                                             | 仓库管理员、质量管理员、质量负责人、审计查看员；销售员仅查看可售摘要                     |
| INV-010         | INV         | 修改或删除库存流水                     | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| INV-011         | INV         | 系统识别过期并阻断                     | SYSTEM          | —                                                                                                                                                          | 系统动作                                                                                 |
| INV-012         | INV         | 恢复不合格或过期为合格                 | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| SO-001          | SO          | 创建销售订单草稿                       | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| SO-002          | SO          | 编辑销售订单草稿                       | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| SO-003          | SO          | 提交客户校验                           | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| SO-004          | SO          | 自动执行客户和范围校验                 | ROLE_AND_SYSTEM | QUALITY_MANAGER                                                                                                                                             | 系统动作；质量管理员维护校验依据                                                         |
| SO-005          | SO          | 处理客户校验例外                       | ROLE            | QUALITY_MANAGER, QUALITY_HEAD                                                                                                                               | 质量管理员；重大争议由质量负责人裁决                                                     |
| SO-006          | SO          | 进入批次分配                           | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| SO-007          | SO          | 选择候选批次                           | ROLE            | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 销售员或仓库管理员                                                                       |
| SO-008          | SO          | 创建库存占用                           | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 系统动作，由销售员或仓库管理员触发                                                       |
| SO-009          | SO          | 释放占用                               | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 仓库管理员触发或系统动作；销售员可提出                                                   |
| SO-010          | SO          | 关闭草稿或已确认订单                   | ROLE            | SALES_OPERATOR                                                                                                                                              | 销售员                                                                                   |
| SO-011          | SO          | 关闭已分配批次订单                     | ROLE            | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 销售员执行，仓库管理员先释放全部占用                                                     |
| SO-012          | SO          | 修改已进入出库复核的核心数据           | PROHIBITED      | —                                                                                                                                                          | 原则禁止；退回复核后由销售员在允许状态受控修改                                           |
| SO-013          | SO          | 质量冻结阻断已有占用                   | SYSTEM          | —                                                                                                                                                          | 系统动作，由 SM-14 冻结事务触发                                                          |
| SO-014          | SO          | 质量阻断后退回重新分配                 | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 系统动作；销售员或仓库管理员后续重新选择批次                                             |
| OUT-001         | OUT         | 备货并提交复核                         | ROLE            | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员                                                                               |
| OUT-002         | OUT         | 开始出库复核                           | ROLE            | OUTBOUND_REVIEWER                                                                                                                                           | 出库复核员                                                                               |
| OUT-003         | OUT         | 提交复核不通过                         | ROLE            | OUTBOUND_REVIEWER                                                                                                                                           | 出库复核员                                                                               |
| OUT-004         | OUT         | 提交复核通过                           | ROLE            | OUTBOUND_REVIEWER                                                                                                                                           | 出库复核员                                                                               |
| OUT-005         | OUT         | 执行实际出库和库存扣减                 | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR                                                                                                                                          | 系统动作，仓库管理员触发                                                                 |
| OUT-006         | OUT         | 复核失败后纠正并重新提交               | ROLE            | WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                                                          | 仓库管理员；需改订单时由销售员处理                                                       |
| OUT-007         | OUT         | 创建发运记录                           | ROLE            | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员                                                                               |
| OUT-008         | OUT         | 登记签收或到货确认                     | ROLE            | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员；外部签收人为记录对象                                                         |
| OUT-009         | OUT         | 登记运输异常                           | ROLE            | QUALITY_MANAGER, WAREHOUSE_OPERATOR                                                                                                                         | 仓库管理员、质量管理员                                                                   |
| OUT-010         | OUT         | 调查并处理运输质量异常                 | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR                                                                                                           | 质量管理员调查；仓库管理员执行已批准措施；重大处置由质量负责人批准                       |
| OUT-011         | OUT         | 受控更正已出库、发运或签收记录         | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                             | 销售员或仓库管理员提出；质量管理员审核；重大更正由质量负责人批准；系统管理员仅技术执行   |
| OUT-012         | OUT         | 删除出库、复核、发运或签收记录         | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| TRACE-001       | TRACE       | 查询批号全过程追溯                     | ROLE            | PURCHASER, QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, SALES_OPERATOR, AUDIT_VIEWER                                                                  | 质量管理员、质量负责人、仓库管理员、审计查看员；采购员和销售员仅查本人业务相关摘要       |
| TRACE-002       | TRACE       | 查看质量事件和冻结处置                 | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, WAREHOUSE_OPERATOR, AUDIT_VIEWER                                                                                             | 质量管理员、质量负责人、审计查看员；仓库管理员看执行所需摘要                             |
| TRACE-003       | TRACE       | 查看客户去向                           | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, SALES_OPERATOR, AUDIT_VIEWER                                                                                                 | 质量管理员、质量负责人、销售员看本人客户、审计查看员                                     |
| TRACE-004       | TRACE       | 导出完整追溯证据                       | ROLE            | QUALITY_MANAGER, QUALITY_HEAD, AUDIT_VIEWER                                                                                                                 | 质量负责人、审计查看员；质量管理员按授权                                                 |
| TRACE-005       | TRACE       | 修改追溯查询结果                       | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| TRACE-006       | TRACE       | 标记链路不完整并发起调查               | ROLE            | QUALITY_MANAGER, AUDIT_VIEWER                                                                                                                               | 质量管理员、审计查看员可提交问题，质量管理员处理                                         |
| QE-001          | QE          | 创建正式质量事件                       | ROLE            | ACCEPTANCE_INSPECTOR, QUALITY_MANAGER, WAREHOUSE_OPERATOR, SALES_OPERATOR                                                                                   | 质量管理员；验收员、仓库管理员、销售员可提交风险线索                                     |
| QE-002          | QE          | 紧急冻结受影响库存                     | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-003          | QE          | 扩大或缩小影响范围                     | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-004          | QE          | 开始或继续调查质量事件                 | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-005          | QE          | 提交解除冻结处置建议                   | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-006          | QE          | 提交转不合格处置建议                   | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-007          | QE          | 批准解除冻结                           | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QE-008          | QE          | 批准转不合格                           | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QE-009          | QE          | 退回质量调查                           | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QE-010          | QE          | 执行批准后的处置                       | ROLE_AND_SYSTEM | WAREHOUSE_OPERATOR                                                                                                                                          | 仓库管理员执行必要仓储动作，系统生成流水                                                 |
| QE-011          | QE          | 关闭质量事件                           | ROLE            | QUALITY_HEAD                                                                                                                                                | 质量负责人                                                                               |
| QE-012          | QE          | 取消误建质量事件                       | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| QE-013          | QE          | 删除质量事件、动作或冻结历史           | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| GD-001          | GD          | 创建入库码核验事件并扫描或录入         | ROLE            | RECEIVER, ACCEPTANCE_INSPECTOR                                                                                                                              | 收货员、验收员                                                                           |
| GD-002          | GD          | 创建出库码核验事件并扫描               | ROLE            | WAREHOUSE_OPERATOR, OUTBOUND_REVIEWER                                                                                                                       | 出库复核员；仓库管理员可辅助扫描但由复核员确认                                           |
| GD-003          | GD          | 自动执行重复码和一致性核验             | SYSTEM          | —                                                                                                                                                          | 系统动作                                                                                 |
| GD-004          | GD          | 纠正来源数据并重新提交核验             | ROLE            | RECEIVER, ACCEPTANCE_INSPECTOR, OUTBOUND_REVIEWER                                                                                                           | 收货员、验收员、出库复核员按原业务环节                                                   |
| GD-005          | GD          | 作废未有效使用的演示追溯码             | ROLE            | QUALITY_MANAGER                                                                                                                                             | 质量管理员                                                                               |
| GD-006          | GD          | 直接将核验失败改为核验通过             | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| GD-007          | GD          | 重新使用已作废追溯码                   | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| GD-008          | GD          | 生成 Mock 交换任务                     | SYSTEM          | —                                                                                                                                                          | 系统动作，由有效入库或出库事件触发                                                       |
| GD-009          | GD          | 执行 Mock 上传                         | ROLE_AND_SYSTEM | SYSTEM_ADMIN                                                                                                                                                | Mock 适配器/系统动作；系统管理员可触发                                                   |
| GD-010          | GD          | 保存 Mock 成功回执                     | SYSTEM          | —                                                                                                                                                          | Mock 适配器/系统动作                                                                     |
| GD-011          | GD          | 保存 Mock 失败或超时                   | SYSTEM          | —                                                                                                                                                          | Mock 适配器/系统动作                                                                     |
| GD-012          | GD          | 标记失败任务待重试                     | ROLE_AND_SYSTEM | SYSTEM_ADMIN, QUALITY_MANAGER                                                                                                                               | 系统动作或系统管理员执行；质量管理员审核业务影响                                         |
| GD-013          | GD          | 执行重试                               | ROLE_AND_SYSTEM | SYSTEM_ADMIN                                                                                                                                                | 系统管理员触发 Mock 适配器或系统调度                                                     |
| GD-014          | GD          | 终止 Mock 交换任务                     | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER                                                                                                                               | 系统管理员执行，质量管理员审核                                                           |
| GD-015          | GD          | 将 Mock 失败人工改为成功               | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| GD-016          | GD          | 将 Mock 成功描述为真实监管成功         | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| GD-017          | GD          | 已终止任务继续上传或重试               | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| DEMO-001        | DEMO        | 查看演示数据任务                       | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, AUDIT_VIEWER                                                                                                                 | 系统管理员、审计查看员、质量管理员查看结果                                               |
| DEMO-002        | DEMO        | 执行演示数据初始化                     | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| DEMO-003        | DEMO        | 执行演示数据重置                       | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员；建议二次确认                                                                 |
| DEMO-004        | DEMO        | 在非 Demo 环境执行重置                 | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| DEMO-005        | DEMO        | 手工改库伪造初始化成功                 | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| BAK-001         | BAK         | 查看备份计划和执行记录                 | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, AUDIT_VIEWER                                                                                                                 | 系统管理员、审计查看员；质量管理员查看结果                                               |
| BAK-002         | BAK         | 创建或修改 Demo 备份计划               | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER                                                                                                                               | 系统管理员，质量管理员审核数据保留相关设置                                               |
| BAK-003         | BAK         | 执行备份                               | ROLE_AND_SYSTEM | SYSTEM_ADMIN                                                                                                                                                | 系统管理员或系统动作（任务调度）                                                         |
| BAK-004         | BAK         | 创建恢复验证任务                       | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| BAK-005         | BAK         | 执行隔离恢复                           | ROLE            | SYSTEM_ADMIN                                                                                                                                                | 系统管理员                                                                               |
| BAK-006         | BAK         | 核对恢复后的关键业务链                 | ROLE            | SYSTEM_ADMIN, QUALITY_MANAGER, AUDIT_VIEWER                                                                                                                 | 系统管理员执行技术核对；质量管理员或审计查看员复核证据                                   |
| BAK-007         | BAK         | 标记验证成功                           | ROLE_AND_SYSTEM | QUALITY_MANAGER, AUDIT_VIEWER                                                                                                                               | 系统根据全部核对项；质量管理员或审计查看员确认报告                                       |
| BAK-008         | BAK         | 记录恢复失败                           | ROLE_AND_SYSTEM | SYSTEM_ADMIN                                                                                                                                                | 系统动作；系统管理员补充技术原因                                                         |
| BAK-009         | BAK         | 删除备份失败或恢复失败记录             | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |
| BAK-010         | BAK         | 备份失败后直接进入恢复验证             | PROHIBITED      | —                                                                                                                                                          | 无                                                                                       |

---

## 20. 规格审查结论

本文件已完成以下审查：

- 160个权限编号唯一且模块数量合计为160；
- execution_mode数量为110 / 17 / 7 / 22 / 4；
- `PO-007`、`RC-008`、`SO-012`已明确为直接修改禁令，继续保持`PROHIBITED`；
- `QA-016`已补充采购员和销售员的本人申请结果粗粒度关系；
- 阶段性禁止与动作族绝对禁止的映射规则已分离；
- 角色—权限关系总数为233；
- 10个角色的关系数合计为233；
- 除主键外的显式约束和索引名称均未超过MySQL标识符长度限制；
- 六张表主键物理名称已按MySQL 8.4固定为`PRIMARY`，`pk_*`仅保留为文档逻辑标签；
- 六表建表依赖顺序闭合；
- 粗粒度RBAC与后续Service业务守卫边界已明确；
- 跨表状态不变量未被错误表述为CHECK已保证；
- 验证脚本的DROP DATABASE、login-path、失败清理和未跟踪文件检查边界已明确。

审查结论：

```text
角色—权限映射语义阻塞已按第13.2节人工决议关闭。
本文件可作为DB-BASE-01的执行规格提交，并进入最终只读复核。
提交本文件不等于授权Codex立即执行DDL；
下一轮仍应先让Codex只读复核本规格与当前仓库状态。
```

---

**文档结束**
