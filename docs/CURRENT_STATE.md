# 项目当前状态基线

## 1. 文档信息

| 项目 | 内容 |
| --- | --- |
| 文档用途 | 记录 `pharma-erp-demo` 在 Goal 1.1 审计时可以由仓库证据确认的现状，作为后续需求、测试、权限、审计和业务模块开发的事实基线。 |
| 审计日期 | 2026-07-18（Asia/Shanghai） |
| 审计范围 | Git 历史、项目规则、目录结构、Maven 配置、Java 源码、Spring 配置、SQL、测试、前端/CI/部署资产及本地可执行的编译测试。 |
| 当前分支 | `main` |
| 基线提交 | `cad7ff6 docs: add Goal 1 documentation placeholders` |
| 远程跟踪引用 | 审计开始时，本地 `HEAD`、本地记录的 `origin/main` 和 `origin/HEAD` 均指向 `cad7ff6`。本次没有执行 `git fetch`，因此没有独立验证远端服务器是否还有更新。 |
| 主要信息来源 | `AGENTS.md`、`backend/pom.xml`、`backend/src/`、`sql/`、Git 命令结果及 Maven 命令结果。 |
| 审计限制 | 未启动长期运行的应用，未连接或修改 MySQL，未执行 SQL，未调用真实 HTTP 接口，未进行前端联调，也未进行正式法规或 GSP 符合性判断。 |

### 1.1 结论使用规则

本文严格区分以下证据层级：

- **代码存在**：仓库中能找到实现，但不代表它已经运行成功。
- **编译通过**：Java 源码能被当前 Maven/JDK 环境编译，但不代表接口和数据库可用。
- **自动化测试通过**：只有测试实际覆盖到的行为才算通过；空的上下文测试不能证明业务接口正确。
- **运行验证**：需要真正启动应用并调用接口；本次未执行。
- **数据库验证**：需要在明确的测试数据库中执行或查询；本次未执行。
- **未发现**：在本次完整仓库范围内未找到实现，不等于外部仓库或未提供环境中一定不存在。

### 1.2 Git 基线

审计开始前执行的 Git 检查结果：

- `git status --short` 无输出，工作区干净，不存在已跟踪修改或未跟踪文件。
- 当前分支为 `main`。
- `HEAD`、本地记录的 `origin/main` 和 `origin/HEAD` 均指向 `cad7ff6`。
- `git branch --all` 只显示本地 `main` 及其 `origin/main` 远程跟踪引用；未发现 tag 或 stash。
- 仓库当前只有 6 条可见提交记录：

| 提交 | 提交说明 | 从提交信息和变更可确认的概要 |
| --- | --- | --- |
| `cad7ff6` | `docs: add Goal 1 documentation placeholders` | 添加 7 个 Goal 1 空文档占位文件。 |
| `620ab8b` | `feat: add drug master CRUD` | 添加药品档案相关代码；实际能力仍以本文源码审计为准。 |
| `58393e6` | `chore: update local database name` | 将仓库配置使用的数据库名统一为 `pharma_erp`。 |
| `3c6bf0e` | `docs: update codex project instructions` | 更新项目长期规则。 |
| `5b9897c` | `fix gitignore env templates` | 修正本地环境文件与模板的忽略规则。 |
| `672a6f7` | `init backend skeleton` | 初始化后端骨架。 |

本文和 `TECH_DEBT.md` 是 Goal 1.1 执行后产生的预期未提交变化；它们不属于上述基线提交。

### 1.3 Goal 1.1 范围和完成标准

本 Goal 的唯一交付物是：

1. 填写已跟踪的 `docs/CURRENT_STATE.md`，建立事实基线。
2. 新增 `docs/TECH_DEBT.md`，记录有证据的技术债和建议方向。

本 Goal 不修改 Java、SQL、YAML、XML、Maven 配置、其他业务文件或其他 Goal 1 占位文档，也不创建提交或执行 push。完成标准是：关键结论有仓库或命令证据，事实/推断/未确认项明确区分，两份文档相互一致，最终 Git 变化仅包含上述两个目标文件。

