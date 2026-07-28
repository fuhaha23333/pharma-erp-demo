
# 药品批发 ERP Demo 数据库设计（DATABASE_DESIGN_DEMO）

> **核心定位：** 本文档将已冻结的范围、业务流程、状态机和角色权限转换为可落地、可审查、可测试的关系型数据模型，并作为后续 SQL 基线、Java 实体、事务实现和数据库验收的上位设计依据。

| 文档属性       | 内容                                                                             |
| -------------- | -------------------------------------------------------------------------------- |
| 文档版本 | v1.0 |
| 文档状态 | 冻结基线 |
| 适用项目       | `pharma-erp-demo`                                                              |
| 适用分支       | `feat/database-redesign`                                                       |
| 上位范围文件   | `docs/DEMO_SCOPE.md` v1.1                                                      |
| 上位业务流程   | `docs/BUSINESS_FLOW.md` v1.0                                                   |
| 上位状态机     | `docs/BUSINESS_STATE_MACHINE.md` v1.1                                    |
| 上位权限矩阵   | `docs/ROLE_PERMISSION_MATRIX.md` v1.1                                    |
| 当前数据库决策 | 放弃现有单表原型作为正式基线；先冻结完整模型，再生成新 SQL 基线                  |
| 本文档职责     | 冻结数据域、表职责、核心字段、关系、状态、约束、事务、并发、索引、审计和重建规则 |
| 本文档不负责   | API地址、Java类名、ORM注解、前端页面、完整DDL、真实监管接口、生产部署拓扑        |

> **优先级声明：** 如本文档与已冻结的范围、流程文件或已冻结的状态机、权限矩阵冲突，以上位文件为准。不得通过数据库设计扩大范围、改变状态机或放宽权限。

---

## 0. v1.1 状态机与权限矩阵同步摘要

本版数据库设计以以下当前草案为直接上位依据：

- `BUSINESS_STATE_MACHINE.md` v1.1；
- `ROLE_PERMISSION_MATRIX.md` v1.1。

相对上一版预冻结草案，本次同步内容：

1. SM-06 改为草稿、收货中、待处理、已收货、待验和已取消；
2. SM-07 明确待质量处理和部分合格；
3. SM-08 只表达待验、合格、不合格和过期，不再包含冻结；
4. SM-09 明确质量阻断占用；
5. SM-10 明确质量阻断后退回待分配批次；
6. SM-11 明确复核中、复核不通过和重新提交；
7. SM-12 增加异常处理中；
8. SM-13 增加处置已批准、处置执行中和误建取消；
9. SM-14 独立表达冻结、解除审批、转不合格审批和审批退回；
10. SM-15 将“未采集”映射为业务对象尚无有效码记录，并只保存本地核验；
11. SM-16 将“未生成”映射为 Mock 任务尚不存在，任务创建后从待上传开始；
12. SM-18 明确备份中、备份失败、核对中和恢复失败；
13. 状态映射表增加权限动作编号，便于三文档自动交叉检查；
14. 数据库验收场景由 42 项增加到 50 项。

本次同步不增加数据域和数据表，完整目标模型仍为 **51 张候选表：M1 36 张、M2 10 张、M3 5 张**。

---

## 1. 文档目的与边界

本文档回答每个业务事实由哪张表保存、上下游如何追溯、状态保存在哪里、哪些记录允许修改、哪些业务必须同一事务完成、库存如何防止超卖，以及新数据库如何从空库重复建立。

### 1.1 范围

仅覆盖单法人、单经营主体、单自营仓、普通药品批发、全国核心流程、广东Profile与Mock，以及审计、演示数据、备份和恢复验证。

明确不设计：多租户、多法人、多仓协同、冷链、特殊药品、疫苗、财务总账、WMS/WCS/TMS、完整退货召回销毁CAPA、通用工作流、EAV、微服务拆库和真实监管接口。

---

## 2. 重建设计决策与本轮审查结论

```text
保留 Git 历史和 pre-database-redesign 标签
→ 从零冻结完整数据模型
→ 生成新的 SQL 基线
→ 重建本地 Demo 数据库
→ 原地重构现有 Drug 模块
```

不采用旧 `drug` 表持续打补丁，也不先删除全部代码后再猜数据模型。

### 2.1 法规映射与工程控制

法规映射控制包括全过程质量管理、授权操作、真实完整记录、可追溯、按日备份和记录保存。

工程控制包括外键、业务快照、状态历史、库存流水、锁定读取、死锁重试、Mock 失败不可覆盖和恢复核对。工程控制用于实现和验证监管目标，不表示法规逐字规定了相同表名、状态代码或事务实现。

### 2.2 对上一版草案的审查结论

上一版总体方向正确，但存在以下需要修正的问题：

1. **状态映射不够严格。** 数据库代码增加了若干细分状态，却没有逐项说明它们与冻结状态机中文语义的对应关系。
2. **经营范围校验缺少药品侧分类字段。** 已有供应商和客户范围表，但 `drug` 没有可用于匹配的经营分类代码。
3. **合格入库幂等规则不完整。** 只写“防止重复消费”，没有定义数据库可唯一识别的来源事件。
4. **库存冻结唯一性不完整。** 未定义同一库存余额只能存在一个活动冻结的数据库约束策略。
5. **受控更正没有独立记录。** 权限矩阵要求已完成验收、已出库记录等受控更正，上一版只有审计表，缺少申请、审核、批准和执行链。
6. **Profile 配置过度拆表。** 两个固定 Profile 不需要一张目录表加一张当前值表。
7. **简化签收被过度拆表。** 首版每个发运只有一个当前签收结果，可合并到 `shipment`，通过状态历史和审计保留更正过程。
8. **固定“52 张表”容易误导。** 表数量不是目标，完整业务不变量才是目标。

### 2.3 本版关键修订

- 候选表由 52 张调整为 **51 张：M1 36 张、M2 10 张、M3 5 张**；
- 合并 `province_profile` 与 `system_runtime_profile` 为 `system_runtime_config`；
- 合并 `delivery_receipt` 到 `shipment`；
- 新增 `business_correction`，承载受控更正链；
- `drug` 新增 `business_category_code`；
- `inventory_ledger` 新增全局唯一 `source_event_key`；
- `inventory_lock` 新增可空 `active_marker` 唯一策略；
- 状态映射表增加“上位状态语义”和“数据库细分说明”；
- 明确首版一个 `acceptance_item` 的合格数量只能一次性入一个库位，不支持拆分入库；
- 明确人工库存调整尚未进入冻结业务流程，因此本版不设计 `inventory_adjustment` 表。

---

## 3. 运行环境与兼容目标

### 3.1 已验证环境基线

以下结果已于 **2026-07-28** 在本地实际运行的 MySQL Server 上验证：

| 项目             | 已验证基线                                                                                                                | 验证结论                                |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| 数据库           | MySQL 8.4.10 LTS                                                                                                          | 通过                                    |
| 引擎             | InnoDB                                                                                                                    | 默认引擎已验证；所有核心表仍须显式指定  |
| 字符集           | `utf8mb4`                                                                                                               | 通过                                    |
| 排序规则         | `utf8mb4_0900_ai_ci`                                                                                                    | 通过                                    |
| SQL Mode         | `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION` | 通过                                    |
| 全局事务隔离     | `REPEATABLE-READ`                                                                                                       | 通过；库存事务继续使用显式锁            |
| 会话事务隔离     | `REPEATABLE-READ`                                                                                                       | 通过                                    |
| 操作系统时区标识 | `CST`                                                                                                                   | 仅记录环境事实，不作为业务时间基线      |
| MySQL 全局时区   | `+00:00`                                                                                                                | 已通过`SET PERSIST` 持久化            |
| MySQL 会话时区   | `+00:00`                                                                                                                | 新连接验证通过                          |
| 应用显示时区     | `Asia/Shanghai`                                                                                                         | 应用展示转换                            |
| 业务时刻         | `DATETIME(3)`，应用显式写入 UTC                                                                                         | `NOW(3)` 与 `UTC_TIMESTAMP(3)` 一致 |
| 业务日期         | `DATE`                                                                                                                  | 生产日期、有效期等                      |
| 主键             | `BIGINT` 自增                                                                                                           | 与 Java`Long` 对应                    |
| 数量             | `DECIMAL(18,4)`                                                                                                         | 精确基本单位数量                        |
| 单价             | `DECIMAL(18,6)`                                                                                                         | 仅演示订单字段                          |
| 金额             | `DECIMAL(18,2)`                                                                                                         | 不形成财务账                            |

环境查询：

```sql
SELECT
    VERSION(),
    @@GLOBAL.sql_mode,
    @@SESSION.sql_mode,
    @@GLOBAL.transaction_isolation,
    @@SESSION.transaction_isolation,
    @@system_time_zone,
    @@GLOBAL.time_zone,
    @@SESSION.time_zone,
    @@character_set_server,
    @@collation_server,
    @@default_storage_engine,
    NOW(3),
    UTC_TIMESTAMP(3);
```

### 3.2 已验证约束能力

在 MySQL 8.4.10 + InnoDB 上已完成单连接约束验证：

1. 同一 `owner_id` 可以插入多条 `current_marker IS NULL` 的历史记录；
2. 同一 `owner_id` 只能插入一条 `current_marker = 1` 的当前记录；
3. 第二条当前记录触发唯一约束错误 `1062`；
4. 负数数量触发 `CHECK` 约束错误 `3819`；
5. `current_marker = 2` 触发 `CHECK` 约束错误 `3819`；
6. `SHOW CREATE TABLE` 确认唯一约束和命名 `CHECK` 均已实际创建并强制执行。

因此本文档可以正式采用：

```text
current_marker = 1      当前版本
current_marker = NULL   历史版本

active_marker = 1       当前活动冻结
active_marker = NULL    历史冻结记录
```

并配合：

```text
UNIQUE (owner_key..., current_marker)
UNIQUE (inventory_balance_id, active_marker)
CHECK (current_marker IS NULL OR current_marker = 1)
CHECK (active_marker IS NULL OR active_marker = 1)
```

### 3.3 已验证并发唯一性

已于 **2026-07-28** 使用两个独立 MySQL 连接验证 nullable unique marker 的并发行为：

1. 连接 A 开启事务并插入 `(owner_id = 1, current_marker = 1)`，事务暂不提交；
2. 连接 B 在 A 事务未结束时尝试插入相同唯一键；
3. A 提交后，B 收到唯一约束错误 `1062 Duplicate entry '1-1'`；
4. 最终查询确认 `(owner_id = 1, current_marker = 1)` 只有一行；
5. 测试数据库已删除。

验证结论：

```text
nullable unique marker 双连接并发唯一性：通过
最终当前记录数量：1
第二个竞争事务：被唯一索引拒绝
```

该结果证明数据库能够阻止两个事务同时形成两条当前记录。

应用实现仍必须遵守：

- 捕获错误 `1062`；
- 将其转换为明确的业务冲突；
- 显式回滚整个业务事务；
- 不在捕获异常后继续执行后续审批、库存或审计写入；
- 不把唯一冲突当作可静默忽略的成功。

重复键错误默认只回滚失败的 SQL 语句；完整事务回滚必须由应用事务边界保证。

### 3.4 环境使用规则

- 即使数据库支持并强制执行 `CHECK`，跨表不变量仍由 Service 事务保证；
- 严禁依赖隐式字符串转数字、隐式零日期和服务器本地时区；
- `DATETIME(3)` 不自动进行时区转换，应用必须统一按 UTC 写入；
- 应用连接建立后必须校验或显式设置会话时区为 `+00:00`；
- DDL 使用命名约束，避免数据库自动生成不可读约束名；
- SQL Mode 在开发、测试和演示环境保持一致；
- 库存事务不得因为默认 `REPEATABLE-READ` 而省略 `SELECT ... FOR UPDATE`。

---

## 4. 总体设计原则

1. 按业务域拆表，不按页面拼表。
2. 采购、收货、验收、销售和出库采用主表+明细表。
3. 业务表保存当前档案外键和业务发生时快照。
4. 状态转换由Service执行，并写状态历史和审计。
5. 库存余额保存当前结果，流水解释来源。
6. 待验不进入可销售库存。
7. 冻结、不合格、过期和占用彼此独立。
8. 核心记录禁止普通删除。
9. 核心表不统一增加 `deleted`、`tenant_id`、`ext_json`。
10. 核心关系使用真实外键。
11. JSON只用于审计快照和Mock报文。
12. 不建设通用工作流引擎。

---

## 5. 命名、类型和通用字段

| 用途     | 规范                                         |
| -------- | -------------------------------------------- |
| 表名     | 小写蛇形，使用明确业务名                     |
| 主键     | `id`                                       |
| 外键     | `<object>_id`                              |
| 业务编号 | `<business>_no`                            |
| 状态     | `status` 或明确领域状态                    |
| 人员     | `<action>_by`                              |
| 时间     | `<action>_at`                              |
| 数量     | `<meaning>_qty`                            |
| 快照     | `<field>_snapshot`                         |
| 版本     | `version`                                  |
| 约束     | `pk_`、`uk_`、`fk_`、`ck_`、`idx_` |

核心可修改表建议具有：

```text
created_by / created_at / updated_by / updated_at / version
```

追加型不可变表至少具有：

```text
created_by / created_at
```

### 5.1 类型规则

- 所有业务数量按药品基本单位保存，首版不实现多单位换算；
- 金额和数量使用 `DECIMAL`，不使用 `FLOAT`、`DOUBLE`；
- 状态代码使用 `VARCHAR(32)` 或 `VARCHAR(64)`，不使用 MySQL `ENUM`；
- 业务编号使用 `VARCHAR(40)`；
- 批号、批准文号和许可证编号按字符串保存；
- JSON 只保存非关系型快照、差异摘要或 Mock 报文；
- 真实外键关系不得放入 JSON 或逗号字符串。

### 5.2 状态代码规则

数据库代码必须在第 18 章逐项映射上位状态语义。允许为技术实现增加“处理中”等细分状态，但必须满足：

1. 不改变上位状态机允许和禁止的业务路径；
2. 不绕过审核、批准或独立复核；
3. 在映射表中标记为“数据库细分状态”；
4. Java Enum 使用相同代码；
5. 前端中文显示名不得反向决定数据库状态。

---

## 6. 数据域与完整表目录

完整目标模型包含 **51 张候选表**：M1 36 张、M2 10 张、M3 5 张。表数量是审查结果，不是成功指标；实际实现按里程碑分批建表。

| 数据域       | 表名                           | 职责                           | 里程碑 |
| ------------ | ------------------------------ | ------------------------------ | ------ |
| 系统权限     | `sys_user`                   | 用户、账号状态和密码哈希       | M1     |
| 系统权限     | `sys_role`                   | 10 个冻结角色                  | M1     |
| 系统权限     | `sys_permission`             | 业务动作权限目录               | M1     |
| 系统权限     | `sys_user_role`              | 用户当前角色                   | M1     |
| 系统权限     | `sys_role_permission`        | 角色权限关系                   | M1     |
| 系统权限     | `sys_role_assignment`        | 角色申请、审核、批准和执行     | M1     |
| Profile      | `system_runtime_config`      | 当前 Profile 和 Demo 环境守卫  | M2     |
| 基础资料     | `drug`                       | 药品稳定档案                   | M1     |
| 基础资料     | `supplier`                   | 供应商档案                     | M1     |
| 基础资料     | `supplier_scope`             | 供应商许可范围                 | M1     |
| 基础资料     | `customer`                   | 客户档案                       | M1     |
| 基础资料     | `customer_scope`             | 客户经营或使用范围             | M1     |
| 基础资料     | `customer_authorized_person` | 采购与提货人员授权             | M1     |
| 基础资料     | `warehouse`                  | 单一自营仓库                   | M1     |
| 基础资料     | `warehouse_location`         | 库位                           | M1     |
| 基础资料     | `document_attachment`        | 附件元数据                     | M1     |
| 首营资质     | `supplier_first_approval`    | 首营企业审批                   | M1     |
| 首营资质     | `drug_first_approval`        | 药品与供应商组合首营品种审批   | M1     |
| 首营资质     | `customer_qualification`     | 客户资质审核与冻结             | M1     |
| 采购收货验收 | `purchase_order`             | 采购订单主表                   | M1     |
| 采购收货验收 | `purchase_order_item`        | 采购订单明细                   | M1     |
| 采购收货验收 | `receipt`                    | 收货主表                       | M1     |
| 采购收货验收 | `receipt_item`               | 按实际批号拆分的收货明细       | M1     |
| 采购收货验收 | `acceptance_record`          | 验收任务主表                   | M1     |
| 采购收货验收 | `acceptance_item`            | 逐批验收结果                   | M1     |
| 批次库存     | `drug_batch`                 | 药品客观批次                   | M1     |
| 批次库存     | `inventory_balance`          | 批次、库位和质量结论余额       | M1     |
| 批次库存     | `inventory_ledger`           | 不可删除库存流水               | M1     |
| 批次库存     | `inventory_lock`             | 质量冻结事实                   | M2     |
| 销售出库     | `sales_order`                | 销售订单主表                   | M1     |
| 销售出库     | `sales_order_item`           | 销售订单明细                   | M1     |
| 销售出库     | `sales_batch_allocation`     | 批次分配和库存占用             | M1     |
| 销售出库     | `outbound_order`             | 出库任务                       | M1     |
| 销售出库     | `outbound_item`              | 实际出库明细                   | M1     |
| 销售出库     | `outbound_review`            | 每次出库复核尝试               | M1     |
| 运输签收     | `shipment`                   | 发运、运输异常和签收信息       | M2     |
| 质量事件     | `quality_event`              | 质量调查与处置主表             | M2     |
| 质量事件     | `quality_event_inventory`    | 质量事件影响库存               | M2     |
| 质量事件     | `quality_event_action`       | 调查、建议、批准和执行动作     | M2     |
| 追溯 Mock    | `trace_code`                 | 演示追溯码当前状态             | M2     |
| 追溯 Mock    | `trace_code_event`           | 追溯码业务事件                 | M2     |
| 追溯 Mock    | `mock_exchange_task`         | Mock 交换任务                  | M2     |
| 追溯 Mock    | `mock_exchange_attempt`      | 每次 Mock 请求和回执           | M2     |
| 审计历史     | `business_status_history`    | SM-01 至 SM-18 状态历史        | M1     |
| 审计历史     | `audit_event`                | 成功、失败和越权审计           | M1     |
| 审计历史     | `business_correction`        | 受控更正申请、审核、批准和执行 | M1     |
| 演示运维     | `demo_data_task`             | 演示数据初始化和重置           | M3     |
| 演示运维     | `backup_plan`                | 每日备份计划                   | M3     |
| 演示运维     | `backup_execution`           | 备份执行结果                   | M3     |
| 演示运维     | `restore_validation`         | 隔离恢复验证任务               | M3     |
| 演示运维     | `restore_validation_check`   | 恢复后关键链路核对             | M3     |