## 2. 项目定位

根据 `AGENTS.md`：

- 项目面向中国大陆小型药品批发企业，目标是建设一个可演示、可试用的 ERP MVP。
- 项目强调供应商/客户资质、商品首营、批号效期、采购验收、出库复核、库存流水、销售流向、审批和操作留痕等药品批发特点。
- 规划技术形态是单体架构、前后端分离；后端使用 Java/Spring Boot，前端规划使用 Vue 3/Element Plus。
- 明确不规划微服务、SaaS 多租户、复杂工作流引擎和复杂财务系统。

以上是**建设目标和范围约束**，不是当前已经完成的功能。根据本次审计证据，项目当前更准确的阶段是“后端原型”，尚不能称为完整 MVP、可试运行系统或可商用系统。

证据：`AGENTS.md` 第 1～4 节、`backend/pom.xml`。

## 3. 仓库结构

```text
pharma-erp-demo/
├── AGENTS.md                 项目长期规则和 P0 边界
├── backend/
│   ├── pom.xml               Spring Boot Maven 配置
│   └── src/
│       ├── main/java/        后端主代码
│       ├── main/resources/   Git 跟踪的 application.yml
│       └── test/java/        当前仅有一个上下文测试
├── docs/                     Goal 1 文档骨架与基线文档
├── frontend/                 本地空目录，无 Git 跟踪的前端工程
└── sql/
    └── 001_create_drug_table.sql
```

补充说明：

- Git 当前跟踪 34 个文件，其中后端主代码 Java 文件 17 个、测试 Java 文件 1 个。
- `frontend/` 没有任何文件；Git 不保存空目录，因此全新克隆仓库时不会得到该目录。
- `.idea/`、`backend/target/` 和 `backend/src/main/resources/application-local.yml` 存在于本次审计工作机，但被 `.gitignore` 忽略，不属于仓库交付内容。
- 审计开始时 11 个 `docs/*.md` 均为 0 字节占位文件；Goal 1.1 只填写本文并新增 `TECH_DEBT.md`，其余占位文件保持不变。
- 仓库根目录未发现 `README.md`；已跟踪的 `docs/README.md` 仍为空占位文件。

证据：`git ls-files`、`find`、`wc -c docs/*.md`、`.gitignore`。

## 4. 技术栈

| 技术 | 当前版本或状态 | 仓库证据 |
| --- | --- | --- |
| Java | 项目要求 Java 17；审计环境为 Java 17.0.17 | `backend/pom.xml` 的 `java.version`；`mvn --version` |
| Maven | 使用 Maven 构建；审计环境为 Maven 3.9.16；仓库未发现 Maven Wrapper | `backend/pom.xml`；仓库文件清单；`mvn --version` |
| Spring Boot | 3.3.5 | `backend/pom.xml` 的 parent |
| Spring MVC | 已引入 Web Starter | `backend/pom.xml` 的 `spring-boot-starter-web` |
| 参数校验 | 已引入 Jakarta Validation | `backend/pom.xml` 的 `spring-boot-starter-validation`；Drug DTO 注解 |
| MyBatis-Plus | 3.5.9，包含 Spring Boot 3 Starter 与 JSQLParser | `backend/pom.xml` |
| 数据库 | 规划并配置 MySQL；驱动为运行时依赖 | `backend/pom.xml`、`backend/src/main/resources/application.yml` |
| API 文档 | Knife4j 4.5.0、Springdoc 配置已启用 | `backend/pom.xml`、`application.yml` |
| Lombok | 已引入，可选依赖 | `backend/pom.xml` |
| 测试 | Spring Boot Test/JUnit 5；仅 1 个 `contextLoads` 测试 | `backend/pom.xml`、`PharmaErpApplicationTests.java` |
| 认证授权 | `AGENTS.md` 规划后续使用 Sa-Token；POM 和源码中尚未发现实现 | `AGENTS.md`、`backend/pom.xml`、Java 源码检索 |
| 前端 | 规划 Vue 3 + Element Plus；当前仓库没有前端工程文件 | `AGENTS.md`、`frontend/` 文件检查 |