### 6.1 表目录控制原则

- M1 只实现全国核心闭环所需表；
- M2 在 M1 通过后增加质量事件、冻结、运输签收和广东 Mock；
- M3 最后增加演示运维；
- 不为减少表数把采购、收货、验收、库存、销售和审计塞进万能表；
- 不为追求“企业级”继续增加多组织、财务、冷链和工作流表；
- `system_runtime_config` 只保存当前 Profile 和 Demo 环境守卫，固定 Profile 代码由种子数据或代码常量冻结；
- 简化签收字段保存在 `shipment`，不单独建设 `delivery_receipt`；
- `business_correction` 是横切控制表，不是通用工作流引擎；
- 角色矩阵中仍为“待后续流程确认”的库存调整，不在本版设计表结构。

---

## 7. 核心 ER 关系

```text
drug ───────────────────┐
                        ├─ drug_first_approval ─ supplier
supplier ─ supplier_first_approval
customer ─ customer_qualification

purchase_order_item
        ↓
receipt_item（实际批号）
        ↓
acceptance_item（逐批结论）
        ↓
drug_batch
        ↓
inventory_balance
        ↓
inventory_ledger

sales_order_item
        ↓
sales_batch_allocation
        ↓
inventory_balance
        ↓
outbound_item
        ↓
shipment（发运、异常、签收）
```

质量与码级扩展：

```text
quality_event
  ├─ quality_event_inventory ─ inventory_balance
  ├─ quality_event_action
  └─ inventory_lock

drug_batch ─ trace_code ─ trace_code_event
mock_exchange_task ─ mock_exchange_attempt
```

横切控制：

```text
business_status_history
     ↑ 所有状态对象

audit_event
     ↑ 所有成功、失败、越权和导出

business_correction
     ↑ 已完成验收、收货、出库等受控更正
```

### 7.1 追溯关系原则

批号追溯通过真实外键查询，不建立可编辑“追溯总表”。

完整链路：

```text
供应商
→ 首营企业
→ 首营品种
→ 采购订单
→ 收货批次
→ 验收结论
→ 药品批次
→ 库存余额和流水
→ 销售批次分配
→ 出库复核和实际出库
→ 发运、签收
→ 客户
```

跨模块的 `business_type + business_id` 仅用于审计、状态历史、附件和受控更正，不得替代核心业务外键。

---

## 8. 系统权限与 Profile 域

### 8.1 用户与权限关系

- `sys_user` 不保存明文密码；
- `sys_role.role_code` 唯一；
- `sys_permission.permission_code` 唯一；
- `sys_user_role` 唯一 `(user_id, role_id)`；
- `sys_role_permission` 唯一 `(role_id, permission_id)`；
- 用户、角色和权限产生业务引用后不删除；
- 系统管理员不自动获得质量批准、验收和出库复核权限。

### 8.2 sys_role_assignment

保存：

```text
assignment_no
target_user_id
role_id
status
requested_by / requested_at
reviewed_by / reviewed_at / review_opinion
approved_by / approved_at / approval_opinion
executed_by / executed_at
valid_from / valid_to
reason
```

只有 `EXECUTED` 后才能写 `sys_user_role`。申请人、被授权用户和技术执行人不得成为唯一批准人。

### 8.3 system_runtime_config

使用固定单例行保存：

```text
id = 1
profile_code = NATIONAL_DEFAULT 或 GD_DEMO_PROFILE
demo_environment = 1
database_guard_code
updated_by / updated_at / version
```

规则：

- Profile 代码由受控种子或代码常量定义，不建立可在线编辑目录；
- 切换必须经过权限矩阵规定的审核并写 `audit_event`；
- Profile 切换不修改已有业务事实；
- `demo_environment` 和 `database_guard_code` 共同阻断非 Demo 数据重置；
- 不在本表保存外部接口密钥。

---

## 9. 基础资料域

### 9.1 drug

核心字段：

```text
drug_code
generic_name
trade_name（可空）
approval_no
dosage_form
specification
manufacturer_name
basic_unit
storage_condition
business_category_code
expiry_control_enabled
near_expiry_warning_days
traceability_level
record_status
```

状态代码：

```text
DRAFT
INCOMPLETE
READY_FOR_FIRST_APPROVAL
DISABLED
```

规则：

- `drug_code` 唯一；
- `business_category_code` 用于供应商和客户范围匹配，首版每个药品只保存一个主要经营分类；
- `expiry_control_enabled` 必须启用，除非后续范围明确允许例外；
- `near_expiry_warning_days >= 0`；
- `traceability_level IN ('BATCH','CODE')`；
- 不保存具体批号、效期、库存、冻结和追溯码；
- 被业务引用后不得删除；
- `READY_FOR_FIRST_APPROVAL` 只表示可提交首营，不代表已获采购或销售资格。

### 9.2 supplier / supplier_scope

`supplier` 保存当前主体和证照摘要；`supplier_scope` 多行保存经营或生产范围及有效期。

规则：

- 供应商编码和统一社会信用代码唯一；
- 当前档案启用不代表首营企业批准；
- 采购确认时必须按 `drug.business_category_code` 匹配当前有效范围；
- 证照更换后新增附件和审批版本，不覆盖历史订单快照。

### 9.3 customer / customer_scope / customer_authorized_person

客户档案启用不代表可销售，当前资格由 `customer_qualification` 决定。

`customer_authorized_person` 至少保存：

```text
person_type
person_name
authorization_no
valid_from / valid_to
id_no_last4
sensitive_data_ref（可空）
status
```

Demo 只使用虚构身份数据。接口输出必须脱敏。

销售动态校验必须同时检查：

- 客户资质当前有效；
- 药品经营分类在客户范围内；
- 采购或提货人员授权有效。

### 9.4 warehouse / warehouse_location

首版只初始化一个自营仓库，但保留仓库和库位外键。库位唯一 `(warehouse_id, location_code)`。

建议库位类型：

```text
NORMAL
UNQUALIFIED
```

待验不通过库存余额表示，因此无需通过“待验库位”制造可销售库存记录。

### 9.5 document_attachment

只保存附件元数据，不保存大文件 BLOB：

```text
owner_type / owner_id
document_type
file_name / storage_path / file_hash
valid_from / valid_to
status
```

首营申请引用的资质附件应以对应审批记录作为 owner，从而固定当次申请证据。替换附件新增记录，旧记录标记 `SUPERSEDED`。

---

## 10. 首营与资质域

每次申请独立成行，禁止覆盖旧申请。

### 10.1 当前版本唯一策略

三张审批表使用：

```text
current_marker = 1      当前版本
current_marker = NULL   历史版本
```

并建立：

```text
UNIQUE (owner_key..., current_marker)
CHECK (current_marker IS NULL OR current_marker = 1)
```

MySQL 的唯一 B-Tree 索引允许多行 `NULL`，因此可以保留多个历史版本但只允许一个当前版本。DDL 执行后必须用并发测试验证。

### 10.2 supplier_first_approval

保存申请人、质量审核人、质量负责人、意见、有效期和版本。

数据库状态：

```text
DRAFT
PENDING_QUALITY_REVIEW
RETURNED
PENDING_QUALITY_HEAD_APPROVAL
APPROVED
REJECTED
EXPIRED（有效期派生状态）
```

`EXPIRED` 是由业务流程和权限矩阵补充的派生状态，不改变冻结主链。

### 10.3 drug_first_approval

当前版本唯一：

```text
(drug_id, supplier_id, current_marker)
```

采购确认必须同时满足：

- 药品为 `READY_FOR_FIRST_APPROVAL` 且未停用；
- 供应商首营当前 `APPROVED` 且有效；
- 药品与供应商组合首营当前 `APPROVED` 且有效；
- 供应商范围覆盖药品经营分类。

### 10.4 customer_qualification

状态：

```text
DRAFT
PENDING_REVIEW
RETURNED
VALID
FROZEN
EXPIRED
REJECTED
```

销售只接受当前 `VALID`。冻结解除和到期失效必须写状态历史和审计。

---

## 11. 采购、收货与验收域

### 11.1 purchase_order / purchase_order_item

采购订单状态：

```text
DRAFT
CONFIRMED
PARTIALLY_RECEIVED
COMPLETED
CLOSED
```

规则：

- 采购确认必须校验药品档案、首营企业、首营品种和供应商经营范围；
- 采购订单不能直接形成库存；
- 采购明细保存供应商和药品业务快照；
- 累计收货数量只能由收货事务维护；
- 已产生收货后不得直接关闭或无痕修改核心字段。

对应权限：`PO-001` 至 `PO-009`。

### 11.2 receipt / receipt_item

`receipt.status`：

```text
DRAFT
RECEIVING
PENDING_ISSUE
RECEIVED
CANCELLED
```

业务映射：

```text
草稿       = DRAFT
收货中     = RECEIVING
待处理     = PENDING_ISSUE
已收货     = RECEIVED
已取消     = CANCELLED
待验       = 已生成 acceptance_record(PENDING_ACCEPTANCE) 的跨对象结果
```

`receipt_item` 按实际到货批号拆分，至少保存采购明细、药品、批号、生产日期、有效期和实收数量。

规则：

- 一条采购明细允许分多次收货；
- 一次收货允许出现多个批号；
- 累计收货不得超过采购数量；
- 待处理未解决时不能完成收货；
- 收货完成不形成合格库存；
- 进入验收后来源数据只能通过 `business_correction` 受控更正。

对应权限：`RC-001` 至 `RC-009`。