MySQL 驱动的具体版本由 Spring Boot parent 的依赖管理决定，当前 POM 没有单独写死该版本；本文不根据记忆推测版本号。

## 5. 当前架构和代码分层

### 5.1 架构形态

- 启动类 `com.fuhaha.pharmaerp.PharmaErpApplication` 使用标准 `@SpringBootApplication`。
- 当前为单个 Spring Boot Maven 工程，属于单体后端原型。
- `AGENTS.md` 规划前后端分离，但当前只有后端源码，尚未形成前后端联调架构。
- 数据访问主要使用 MyBatis-Plus `BaseMapper`；当前未发现 Mapper XML。

### 5.2 包结构

```text
com.fuhaha.pharmaerp
├── common
│   ├── exception             业务异常和全局异常处理
│   ├── page                  分页返回模型
│   └── result                统一返回模型
├── config                    MyBatis-Plus 分页配置
└── modules
    ├── system/controller     健康检查
    └── master/drug           药品档案模块
```

`AGENTS.md` 中提到的 `quality`、`purchase`、`stock`、`sales` 等是建议模块结构；本次仓库文件清单中尚未发现这些模块实现。

### 5.3 分层关系

```text
HTTP 请求
  → Controller：接收参数、触发校验、返回 Result
  → Service：执行业务校验、状态变化和事务
  → Mapper：通过 MyBatis-Plus 访问数据库
  → Entity：映射数据库表

DTO：接收请求字段
VO：控制返回给调用方的字段
Enum：集中定义业务状态代码
```

药品模块基本遵循上述分层。当前 Entity 与 DTO/VO 分离，没有直接把 Entity 作为 Controller 返回值。

## 6. 已实现功能概览

“已验证程度”只描述本次取得的最强证据，不扩大解释。

| 功能 | 当前状态 | 证据文件 | 已验证程度 | 说明 |
| --- | --- | --- | --- | --- |
| Spring Boot 启动骨架 | 已实现 | `PharmaErpApplication.java` | 有限自动化验证：仅 1 个 `contextLoads` 测试在沙箱外通过 | 沙箱内因 JVM/Mockito 运行限制失败；沙箱外同一命令成功；未验证 HTTP、Mapper、MySQL、DDL 和 Drug 业务行为，也未做长期启动验证。 |
| 统一返回 `Result<T>` | 已实现 | `common/result/Result.java` | 已通过编译但未运行 | 提供 `code/message/data` 及成功、失败工厂方法。 |
| 分页结果 `PageResult<T>` | 已实现 | `common/page/PageResult.java` | 已通过编译但未运行 | 提供记录、总数、页码和页大小。 |
| 业务异常与全局异常处理 | 部分实现 | `BizException.java`、`GlobalExceptionHandler.java` | 已通过编译但未运行 | 已覆盖业务异常、参数校验和兜底异常；HTTP 状态和日志仍有缺口。 |
| MyBatis-Plus 分页 | 已实现配置 | `config/MyBatisPlusConfig.java` | 已通过编译但未运行 | 注册 MySQL 分页拦截器；真实分页 SQL 未验证。 |
| 健康检查 | 存在实现 | `modules/system/controller/HealthController.java` | 已通过编译但未运行 | `GET /health` 返回固定成功信息，不检查数据库。 |
| 药品档案新增 | 存在实现 | `DrugController.java`、`DrugServiceImpl.java` | 已通过编译但未运行 | 未进行 HTTP、数据库或业务验收测试。 |
| 药品档案更新 | 存在实现 | 同上 | 已通过编译但未运行 | 公开更新 DTO 不允许修改 `drugCode`。 |
| 药品档案详情和分页 | 存在实现 | 同上 | 已通过编译但未运行 | 分页支持多个筛选条件。 |
| 药品启用/停用 | 部分实现 | `DrugStatusEnum.java`、`DrugServiceImpl.java` | 已通过编译但未运行 | 只有启用/停用状态，尚未关联首营或质量审核。 |
| `drug` 表 DDL | 存在脚本 | `sql/001_create_drug_table.sql` | 存在实现但未验证 | 未连接数据库，无法确认脚本已执行或实际表结构一致。 |

## 7. 药品档案模块详细现状

### 7.1 已存在的类

| 分层 | 文件 | 职责 |
| --- | --- | --- |
| Controller | `modules/master/drug/controller/DrugController.java` | 暴露新增、更新、详情、分页、启用和停用接口。 |
| DTO | `DrugCreateDTO.java` | 新增请求字段和 Bean Validation 规则。 |
| DTO | `DrugUpdateDTO.java` | 更新请求字段；不包含药品编码和状态。 |
| DTO | `DrugPageQueryDTO.java` | 页码、页大小和查询筛选条件。 |
| Entity | `entity/Drug.java` | 映射 `drug` 表，包含自增主键和逻辑删除字段。 |
| Enum | `enums/DrugStatusEnum.java` | 定义 `ENABLED` 与 `DISABLED`。 |
| Mapper | `mapper/DrugMapper.java` | 继承 `BaseMapper<Drug>`，没有自定义方法。 |
| Service | `service/DrugService.java` | 定义 6 项药品档案操作。 |
| Service 实现 | `service/impl/DrugServiceImpl.java` | 业务校验、事务、查询条件、状态变化和 VO 转换。 |
| VO | `vo/DrugVO.java` | 对外返回药品字段、状态名称和时间。 |

以上相对路径均位于：
`backend/src/main/java/com/fuhaha/pharmaerp/modules/master/drug/`。

### 7.2 现有接口

| 请求方式 | 地址 | 代码证据 |
| --- | --- | --- |
| `POST` | `/master/drugs` | `DrugController.create` |
| `PUT` | `/master/drugs/{id}` | `DrugController.update` |
| `GET` | `/master/drugs/{id}` | `DrugController.getDetail` |
| `GET` | `/master/drugs/page` | `DrugController.page` |
| `PUT` | `/master/drugs/{id}/enable` | `DrugController.enable` |
| `PUT` | `/master/drugs/{id}/disable` | `DrugController.disable` |

当前没有删除接口，因此准确描述是“新增、查询、更新和启停”，不能仅根据提交信息把它认定为已验证的完整 CRUD。

### 7.3 已有行为和校验

- 创建 DTO 对药品编码、名称、通用名、批准文号、剂型、规格、生产厂家、基本单位和储存条件设置非空和长度校验。
- 更新 DTO 对核心字段设置非空和长度校验，但不暴露药品编码和状态字段。
- 分页默认第 1 页、每页 10 条，限制最大每页 100 条；可按编码、名称、通用名、批准文号、厂家和状态筛选。
- Service 对核心非空字段做二次检查，写入前清理普通首尾空格，空备注转换为 `null`。
- 创建时先检查药品编码；DDL 定义了数据库唯一键，只有该脚本已在目标数据库正确执行时，它才构成最终数据约束。新记录由 Service 明确设为 `DISABLED`。
- 创建、更新、启用和停用方法使用 `@Transactional(rollbackFor = Exception.class)`。
- 启用和停用具备简单幂等处理：已经处于目标状态时直接返回。
- 分页按创建时间和 ID 倒序。

证据：3 个 Drug DTO、`DrugServiceImpl.java`、`DrugStatusEnum.java`。

### 7.4 当前业务边界

- `enable` 只验证药品核心字段完整，不读取首营审批、质量审核或证照数据。
- 只有 `ENABLED/DISABLED` 两种状态，无法从当前代码表达待审核、审核通过或驳回。
- 已启用档案仍可通过更新接口修改批准文号、规格、生产厂家等字段；当前没有变更审批或前后值留痕。
- 当前没有供应商、客户、采购、验收、批号库存、库存流水、销售或出库复核模块可与药品档案形成业务闭环。