### 11.3 acceptance_record / acceptance_item

`acceptance_record.status`：

```text
PENDING_ACCEPTANCE
IN_PROGRESS
PENDING_QUALITY
QUALIFIED
PARTIALLY_QUALIFIED
UNQUALIFIED
```

`acceptance_item.result`：

```text
QUALIFIED
PARTIALLY_QUALIFIED
UNQUALIFIED
PENDING_QUALITY
```

规则：

- 必须逐收货批次验收；
- `accepted_qty > 0`；
- `qualified_qty >= 0`、`unqualified_qty >= 0`；
- `qualified_qty + unqualified_qty = accepted_qty`；
- 验收数量不得超过收货数量；
- 过期批次不得提交合格或部分合格中的合格数量；
- 质量介入时进入 `PENDING_QUALITY`，质量管理员给出意见后返回 `IN_PROGRESS`；
- 部分合格只允许 `qualified_qty` 进入合格入库；
- 已完成结论只能受控更正，不能覆盖原结果。

对应权限：`ACPT-001` 至 `ACPT-010`。

### 11.4 验收与入库边界

验收结论本身不增加库存。合格入库是独立事务，使用唯一 `source_event_key` 防止同一 `acceptance_item` 重复入库。

---

## 12. 批次与库存域

### 12.1 drug_batch

唯一：

```text
(drug_id, batch_no, expiry_date)
```

核心字段：

```text
drug_id
batch_no
production_date
expiry_date
manufacturer_name_snapshot
approval_no_snapshot
source_acceptance_item_id
status = ACTIVE / EXPIRED / VOIDED
```

同一批号可以存在于不同药品，追溯查询必须同时指定 `drug_id`。

### 12.2 inventory_balance

唯一：

```text
(drug_batch_id, warehouse_location_id, quality_status)
```

质量结论仅允许：

```text
QUALIFIED
UNQUALIFIED
EXPIRED
```

规则：

- SM-08 中的“待验”由尚未完成合格入库的验收记录表达，不进入库存余额；
- **冻结不属于 `quality_status`**，由 `inventory_lock` 独立表达；
- `on_hand_qty >= 0`；
- `reserved_qty >= 0`；
- `reserved_qty <= on_hand_qty`；
- 任何数量和质量转换必须与库存流水同一事务。

### 12.3 可用数量

不保存可编辑 `available_qty`：

```text
存在 active_marker=1 的 inventory_lock：available_qty = 0
否则：available_qty = on_hand_qty - reserved_qty
```

“可用”是 SM-09 的派生业务状态，不对应一条 `sales_batch_allocation` 记录。

### 12.4 inventory_ledger

核心字段：

```text
ledger_no
source_event_key
inventory_balance_id
movement_type
on_hand_before / on_hand_delta / on_hand_after
reserved_before / reserved_delta / reserved_after
from_quality_status / to_quality_status
source_type / source_id
reason
occurred_at
```

规则：

- `ledger_no` 唯一；
- `source_event_key` 全局唯一；
- `before + delta = after`；
- 完成后禁止 UPDATE 和 DELETE；
- 更正只能新增冲正或补充流水。

### 12.5 合格入库幂等

首版一个 `acceptance_item` 的全部合格数量一次性进入一个库位：

```text
source_event_key = ACCEPTANCE:<acceptance_item_id>:INBOUND
```

部分合格时只消费 `qualified_qty`。重复提交必须命中同一事件，不得重复增加库存。

### 12.6 inventory_lock

核心字段：

```text
lock_no
inventory_balance_id
quality_event_id
status
active_marker
reason
locked_by / locked_at
released_by / released_at
```

状态代码：

```text
ACTIVE
PENDING_RELEASE_APPROVAL
PENDING_UNQUALIFIED_APPROVAL
RELEASED
CONVERTED_TO_UNQUALIFIED
```

“未锁定”表示不存在 `active_marker=1` 的冻结记录。

活动冻结唯一策略：

```text
active_marker = 1      ACTIVE 或待处置审批
active_marker = NULL   RELEASED 或 CONVERTED_TO_UNQUALIFIED 历史
UNIQUE (inventory_balance_id, active_marker)
CHECK (active_marker IS NULL OR active_marker = 1)
```

规则：

- 首版冻结整条库存余额，不实现部分数量冻结；
- 冻结不减少现存数量，也不改变 QUALIFIED 质量结论；
- 冻结时已有 ACTIVE 占用转为 `BLOCKED_BY_QUALITY`，同步减少 `reserved_qty`，销售订单退回待分配批次；
- 解除冻结只改变锁状态；
- 转不合格必须把 QUALIFIED 数量转移到 UNQUALIFIED 余额；
- 审批退回时从待审批状态返回 ACTIVE。

对应权限：`INV-001` 至 `INV-012`、`QE-002` 至 `QE-010`。

### 12.7 质量状态转换

合格转过期、冻结转不合格使用成对流水：

```text
QUALIFIED 扣减
+
UNQUALIFIED 或 EXPIRED 增加
```

两条流水使用同一业务事件组号并在同一事务提交。禁止直接覆盖 `quality_status`。

### 12.8 人工库存调整

首版不建立 `inventory_adjustment` 表，不开放人工直接改库存。只有上位流程和状态机正式变更后才能设计。

---

## 13. 销售、出库、发运与签收域

### 13.1 sales_order / sales_order_item

`sales_order.status`：

```text
DRAFT
PENDING_CUSTOMER_CHECK
PENDING_MANUAL_REVIEW
CONFIRMED
PENDING_ALLOCATION
ALLOCATED
PENDING_OUTBOUND_REVIEW
COMPLETED
REJECTED
CLOSED
```

业务映射：

- `PENDING_MANUAL_REVIEW` 是“待客户校验”的内部人工处理细分；
- 质量冻结影响已分配批次时，`ALLOCATED` 或 `PENDING_OUTBOUND_REVIEW` 返回 `PENDING_ALLOCATION`；
- 进入出库复核后核心内容不得直接修改；
- 客户资质必须在确认和出库前动态复核。

对应权限：`SO-001` 至 `SO-014`。

### 13.2 sales_batch_allocation

状态：

```text
ACTIVE
RELEASED
BLOCKED_BY_QUALITY
CONSUMED
```

业务映射：

```text
可用       = 无占用记录且可用数量大于0的派生条件
已占用     = ACTIVE
已释放     = RELEASED
质量阻断   = BLOCKED_BY_QUALITY
已出库     = CONSUMED
```

规则：

- ACTIVE 汇总等于 `inventory_balance.reserved_qty`；
- 只能占用 QUALIFIED、未过期、无活动冻结的库存；
- 质量冻结把 ACTIVE 转为 BLOCKED_BY_QUALITY，并同步释放占用汇总；
- 质量阻断后的订单必须重新选择批次；
- 占用、释放、质量阻断和消费均写唯一来源库存流水。

### 13.3 outbound_order / outbound_item

`outbound_order.status`：

```text
PENDING_REVIEW
REVIEWING
REVIEW_FAILED
REVIEW_PASSED
OUTBOUNDED
```

规则：

- `REVIEW_FAILED` 纠正后返回 `PENDING_REVIEW`；
- 一张销售订单首版只建立一张当前出库任务；
- 实际出库必须来自 ACTIVE 分配；
- `REVIEW_PASSED` 但库存事务失败时不得进入 OUTBOUNDED；
- 完成出库后不得删除或直接回滚库存事实。

### 13.4 outbound_review

每次复核尝试独立成行：

```text
outbound_order_id
attempt_no
status = IN_PROGRESS / PASSED / FAILED
reviewer_id / reviewed_at
failure_reason
customer_check_result
inventory_check_result
batch_check_result
quantity_check_result
order_snapshot_hash
```

唯一 `(outbound_order_id, attempt_no)`。失败记录不得覆盖，纠正后重新提交必须创建新尝试。

对应权限：`OUT-001` 至 `OUT-012`。

### 13.5 shipment

首版将发运、运输异常处理和签收保存于一张表：

```text
shipment_no
outbound_order_id
status = PENDING_SHIPMENT / SHIPPED / TRANSPORT_EXCEPTION /
         EXCEPTION_PROCESSING / SIGNED / EXCEPTION_CLOSED
shipped_at
origin_address
destination_name / destination_address
package_count
transport_method
carrier_name / vehicle_no / transport_doc_no
transport_exception_reason
exception_handled_by / exception_handled_at / exception_result
receiver_name / received_at / receipt_confirmation_type
registered_by
```

规则：

- 只有完成出库才能发运；
- `TRANSPORT_EXCEPTION` 处理时进入 `EXCEPTION_PROCESSING`；
- 处理结果可以进入 SIGNED 或 EXCEPTION_CLOSED；
- 收货单位和地址必须与销售订单快照一致；
- 签收时间不得早于发运时间；
- 更正通过 `business_correction`、状态历史和审计保留原值；
- 不实现 GPS、TMS、车辆调度和承运结算。

---

## 14. 质量事件与库存冻结域

### 14.1 quality_event

`quality_event.status`：

```text
CREATED
INVESTIGATING
PENDING_DISPOSITION_APPROVAL
DISPOSITION_APPROVED
EXECUTING
DISPOSED
CLOSED
CANCELLED
```

业务映射：

```text
已创建       = CREATED
调查中       = INVESTIGATING
待处置审批   = PENDING_DISPOSITION_APPROVAL
处置已批准   = DISPOSITION_APPROVED
处置执行中   = EXECUTING
已处置       = DISPOSED
已关闭       = CLOSED
已取消       = CANCELLED
```

规则：

- 质量管理员调查并提出处置建议；
- 质量负责人可以批准或退回调查；
- 已批准后由仓库管理员或系统动作执行；
- 已产生冻结或实际处置后不得取消；
- 关闭前必须确认关联冻结和库存流水已处理。

### 14.2 quality_event_inventory

使用真实关联表保存一个质量事件影响的库存余额和影响类型，不用逗号字符串或 JSON 数组替代核心关系。

### 14.3 quality_event_action

追加保存：

```text
CREATE
INVESTIGATE
PROPOSE_RELEASE
PROPOSE_UNQUALIFIED
RETURN_TO_INVESTIGATION
APPROVE
START_EXECUTION
EXECUTE
CLOSE
CANCEL
```

完成动作禁止 UPDATE 和 DELETE。

### 14.4 与 inventory_lock 联动

- 紧急冻结创建 ACTIVE 锁；
- 提交解除建议进入 PENDING_RELEASE_APPROVAL；
- 提交转不合格建议进入 PENDING_UNQUALIFIED_APPROVAL；
- 质量负责人退回时恢复 ACTIVE；
- 批准解除后进入 RELEASED；
- 批准转不合格并完成库存转移后进入 CONVERTED_TO_UNQUALIFIED。

对应权限：`QE-001` 至 `QE-013`。

---

## 15. 广东追溯码与 Mock 域

全国默认支持批号追溯。只有药品追溯级别为 CODE 且启用 `GD_DEMO_PROFILE` 时，才强制执行码级流程。

### 15.1 trace_code

`trace_code.current_status`：

```text
PENDING_VERIFY
VERIFIED
VERIFY_FAILED
VOIDED
```

数据库映射：

- “未采集”表示当前业务对象尚无有效 `trace_code` 记录；
- 扫描或录入时创建记录并进入 `PENDING_VERIFY`；
- 未采集码直接作废时，创建 `VOIDED` 记录保存码值和作废原因；
- 不保存 `NOT_COLLECTED` 空记录。

规则：

- `trace_code` 全局唯一；
- 药品、批号、数量和业务关系不一致进入 VERIFY_FAILED；
- 纠正后返回 PENDING_VERIFY，并新增核验事件；
- VERIFY_FAILED 不得直接改为 VERIFIED；
- VOIDED 不得重新使用。

### 15.2 trace_code_event

事件只追加：

```text
INBOUND_SCAN
OUTBOUND_SCAN
VERIFY_SUCCESS
VERIFY_FAILED
REVERIFY_SUBMITTED
VOID
```

每次失败和重新核验必须独立保存。

对应权限：`GD-001` 至 `GD-007`。

### 15.3 mock_exchange_task

`mock_exchange_task.status`：

```text
PENDING
UPLOADING
SUCCEEDED
FAILED
RETRY_PENDING
TERMINATED
```

数据库映射：

- “未生成”表示 `mock_exchange_task` 尚不存在；
- 有效本地入库或出库事件触发后创建任务并进入 PENDING；
- 不保存 `NOT_GENERATED` 空任务记录。

规则：

- FAILED 只能进入 RETRY_PENDING 或 TERMINATED；
- RETRY_PENDING 重试时进入 UPLOADING；
- 只有新尝试获得明确成功回执才能进入 SUCCEEDED；
- TERMINATED 是终态；
- Mock 成功不得描述为真实监管平台成功。

### 15.4 mock_exchange_attempt

每次上传或重试新增 `(task_id, attempt_no)`，保存请求、回执、结果、失败代码和耗时，禁止覆盖旧失败。

外部调用不得长时间持有库存事务锁。

对应权限：`GD-008` 至 `GD-017`。

---

## 16. 状态历史、审计与受控更正域

### 16.1 business_status_history

只追加保存：

```text
business_type / business_id
from_status / to_status
action_code / reason
operator_id / occurred_at
related_approval_type / related_approval_id
```

状态变化成功后，历史最新 `to_status` 必须与业务表当前状态一致。

### 16.2 audit_event

记录 `SUCCESS / FAILED / DENIED`：

```text
request_id
actor_user_id
action_code
target_type / target_id
result
failure_code / failure_message
reason
before_data / after_data
source_ip
occurred_at
```

`before_data` 和 `after_data` 仅保存发生变化且已经脱敏的字段，不保存整行密码、密钥、附件内容和不必要的身份证件。

### 16.3 business_correction

用于保存已完成记录的受控更正链，不用于一般草稿编辑。

核心字段：

```text
correction_no
target_type / target_id
correction_type
status = DRAFT / PENDING_REVIEW / PENDING_APPROVAL / APPROVED / REJECTED / EXECUTED / CANCELLED
requested_by / requested_at
reason
before_snapshot / proposed_after_snapshot
reviewed_by / reviewed_at / review_opinion
approved_by / approved_at / approval_opinion
executed_by / executed_at
execution_result
```

适用对象：

- 已进入验收的收货数据；
- 已完成验收结论；
- 已确认采购或销售核心数据；
- 已出库、发运和签收记录的说明性更正；
- 其他权限矩阵明确要求受控更正的对象。

规则：

- 申请、审核、批准和执行不得由同一用户包办；
- `EXECUTED` 不得覆盖原审计、状态历史和库存流水；
- 涉及库存事实时只允许生成冲正或补充流水，不直接改历史流水；
- `target_type + target_id` 由 Service 校验对象存在；
- 该表是固定更正流程，不允许配置任意工作流。

### 16.4 数据库账号建议

推荐至少区分：

1. `schema_owner`：仅用于建表和迁移；
2. `app_runtime`：应用运行时读写；
3. `audit_reader`：可选，只读审计演示账号。

对 `inventory_ledger`、`audit_event`、`business_status_history`、`outbound_review` 完成记录、`trace_code_event`、`mock_exchange_attempt` 和 `quality_event_action`，运行账号原则上只允许 INSERT/SELECT，不授予普通 UPDATE/DELETE。是否在首版真正拆账号，由 DDL Goal 决定。

---

## 17. 演示数据、备份和恢复

### 17.1 demo_data_task

状态：

```text
PENDING
RUNNING
SUCCEEDED
FAILED
```

仅在明确 Demo 环境执行；失败后重新执行必须保留旧失败任务或尝试。

### 17.2 backup_plan / backup_execution

`backup_execution.status`：

```text
PENDING
RUNNING
SUCCEEDED
FAILED
```

业务映射：待执行、备份中、备份成功和备份失败。

SUCCEEDED 必须具有备份位置、文件摘要、文件大小和完成时间；FAILED 必须保存失败阶段和原因。

### 17.3 restore_validation / restore_validation_check

`restore_validation.status`：

```text
PENDING
RESTORING
VERIFYING
SUCCEEDED
FAILED
```

业务映射：

```text
待执行       = PENDING
恢复验证中   = RESTORING
核对中       = VERIFYING
验证成功     = SUCCEEDED
恢复失败     = FAILED
```

规则：

- 只有有效备份成功记录才能创建恢复验证；
- 恢复目标必须为隔离环境；
- 所有必选核对项通过后才能 SUCCEEDED；
- 恢复或核对任一阶段失败均进入 FAILED；
- 备份失败和恢复失败记录不得删除；
- 系统管理员执行，质量管理员或审计查看员复核证据。

对应权限：`DEMO-001` 至 `DEMO-005`、`BAK-001` 至 `BAK-010`。

核心经营、质量、追溯和审计记录设计为至少保存 5 年。

---

## 18. SM-01 至 SM-18 严格映射