`AGENTS.md` 对首营、审核和操作留痕提出了项目规则，但仓库中没有正式法规原文或已确认的合规矩阵。因此上述差距属于**项目规划差距和合规待核验事项**，不是本文给出的法律结论。

### 7.5 验证分层

| 验证层级 | 当前结论 |
| --- | --- |
| 代码存在 | 已确认。 |
| Maven 编译 | 已通过。 |
| 药品自动化测试 | 未发现；唯一测试没有调用药品模块。 |
| 数据库连接与 CRUD | 未验证。 |
| 真实 HTTP 调用 | 未验证。 |
| Knife4j 调用 | 未验证。 |
| 前端联调 | 未验证。 |
| 业务验收 | 未验证。 |

## 8. 公共基础能力现状

| 能力 | 当前状态 | 证据与说明 |
| --- | --- | --- |
| 统一返回 | 已实现代码 | `Result.java` 提供 `code/message/data`。 |
| 业务异常 | 已实现代码 | `BizException` 默认 code 为 400。 |
| 全局异常 | 部分实现 | `GlobalExceptionHandler` 有多类处理器；业务异常处理未明确改变 HTTP 状态。 |
| 分页 | 已实现代码和配置 | `PageResult.java`、`MyBatisPlusConfig.java`。 |
| 参数校验 | 已实现于 Drug DTO/Controller | 使用 `@Valid`、`@NotBlank`、`@Size`、`@Min`、`@Max`。 |
| 业务日志 | 未发现 | 未发现 Service 主动记录业务操作；兜底异常没有记录异常堆栈。 |
| 登录 | 未发现 | POM 和源码未发现 Sa-Token 或其他登录实现。 |
| 权限 | 未发现 | Controller 未发现角色或权限限制。 |
| 操作审计 | 未发现 | 未发现 `audit_log` 实现、当前操作人或字段变更前后值。 |
| 数据字典 | 未发现 | 当前枚举只覆盖药品启停状态。 |
| 文件上传 | 未发现 | 未发现上传 Controller、存储配置或附件表。 |
| 数据库迁移 | 未发现 | 未发现 Flyway/Liquibase；只有手工 SQL 文件。 |
| 环境隔离 | 部分存在但未形成仓库方案 | 有被忽略的 `application-local.yml`，但无 test/prod 配置和可提交模板。 |
| API 文档 | 存在依赖和配置 | Springdoc/Knife4j 已启用，但端点和页面未做 HTTP 验证。 |
| CI | 未发现 | 仓库中未发现 GitHub Actions、GitLab CI、Jenkins 等配置。 |

## 9. 数据库与 SQL 现状

### 9.1 脚本清单

仓库当前仅有：

- `sql/001_create_drug_table.sql`

它只定义 `drug` 一张表，没有初始化演示数据。文件名前缀 `001_` 表示人工编号，仓库中没有工具证明它会自动按顺序执行。

### 9.2 `drug` 表关键设计

| 项目 | 当前定义 |
| --- | --- |
| 主键 | `id BIGINT AUTO_INCREMENT` |
| 唯一约束 | `uk_drug_code (drug_code)` |
| 普通索引 | `drug_name`、`generic_name`、`approval_no`、`manufacturer`、`status`、`deleted` |
| 状态 | `VARCHAR(20)`，默认 `DISABLED` |
| 时间 | `created_at` 默认当前时间；`updated_at` 使用 `ON UPDATE CURRENT_TIMESTAMP` |
| 逻辑删除 | `deleted TINYINT`，默认 0 |
| 引擎与字符集 | InnoDB、utf8mb4 |

### 9.3 Entity 对应关系

- `Drug` 使用 `@TableName("drug")`、自增 `@TableId` 和 `@TableLogic`。
- Entity 的字段与 DDL 的 15 个列在命名和主要类型上明显对应。
- Java 驼峰字段依赖 `application.yml` 中 `map-underscore-to-camel-case: true` 映射到下划线列。
- DTO 长度限制与 SQL 中相应 `VARCHAR` 长度一致。
- Java 枚举代码与 SQL 注释中的 `ENABLED/DISABLED` 对应。