| 状态机                   | 上位业务语义                                                                                              | 表与字段                                                                             | 数据库代码或派生表达                                                                                                                                          | 权限动作                                | 说明                                                           |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | -------------------------------------------------------------- |
| SM-01 药品档案           | 草稿 / 待完善 / 可提交首营 / 停用                                                                         | `drug.record_status`                                                               | DRAFT / INCOMPLETE / READY_FOR_FIRST_APPROVAL / DISABLED                                                                                                      | MD-001～MD-004                          | 停用恢复需重新检查资料                                         |
| SM-02 首营企业           | 草稿 / 待质量审核 / 退回补充 / 待质量负责人批准 / 已批准 / 已驳回 / 已失效                                | `supplier_first_approval.status`                                                   | DRAFT / PENDING_QUALITY_REVIEW / RETURNED / PENDING_QUALITY_HEAD_APPROVAL / APPROVED / REJECTED / EXPIRED                                                     | QA-001～QA-006                          | 撤回回到 DRAFT；当前版本由 current_marker 控制                 |
| SM-03 首营品种           | 同 SM-02，按药品+供应商                                                                                   | `drug_first_approval.status`                                                       | 同 SM-02                                                                                                                                                      | QA-007～QA-010                          | 按`(drug_id,supplier_id)` 建立关系                           |
| SM-04 客户资质           | 草稿 / 待审核 / 退回补充 / 有效 / 已驳回 / 冻结 / 已失效                                                  | `customer_qualification.status`                                                    | DRAFT / PENDING_REVIEW / RETURNED / VALID / REJECTED / FROZEN / EXPIRED                                                                                       | QA-011～QA-016                          | 冻结解除返回 VALID；冻结仍可因到期进入 EXPIRED                 |
| SM-05 采购订单           | 草稿 / 已确认 / 部分收货 / 已完成 / 已关闭                                                                | `purchase_order.status`                                                            | DRAFT / CONFIRMED / PARTIALLY_RECEIVED / COMPLETED / CLOSED                                                                                                   | PO-001～PO-009                          | 采购不形成库存                                                 |
| SM-06 收货               | 草稿 / 收货中 / 待处理 / 已收货 / 待验 / 已取消                                                           | `receipt.status` + `acceptance_record.status`                                    | DRAFT / RECEIVING / PENDING_ISSUE / RECEIVED / CANCELLED；待验=PENDING_ACCEPTANCE                                                                             | RC-001～RC-009                          | 待验是生成验收任务后的跨对象结果                               |
| SM-07 验收               | 待验收 / 验收中 / 待质量处理 / 合格 / 部分合格 / 不合格                                                   | `acceptance_record.status` + `acceptance_item.result`                            | PENDING_ACCEPTANCE / IN_PROGRESS / PENDING_QUALITY / QUALIFIED / PARTIALLY_QUALIFIED / UNQUALIFIED                                                            | ACPT-001～ACPT-010                      | 只有合格数量可入库                                             |
| SM-08 批号库存质量结论   | 待验 / 合格 / 不合格 / 过期                                                                               | `acceptance_record` + `inventory_balance.quality_status`                         | 待验=PENDING_ACCEPTANCE；QUALIFIED / UNQUALIFIED / EXPIRED                                                                                                    | INV-003、INV-011、QE-008～QE-010        | **冻结不属于 quality_status**；转不合格由 SM-14 批准触发 |
| SM-09 库存占用           | 可用 / 已占用 / 已释放 / 质量阻断 / 已出库                                                                | 派生可用量 +`sales_batch_allocation.status`                                        | DERIVED_AVAILABLE / ACTIVE / RELEASED / BLOCKED_BY_QUALITY / CONSUMED                                                                                         | SO-008～SO-009、SO-013～SO-014、OUT-005 | 可用为派生条件；质量阻断不再占用 reserved_qty                  |
| SM-10 销售订单           | 草稿 / 待客户校验 / 待人工确认 / 已确认 / 待分配批次 / 已分配批次 / 待出库复核 / 已完成 / 已驳回 / 已关闭 | `sales_order.status`                                                               | DRAFT / PENDING_CUSTOMER_CHECK / PENDING_MANUAL_REVIEW / CONFIRMED / PENDING_ALLOCATION / ALLOCATED / PENDING_OUTBOUND_REVIEW / COMPLETED / REJECTED / CLOSED | SO-001～SO-014                          | 质量阻断后返回 PENDING_ALLOCATION                              |
| SM-11 出库复核           | 待复核 / 复核中 / 复核通过 / 复核不通过 / 已出库                                                          | `outbound_order.status` + `outbound_review.status`                               | PENDING_REVIEW / REVIEWING / REVIEW_PASSED / REVIEW_FAILED / OUTBOUNDED；尝试=IN_PROGRESS/PASSED/FAILED                                                       | OUT-001～OUT-006                        | 失败纠正后返回 PENDING_REVIEW 并新建尝试                       |
| SM-12 发运签收           | 待发运 / 已发运 / 运输异常 / 异常处理中 / 已签收 / 异常关闭                                               | `shipment.status`                                                                  | PENDING_SHIPMENT / SHIPPED / TRANSPORT_EXCEPTION / EXCEPTION_PROCESSING / SIGNED / EXCEPTION_CLOSED                                                           | OUT-007～OUT-012                        | 发运、异常处理和签收保存在同一主记录并写历史                   |
| SM-13 质量事件           | 已创建 / 调查中 / 待处置审批 / 处置已批准 / 处置执行中 / 已处置 / 已关闭 / 已取消                         | `quality_event.status`                                                             | CREATED / INVESTIGATING / PENDING_DISPOSITION_APPROVAL / DISPOSITION_APPROVED / EXECUTING / DISPOSED / CLOSED / CANCELLED                                     | QE-001、QE-003～QE-013                  | 产生冻结或处置后不得取消                                       |
| SM-14 库存冻结与质量处置 | 未锁定 / 冻结 / 待解除审批 / 已解除 / 待转不合格审批 / 已转不合格                                         | `inventory_lock.status` + `active_marker` + `inventory_balance.quality_status` | 未锁定=无活动锁；ACTIVE / PENDING_RELEASE_APPROVAL / RELEASED / PENDING_UNQUALIFIED_APPROVAL / CONVERTED_TO_UNQUALIFIED                                       | QE-002、QE-005～QE-010                  | 审批退回恢复 ACTIVE；转不合格同步 SM-08                        |
| SM-15 本地追溯码核验     | 未采集 / 待核验 / 核验通过 / 核验失败 / 已作废                                                            | `trace_code.current_status` + `trace_code_event`                                 | 未采集=无有效码记录；PENDING_VERIFY / VERIFIED / VERIFY_FAILED / VOIDED                                                                                       | GD-001～GD-007                          | 只表达本地核验，不包含上传状态                                 |
| SM-16 Mock 交换          | 未生成 / 待上传 / 上传中 / 上传成功 / 上传失败 / 待重试 / 已终止                                          | `mock_exchange_task.status` + `mock_exchange_attempt`                            | 未生成=无任务记录；PENDING / UPLOADING / SUCCEEDED / FAILED / RETRY_PENDING / TERMINATED                                                                      | GD-008～GD-017                          | 每次尝试独立；TERMINATED 为终态                                |
| SM-17 演示数据任务       | 待执行 / 执行中 / 成功 / 失败                                                                             | `demo_data_task.status`                                                            | PENDING / RUNNING / SUCCEEDED / FAILED                                                                                                                        | DEMO-001～DEMO-005                      | 仅 Demo 环境                                                   |
| SM-18 备份恢复验证       | 待执行 / 备份中 / 备份成功 / 备份失败 / 恢复验证中 / 核对中 / 验证成功 / 恢复失败                         | `backup_execution.status` + `restore_validation.status`                          | PENDING/RUNNING/SUCCEEDED/FAILED；PENDING/RESTORING/VERIFYING/SUCCEEDED/FAILED                                                                                | BAK-001～BAK-010                        | 备份成功后才能恢复；全部核对通过才能验证成功                   |

### 18.1 映射控制规则

- 上位业务语义来自 `BUSINESS_STATE_MACHINE.md` v1.1；
- 权限动作来自 `ROLE_PERMISSION_MATRIX.md` v1.1；
- 数据库细分状态不得产生上位状态机禁止的跳转；
- 无记录派生状态只允许用于“未采集、未生成、未锁定、可用”等明确语义；
- 所有成功状态转换写 `business_status_history` 和 `audit_event`；
- 当前状态与最新状态历史不一致时验收失败；
- 禁止通过 SQL 直接修正状态而不保留更正证据。

---

## 19. BF-01至BF-18映射

| 流程  | 主要表                                                                       | 数据结果             |
| ----- | ---------------------------------------------------------------------------- | -------------------- |
| BF-01 | drug、document_attachment                                                    | 药品档案             |
| BF-02 | supplier、supplier_scope、supplier_first_approval                            | 首营企业             |
| BF-03 | drug_first_approval                                                          | 首营品种             |
| BF-04 | customer、customer_scope、customer_authorized_person、customer_qualification | 客户资质             |
| BF-05 | purchase_order、purchase_order_item                                          | 采购订单             |
| BF-06 | receipt、receipt_item                                                        | 收货                 |
| BF-07 | acceptance_record、acceptance_item                                           | 逐批验收             |
| BF-08 | drug_batch、inventory_balance、inventory_ledger                              | 合格入库             |
| BF-09 | inventory_balance、inventory_ledger                                          | 库存与质量状态       |
| BF-10 | sales_order、sales_order_item                                                | 销售与客户动态校验   |
| BF-11 | sales_batch_allocation、inventory_balance、inventory_ledger                  | 批次分配和占用       |
| BF-12 | outbound_order、outbound_item、outbound_review、inventory_ledger             | 复核和出库           |
| BF-13 | 核心业务外键、business_status_history、audit_event                           | 批号全过程追溯       |
| BF-14 | shipment                                                                     | 发运、运输异常和签收 |
| BF-15 | quality_event、quality_event_inventory、quality_event_action、inventory_lock | 质量事件和冻结       |
| BF-16 | trace_code、trace_code_event、mock_exchange_task、mock_exchange_attempt      | 广东Mock             |
| BF-17 | demo_data_task                                                               | 演示数据             |
| BF-18 | backup_plan、backup_execution、restore_validation、restore_validation_check  | 备份恢复             |

---

## 20. 约束设计

### 20.1 主键和外键

所有核心表使用 `BIGINT` 内部主键，业务对象另设唯一业务编号。

外键默认：

```text
ON DELETE RESTRICT
ON UPDATE RESTRICT
```

核心业务不得大面积使用 `CASCADE`，不得删除父记录制造追溯断链。

### 20.2 必须的唯一约束

至少包括：

- 用户名、角色代码、权限代码；
- 药品、供应商、客户、仓库和库位编码；
- 统一社会信用代码；
- 所有业务单号；
- 药品批次 `(drug_id, batch_no, expiry_date)`；
- 当前首营和资质版本的 `current_marker`；
- 活动库存冻结的 `active_marker`；
- `inventory_ledger.source_event_key`；
- 追溯码；
- Mock 尝试 `(task_id, attempt_no)`；
- 出库复核尝试 `(outbound_order_id, attempt_no)`。

### 20.3 CHECK 约束

实际 MySQL 版本确认支持后至少实现：

```text
数量 >= 0
订单数量 > 0
reserved_qty <= on_hand_qty
qualified_qty + unqualified_qty = accepted_qty
production_date <= expiry_date
valid_from <= valid_to
near_expiry_warning_days >= 0
attempt_no > 0
current_marker IS NULL OR current_marker = 1
active_marker IS NULL OR active_marker = 1
```

### 20.4 跨表不变量

Service 事务必须保证：

- 药品经营分类与供应商、客户范围匹配；
- 累计收货不超过采购数量；
- 验收数量不超过收货数量；
- 合格验收通过唯一 `source_event_key` 只入库一次；
- ACTIVE 分配汇总等于 `reserved_qty`；
- 出库数量不超过 ACTIVE 分配；
- 冻结、过期和不合格库存不能销售；
- 准入和资质在采购、销售、出库三个时点有效；
- 出库复核失败不得扣减库存；
- 成对质量状态转移数量相等；
- 受控更正不覆盖原流水和审计；
- 恢复核对未全部通过不得成功。

---

## 21. 业务快照和不可变记录

### 21.1 快照范围

采购订单保存：

- 供应商名称、证照和范围校验摘要；
- 药品编码、通用名称、规格、生产企业、批准文号、基本单位和经营分类。

销售订单保存：

- 客户名称、证照、范围校验摘要；
- 采购或提货人员授权摘要；
- 药品关键字段。

收货、验收和出库保存：

- 批号、生产日期、有效期；
- 数量、生产企业和批准文号；
- 来源订单、收货、验收、分配和库存余额。

### 21.2 不可变记录

完成后禁止普通 UPDATE 或 DELETE：

```text
inventory_ledger
business_status_history
audit_event
outbound_review
trace_code_event
mock_exchange_attempt
quality_event_action
backup_execution
restore_validation_check
```

### 21.3 受控更正

```text
保留原记录
→ 创建 business_correction
→ 审核和批准
→ 新增冲正、补充或说明记录
→ 更新允许变更的当前摘要
→ 写状态历史和审计
```

涉及库存数量时禁止直接修改历史余额或流水；只能通过新的业务事件调整当前结果。

---

## 22. 核心事务边界

### T-01 采购确认

锁定订单，校验药品状态、供应商首营、首营品种、药品经营分类和供应商范围，固定快照，更新状态，写历史和审计。

### T-02 收货完成与生成待验

锁定采购明细，校验可收数量，保存实际批号，更新累计收货，把 receipt 更新为 RECEIVED，创建 acceptance_record(PENDING_ACCEPTANCE)，写历史和审计。

### T-03 验收结论

锁定验收和收货明细，校验数量，保存逐批合格、部分合格或不合格结论，更新总体状态，写历史和审计。本事务不增加可销售库存。

### T-04 合格入库

```text
锁定 acceptance_item
→ 校验 qualified_qty > 0
→ 使用唯一 source_event_key 检查未入库
→ 创建或取得 drug_batch
→ 锁定或创建 QUALIFIED inventory_balance
→ 增加 on_hand_qty
→ 插入 INBOUND inventory_ledger
→ 写状态历史和审计
```

部分合格只消费 `qualified_qty`。

### T-05 库存占用

按 `inventory_balance.id` 升序 `SELECT ... FOR UPDATE`，校验合格、未过期、无活动冻结，创建 ACTIVE allocation，增加 reserved，写 RESERVE 流水并更新销售状态。

### T-06 主动释放占用

锁定 allocation 和库存余额，ACTIVE 改为 RELEASED，减少 reserved，写 RELEASE 流水并更新订单状态。

### T-07 质量冻结与占用阻断

```text
锁定受影响 inventory_balance
→ 找出 ACTIVE allocation
→ allocation 改 BLOCKED_BY_QUALITY
→ 减少 reserved_qty
→ 销售订单退回 PENDING_ALLOCATION
→ 创建 active_marker=1 的 inventory_lock(ACTIVE)
→ 写 RELEASE/LOCK 流水
→ 更新质量事件、状态历史和审计
```

### T-08 出库复核失败后重新提交

锁定 outbound_order，确认 REVIEW_FAILED，校验仓库或销售已纠正源问题，更新为 PENDING_REVIEW，新增下一次 outbound_review 尝试，保留旧失败记录。

### T-09 出库完成

确认最近复核 PASSED，锁定库存，再校验客户、质量、效期、冻结和数量，减少 on_hand 与 reserved，allocation 改 CONSUMED，创建 outbound_item 和 OUTBOUND 流水，更新销售与出库状态，生成追溯事件与 Mock 任务。任一步失败全部回滚。

### T-10 解除冻结

确认质量负责人批准，锁定 inventory_lock，把 PENDING_RELEASE_APPROVAL 更新为 RELEASED，`active_marker` 置 NULL，写 UNLOCK 流水、质量动作、历史和审计。质量结论保持 QUALIFIED。

### T-11 转不合格

确认质量负责人批准，锁定 QUALIFIED 余额和冻结记录，扣减 QUALIFIED、增加 UNQUALIFIED，写成对质量转移流水，把冻结更新为 CONVERTED_TO_UNQUALIFIED 并清空 active_marker，写质量动作、历史和审计。

### T-12 过期转换

每日任务加业务访问守卫：锁定到期 QUALIFIED 余额，阻断或释放占用，转入 EXPIRED，写成对流水、历史和审计。

### T-13 运输异常处理

锁定 shipment，TRANSPORT_EXCEPTION 更新为 EXCEPTION_PROCESSING，保存质量调查和处理结果；根据结果进入 SIGNED 或 EXCEPTION_CLOSED，并写状态历史和审计。

### T-14 受控更正执行

锁定 `business_correction` 和目标对象，确认 APPROVED，执行允许的补充或冲正，标记 EXECUTED，写审计。任何一步失败全部回滚。

### T-15 Mock 重试

短事务领取 FAILED/RETRY_PENDING 任务并新增 attempt，事务外调用 Mock，短事务保存结果。禁止持有库存锁等待外部调用。

### T-16 备份恢复验证

备份执行独立记录 PENDING→RUNNING→SUCCEEDED/FAILED。只有 SUCCEEDED 备份可创建恢复验证；恢复进入 RESTORING，恢复完成后进入 VERIFYING，全部核对通过才 SUCCEEDED，否则 FAILED。

---

## 23. 库存并发、锁和死锁

库存读取后准备修改时必须在事务内使用 `SELECT ... FOR UPDATE`。所有批量库存操作统一按ID升序锁定。锁定条件必须命中主键或合适索引，禁止无索引全表扫描。

应用必须处理死锁：回滚整个事务，仅对幂等事务有限重试，建议最多3次指数退避，最终失败写审计；业务校验失败不重试。

version适合档案和草稿编辑；库存以事务锁为主。

---

## 24. 索引与核心查询

至少支持：药品编码、证照到期、当前首营、客户当前资质、采购待收货、待验任务、药品+批号、可销售库存、库存流水、ACTIVE占用、待复核出库、质量事件、当前冻结、追溯码、Mock待处理、状态历史和审计查询。

首版不建立物化追溯总表，先通过真实关系和索引JOIN实现。

---

## 25. 新数据库基线与重建

文档冻结后建议：

```text
sql/
├── 001_baseline_system_profile.sql
├── 002_baseline_master_qualification.sql
├── 003_baseline_purchase_receipt_acceptance.sql
├── 004_baseline_inventory_sales_outbound.sql
├── 005_baseline_quality_trace_audit.sql
├── 006_baseline_demo_backup.sql
├── 007_seed_demo_reference_data.sql
├── 008_seed_demo_users_roles.sql
├── 009_seed_demo_business_data.sql
└── 010_verify_database_invariants.sql
```

必须从空Schema顺序执行，结构和种子数据分开，失败立即停止，验证脚本不修改业务数据。新基线通过后删除或替换旧001_create_drug_table.sql，不保留冲突基线。

---

## 26. 数据库验收场景