### 9.4 当前缺口和限制

- 未发现数据库迁移工具、schema history、回滚说明或脚本校验和。
- 脚本没有 `CREATE DATABASE`、`USE pharma_erp` 或 `IF NOT EXISTS`；执行目标和幂等策略未由脚本决定。
- 表和 Entity 均没有 `version/@Version`、`created_by`、`updated_by`。
- 数据库状态字段没有 CHECK 约束，正常 Service 路径使用枚举，但数据库层不能阻止其他写入方写入未知状态。
- 已配置逻辑删除，但没有公开删除接口；软删除后药品编码是否永久不可复用尚未形成业务规则。
- 本次没有连接 MySQL，无法确认数据库是否已经创建、脚本是否执行、实际表结构是否与仓库一致。

## 10. 配置现状与安全边界

### 10.1 Git 跟踪配置

`backend/src/main/resources/application.yml`：

- 端口为 8080，应用名为 `pharma-erp`。
- 数据源指向 `127.0.0.1:3306/pharma_erp`。
- 提交配置使用 `root` 用户，密码为空。
- 配置 MyBatis-Plus 驼峰转换和逻辑删除。
- Springdoc 与 Knife4j 无条件启用。

这只能视为当前本地开发默认值，仓库中没有 dev/test/prod 的明确部署策略。

### 10.2 被忽略的本地配置

审计工作机存在 `backend/src/main/resources/application-local.yml`：

- 该文件被 `.gitignore` 排除，Git 历史中未发现此路径。
- 自动检查只确认其数据库密码字段非空，具体值没有在审计输出或文档中回显、记录，也未确认该值是否为仍然有效的真实凭据。
- Maven 资源阶段显示复制 2 个主资源；`target/classes/application-local.yml` 与源本地文件一致。
- 因此已确认构建目录含本地配置。若未来打包，配置可能进入制品；本次未执行 package，JAR 内容尚未验证。

## 11. 构建与测试状态

### 11.1 审计环境

- Maven 3.9.16
- Java 17.0.17（Ubuntu OpenJDK）
- Linux/WSL2

环境证据：`mvn --version`。

### 11.2 执行结果

| 命令 | 结果 | 能证明什么 | 不能证明什么 |
| --- | --- | --- | --- |
| `mvn -f backend/pom.xml -DskipTests compile` | `BUILD SUCCESS` | 当前 Maven 增量编译成功。 | 不证明业务运行或数据库可用。 |
| 受限沙箱内 `mvn -f backend/pom.xml test` | `BUILD FAILURE` | 失败原因是沙箱禁止网络接口/Mockito Byte Buddy 自附加 JVM。 | 该失败不是业务断言失败，也不能据此判定项目测试坏。 |
| 经批准在沙箱外重试同一 test 命令 | `BUILD SUCCESS`；1 test，0 failures，0 errors | 默认 profile 下 Spring 上下文可加载。 | 不证明 HTTP、Mapper、MySQL、DDL、Drug CRUD 或业务规则正确。 |

唯一测试为：

- `backend/src/test/java/com/fuhaha/pharmaerp/PharmaErpApplicationTests.java`
- 使用 `@SpringBootTest`。
- 测试方法 `contextLoads()` 没有断言、HTTP 请求、Mapper 调用或 SQL 查询。
- 日志显示没有激活 profile，使用 `default` profile；没有证据表明测试取得了真实数据库连接。

## 12. 已完成、部分完成和未开始

### 12.1 已有明确代码和验证证据

- Spring Boot/Maven 后端骨架能够在当前环境编译。
- 默认 profile 的 Spring 上下文测试通过。
- 统一返回、分页模型、异常类和 MyBatis-Plus 分页配置已存在并通过编译。
- Drug 模块具备完整的 Controller/DTO/Service/Mapper/Entity/VO/Enum 文件结构并通过编译。
- `drug` DDL、唯一键、索引、时间和逻辑删除定义可由 SQL 静态确认。

### 12.2 已有部分实现但未形成闭环