| 编号     | 场景                                | 预期                                |
| -------- | ----------------------------------- | ----------------------------------- |
| DB-AT-01 | 重复药品编码                        | 唯一约束拒绝                        |
| DB-AT-02 | 已被业务引用的药品删除              | 阻断，只允许停用                    |
| DB-AT-03 | 同一主体出现两个当前首营版本        | 唯一策略或事务阻断                  |
| DB-AT-04 | 首营未批准确认采购订单              | 阻断且订单状态不变                  |
| DB-AT-05 | 采购订单直接增加库存                | 无允许路径                          |
| DB-AT-06 | 累计收货超过采购数量                | 事务阻断                            |
| DB-AT-07 | 收货员提交验收结论                  | 权限阻断并审计                      |
| DB-AT-08 | 合格数+不合格数不等于验收数         | 约束或业务阻断                      |
| DB-AT-09 | 同一合格验收重复入库                | 幂等阻断                            |
| DB-AT-10 | 无验收来源增加库存                  | 阻断                                |
| DB-AT-11 | 库存余额出现负数                    | 约束和事务阻断                      |
| DB-AT-12 | 并发占用同一库存                    | 不超卖                              |
| DB-AT-13 | 冻结库存新建占用                    | 阻断                                |
| DB-AT-14 | 冻结时已有占用                      | 同事务释放并退回分配                |
| DB-AT-15 | 过期库存占用或出库                  | 阻断                                |
| DB-AT-16 | 复核失败执行出库                    | 阻断且库存不变                      |
| DB-AT-17 | 出库事务中途失败                    | 全部回滚                            |
| DB-AT-18 | 修改或删除库存流水                  | 阻断                                |
| DB-AT-19 | 质量管理员自行批准解除冻结          | 阻断                                |
| DB-AT-20 | 转不合格后仍有合格可用余额          | 验收失败                            |
| DB-AT-21 | 重复追溯码                          | 唯一约束或业务阻断                  |
| DB-AT-22 | 追溯码与药品批号不一致              | 核验失败                            |
| DB-AT-23 | Mock失败手工改成功                  | 阻断并安全审计                      |
| DB-AT-24 | Mock重试覆盖旧失败                  | 阻断，新增attempt                   |
| DB-AT-25 | 非Demo环境执行重置                  | 环境守卫阻断                        |
| DB-AT-26 | 备份失败显示成功                    | 状态规则阻断                        |
| DB-AT-27 | 无有效备份执行恢复成功              | 阻断                                |
| DB-AT-28 | 恢复核对未全部通过标记成功          | 阻断                                |
| DB-AT-29 | 基础档案修改后查询旧订单            | 显示业务快照                        |
| DB-AT-30 | 按药品和批号追溯                    | 可串联供应商至客户                  |
| DB-AT-31 | 同批号存在不同药品                  | 必须同时按drug_id查询               |
| DB-AT-32 | 无权限直接调用API                   | 拒绝并写audit_event                 |
| DB-AT-33 | 非法状态跳转                        | 阻断且无伪历史                      |
| DB-AT-34 | 死锁模拟                            | 回滚并有限重试                      |
| DB-AT-35 | 无效日期和零日期                    | 严格模式或校验拒绝                  |
| DB-AT-36 | 审计包含明文密码                    | 测试失败                            |
| DB-AT-37 | 药品经营分类不在供应商范围          | 采购确认阻断                        |
| DB-AT-38 | 药品经营分类不在客户范围            | 销售确认阻断                        |
| DB-AT-39 | 同一 acceptance_item 重复入库       | source_event_key 唯一约束或幂等返回 |
| DB-AT-40 | 同一库存余额创建两个活动冻结        | active_marker 唯一约束阻断          |
| DB-AT-41 | 未批准 business_correction 执行更正 | 阻断且原数据不变                    |
| DB-AT-42 | 更正库存流水时直接 UPDATE 历史流水  | 阻断，必须新增冲正或补充流水        |

| DB-AT-43 | SM-08 质量状态写入冻结代码 | 阻断；冻结只能写 inventory_lock |
| DB-AT-44 | 质量冻结影响 ACTIVE 占用 | allocation 转 BLOCKED_BY_QUALITY、reserved 减少、订单退回待分配 |
| DB-AT-45 | 复核失败纠正后重新提交 | outbound_order 返回 PENDING_REVIEW，新增复核尝试 |
| DB-AT-46 | 运输异常开始处理 | shipment 进入 EXCEPTION_PROCESSING 并保留异常原值 |
| DB-AT-47 | 未采集追溯码提前建立 NOT_COLLECTED 空记录 | 设计验收失败；未采集由无有效记录表达 |
| DB-AT-48 | 未生成 Mock 任务提前建立 NOT_GENERATED 空任务 | 设计验收失败；未生成由无任务记录表达 |
| DB-AT-49 | 质量事件批准后未进入执行状态直接关闭 | 阻断 |
| DB-AT-50 | 备份失败或恢复核对失败后标记验证成功 | 阻断并保留失败证据 |

每个场景至少保留初始化数据、SQL或接口、错误、事务前后数据、审计、状态历史和库存流水证据。

---

## 27. 分阶段实施

DB-01冻结本文档；DB-02实现系统、基础资料和准入；DB-03实现采购收货验收；DB-04实现批次库存；DB-05实现销售占用和出库；DB-06实现质量事件；DB-07实现运输签收和广东Mock；DB-08实现演示、备份和恢复。

合并回main最低条件：文档冻结、新基线可从空库执行、Drug模块适配、后端编译和当前阶段测试通过、没有误改上位冻结文档。

---

## 28. 冻结决策与后续实施事项

### 28.1 已采用的 Demo 设计默认值

以下内容不再阻塞文档冻结：

1. MySQL 8.4.10 LTS、InnoDB、`utf8mb4`、`utf8mb4_0900_ai_ci`；
2. 严格 SQL Mode、`REPEATABLE-READ`、数据库会话时区 `+00:00`；
3. nullable unique marker 的单连接和双连接并发唯一性已验证；
4. 采购和销售保留演示金额但不形成财务账；
5. 首版一张销售订单只建立一张当前出库任务；
6. 首版只支持整条库存余额冻结；
7. 质量冻结影响 ACTIVE 占用时采用 `BLOCKED_BY_QUALITY`；
8. 一个 acceptance_item 的合格数量首版一次性进入一个库位；
9. “未采集、未生成、未锁定、可用”采用明确的无记录或派生表达，不创建空业务记录；
10. 人工库存调整继续保持范围外；
11. 旧本地测试数据允许放弃；
12. 51 张表按 M1、M2、M3 分阶段建立；
13. 首版使用编号 SQL，不强制引入 Flyway；
14. 核心业务不使用普通删除。

### 28.2 三文档交叉检查结果

当前分支中三份文件的自动交叉检查已经完成：

1. `BUSINESS_STATE_MACHINE.md` v1.1 的 SM-01～SM-18；
2. `ROLE_PERMISSION_MATRIX.md` v1.1 的 SM-01～SM-18动作和角色；
3. 本文档第18章的表、字段、代码和权限动作。

检查已经证明：

- 18个编号连续且对象一致；
- 状态机中的每个核心状态有数据库表达；
- 权限矩阵中的每个转换动作有数据库事务或记录；
- SM-08不保存冻结；
- SM-15不保存上传状态；
- SM-16不保存本地核验状态；
- SM-18明确备份失败和恢复失败；
- 不存在旧状态语义残留。

### 28.3 冻结后实施阶段确认

以下事项在对应 Goal 或 DDL 阶段确认，不阻塞设计冻结：

- 药品经营分类代码集和范围数据字典；
- 过期任务频率；
- 附件存储；
- 审计 JSON 脱敏白名单；
- Java、JDBC、MyBatis-Plus UTC配置；
- 备份工具和目录；
- 数据库账号拆分；
- 51张表在SQL文件中的拆分；
- 受控更正实际开放对象；
- Flyway引入时点。

### 28.4 正确实施顺序

```text
冻结三份设计文档
→ 生成 DDL
→ 空库执行与约束验证
→ 适配 Drug 模块
→ 实现业务切片
→ 执行数据库、接口和权限验收
```

DDL、代码适配和测试是冻结后的实施验收条件，不是设计文档冻结前置条件。

## 29. 依据与声明

官方来源：

- 国家市场监督管理总局《药品经营质量管理规范》
  https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/bgt/art/2023/art_bc07ffdb7a1c4e46be371ac5a4a65f9c.html
- 国家市场监督管理总局《药品经营和使用质量监督管理办法》
  https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/fgs/art/2023/art_db526cfcd7204874b8b23297fa3b02dc.html
- 广东省药品监督管理局药品批发企业储存运输管理若干规定
  https://mpa.gd.gov.cn/gkmlpt/content/4/4191/post_4191999.html
- MySQL InnoDB、锁定读取、锁、死锁和时间类型
  https://dev.mysql.com/doc/refman/8.4/en/innodb-introduction.html
  https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html
  https://dev.mysql.com/doc/refman/8.4/en/innodb-locks-set.html
  https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlocks.html
  https://dev.mysql.com/doc/refman/8.4/en/date-and-time-types.html

本文档不构成法律意见或药监验收结论，不表示系统已完成计算机系统验证，不可直接用于真实药品经营。正式商业化前必须结合真实企业SOP、人员、经营范围和届时有效规则重新设计和验证。

---

## 30. 冻结前自审清单

### 已通过

- [X] 范围未扩大；
- [X] BF-01 至 BF-18 全部映射；
- [X] 51 张候选表数量和里程碑不变；
- [X] 上位状态机引用更新为 v1.1；
- [X] 上位权限矩阵引用更新为 v1.1；
- [X] SM-06 收货中、待处理和取消已映射；
- [X] SM-07 待质量处理和部分合格已映射；
- [X] SM-08 质量结论与 SM-14 冻结完全分离；
- [X] SM-09 BLOCKED_BY_QUALITY 已映射；
- [X] SM-11 复核失败回退和新尝试已映射；
- [X] SM-12 EXCEPTION_PROCESSING 已映射；
- [X] SM-13 DISPOSITION_APPROVED 和 EXECUTING 已映射；
- [X] SM-15 未采集采用无有效记录表达，不包含上传状态；
- [X] SM-16 未生成采用无任务记录表达，不包含本地核验状态；
- [X] SM-18 备份失败、核对中和恢复失败已映射；
- [X] 权限动作编号写入状态映射表；
- [X] 合格入库 source_event_key、活动冻结 active_marker 已保留；
- [X] MySQL环境、UTC、CHECK和marker并发验证已完成；
- [X] 数据库验收场景扩展到 DB-AT-01～DB-AT-50；
- [X] 核心记录不普通删除；
- [X] 人工库存调整继续保持范围外。

### 文档冻结前尚未通过

- [x] 三份文件已运行最终自动交叉检查；
- [x] 当前文件已在仓库内运行 `git diff --check`；
- [x] 三份文件已完成人工差异审查。

### 冻结后实施验收

- [ ] 51 张表尚未转成 DDL；
- [ ] DDL 尚未在空库执行；
- [ ] Drug 模块尚未适配；
- [ ] 数据库、权限和接口验收尚未执行；
- [ ] 后端编译和自动化测试尚未执行。

> 三文档交叉检查和提交前审查已完成，本文件进入 `v1.0 / 冻结基线`。

---

**文档结束**