- 药品档案存在新增、查询、更新和启停代码，但没有业务自动化测试、真实 HTTP 或数据库验证。
- 异常处理已建立框架，但 HTTP 状态语义、错误分类和服务端异常日志不完整。
- Knife4j/OpenAPI 已配置，但文档端点尚未做冒烟测试。
- 本地配置覆盖方式存在，但环境隔离、测试数据库和敏感配置管理没有形成可复制方案。

### 12.3 仓库中尚未发现实现

- 供应商、客户和证照档案。
- 商品首营、资质审核和审批记录。
- 采购订单、到货验收和采购入库。
- 仓库、货位、`stock_batch` 和 `stock_movement`。
- 销售订单、出库复核和销售流向。
- 批号追溯、资质/效期预警。
- 登录、角色权限、操作审计和修改前后值留痕。
- Vue 前端工程。
- CI、部署配置、监控、备份和恢复方案。

这些项目中部分出现在 `AGENTS.md` 的未来规划里，但不能因此写成“已有骨架”或“已经完成”。

## 13. 前端、CI、权限、审计和部署现状

| 领域 | 当前仓库证据 | 结论 |
| --- | --- | --- |
| 前端 | `frontend/` 为空；未发现 `package.json`、Vite 或 Vue 源码 | 尚未开始仓库内前端实现。 |
| CI | 未发现 `.github/workflows`、GitLab CI、Jenkinsfile 等 | 仓库内没有自动编译/测试流水线。 |
| 登录权限 | POM 和 Java 源码未发现认证授权组件或权限注解 | 尚未实现。 |
| 审计 | 未发现 `audit_log`、当前操作人或前后值记录 | 尚未实现。 |
| 部署 | 未发现 Dockerfile、Compose、Kubernetes、部署脚本或运行手册 | 尚未形成可重复部署方案。 |
| 备份恢复 | 未发现数据库备份、恢复或演练说明 | 尚未设计或至少未提交到仓库。 |
| 监控就绪 | `/health` 只返回固定内容，无 Actuator 或数据库 readiness | 只能作为简单存活接口代码，未验证实际部署效果。 |

## 14. 当前项目阶段结论

当前项目应归类为：**后端原型**。

判断依据：

1. 已有可编译的 Spring Boot 后端骨架和一个药品档案纵向代码样例。
2. 唯一自动化测试只验证 Spring 上下文加载。
3. 未验证真实数据库、HTTP 接口、事务和业务规则。
4. P0 所需的大多数药品批发模块尚未在仓库中出现。
5. 前端、认证授权、审计、CI 和部署能力尚未实现。

因此，本项目当前不能表述为：

- 已完成药品 ERP；
- 已经符合 GSP；
- 已通过药品监管验收；
- 可以正式商用；
- 已具备试运行条件。

## 15. 未确认事项

以下内容无法从当前仓库和本次安全检查中确认：

1. `pharma_erp` 数据库是否已实际创建。
2. `001_create_drug_table.sql` 是否已执行，以及实际表结构是否与脚本一致。
3. Drug 接口是否曾通过 curl、Knife4j、Apifox 或前端真实调用。
4. 应用在当前机器上长期启动后，`/health` 和 `/doc.html` 是否可访问。
5. 本地配置中的数据库是否仅为开发库；本次没有使用或验证该凭据。
6. 是否存在未提供的独立前端仓库、部署仓库或 CI 平台配置。
7. Git 远端服务器是否有本次未 fetch 的更新或服务器端规则。
8. 目标企业所在省份及具体监管口径。
9. 目标企业是否经营冷藏冷冻药品、特殊管理药品或其他特殊品类。
10. 供应商、客户、商品首营、证照和数据留存的详细业务规则及正式法规依据。
11. 演示环境、演示账号、初始化数据及演示数据重置方案。
12. 正式部署目标、数据库版本、备份周期、恢复目标和日志留存要求。

涉及业务或法规的问题应在后续 `OPEN_QUESTIONS.md`、`URS.md`、`COMPLIANCE_MATRIX.md` 等 Goal 中确认，不能用技术推测代替。
