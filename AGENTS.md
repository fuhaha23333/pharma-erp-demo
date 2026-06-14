# AGENTS.md

## 1. 项目背景

本项目是一个小型药品批发 ERP Demo，目标是先完成一个可演示、可试用的 MVP。

系统面向中国大陆小型药品批发企业，第一版重点不是做大型商业 ERP，而是体现药品批发业务的核心流程和 GSP 合规思想。

本项目不是普通进销存。药品批发 ERP 除了采购、销售、库存数量，还必须关注：

1. 供应商资质；
2. 客户资质；
3. 商品首营；
4. 证照有效期；
5. 药品批号；
6. 药品效期；
7. 采购验收；
8. 出库复核；
9. 库存流水；
10. 销售流向；
11. 审批记录；
12. 操作留痕；
13. 质量状态；
14. 批号追溯。

---

## 2. 技术栈

后端：

* Java 17
* Spring Boot 3
* Maven
* MyBatis-Plus
* MySQL
* Knife4j / OpenAPI
* Validation
* Lombok
* Sa-Token，后续登录权限模块再引入或启用

前端：

* Vue 3
* Element Plus

架构：

* 单体架构
* 前后端分离
* 不做微服务
* 不做 SaaS 多租户
* 不做复杂工作流引擎
* 不做复杂财务系统
* 不引入当前阶段用不到的复杂中间件

---

## 3. 项目目录说明

项目根目录：

```text
pharma-erp-demo/
├── AGENTS.md
├── backend
├── docs
├── frontend
└── sql
```

目录职责：

```text
AGENTS.md  给 Codex / AI 编程助手看的项目长期规则
backend    后端 Spring Boot 项目
docs       项目规划、功能清单、数据库设计、Codex 规则
frontend   前端 Vue 项目，后续开发
sql        数据库建表脚本、初始化数据脚本
```

后端包名：

```text
com.fuhaha.pharmaerp
```

后端建议模块结构：

```text
modules/system      系统模块，如用户、角色、权限、健康检查
modules/master      基础档案，如药品、供应商、客户
modules/quality     质量管理，如首营审批、证照审核
modules/purchase    采购模块，如采购订单、验收入库
modules/stock       库存模块，如批号库存、库存流水
modules/sales       销售模块，如销售订单、出库复核
```

---

## 4. P0 范围边界

第一版 P0 聚焦以下能力：

1. 基础档案；
2. 资质证照；
3. 首营审批；
4. 采购验收入库；
5. 批号库存；
6. 销售出库；
7. 库存流水；
8. 批号追溯；
9. 资质 / 效期预警；
10. 登录和角色权限。

详细功能清单见：

```text
docs/P0_FEATURES.md
```

---

## 5. 数据库命名与设计原则

当前 MySQL 数据库名称统一为：

```text
pharma_erp
```

不要再使用：

```text
pharma_erp_demo
```

数据库规则：

1. 表名使用小写下划线；
2. 字段名使用小写下划线；
3. Java 属性使用小驼峰；
4. MyBatis-Plus 开启下划线转驼峰；
5. SQL 脚本统一放在 `sql` 目录；
6. 业务表原则上使用逻辑删除，不做物理删除；
7. 所有金额字段使用 `BigDecimal`，数据库使用 `decimal`；
8. 日期时间字段使用 `LocalDate` 或 `LocalDateTime`；
9. 所有业务状态使用枚举，不要写魔法字符串。

核心命名约定：

```text
stock_batch     批号库存表，表示当前库存还剩多少
stock_movement  库存流水表，表示库存为什么发生变化
```

库存流水统一命名为：

```text
stock_movement
```

不要使用：

```text
stock_transaction
```

---

## 6. 药品 ERP 核心业务规则

1. 所有业务单据采用主表 + 明细表结构。
2. 库存必须按“药品 + 批号 + 效期 + 仓库 + 货位 + 质量状态”管理。
3. 每次库存变化必须生成 `stock_movement` 库存流水。
4. 采购入库必须来自验收合格记录。
5. 销售出库必须经过出库复核。
6. 未审核通过的供应商不能采购。
7. 未审核通过的客户不能销售。
8. 未审核通过的商品不能采购和销售。
9. 证照过期应触发预警或业务限制。
10. 重要业务操作必须记录 `audit_log`。
11. 审批记录、库存流水、关键业务单据不能随意删除。

---

## 7. 后端分层规则

Controller：

* 接收 HTTP 请求；
* 做参数校验；
* 返回统一 Result；
* 不写复杂业务逻辑。

Service：

* 负责业务规则；
* 负责状态流转；
* 负责事务控制；
* 负责调用 Mapper。

Mapper：

* 负责数据库访问；
* 优先使用 MyBatis-Plus；
* 简单 CRUD 不写复杂 XML。

Entity：

* 对应数据库表。

DTO：

* 接收前端请求参数。

VO：

* 返回前端展示数据。

Enum：

* 表示业务状态；
* 禁止直接写魔法字符串。

---

## 8. 代码修改规则

每次开始任务前，必须先输出：

1. 当前任务目标；
2. 当前 Git 状态；
3. 准备修改哪些文件；
4. 准备新增哪些文件；
5. 是否需要新增 SQL；
6. 是否需要修改配置；
7. 风险点；
8. 测试方式。

在用户回复“确认执行”之前，不要修改代码。

每次任务结束后，必须输出：

1. 修改了哪些文件；
2. 为什么这样改；
3. 新增了哪些接口；
4. 新增了哪些 SQL；
5. 如何启动；
6. 如何测试；
7. 测试结果；
8. Java 新手应该理解哪些知识点；
9. 后续风险。

---

## 9. Git 规则

每个功能模块开始前，先执行：

```bash
git status
git branch
git log --oneline -5
```

工作区不干净时，不要直接开始新任务。

每完成一个小功能，建议提交一次。

不要提交：

1. 构建产物；
2. IDE 临时文件；
3. 本地环境配置；
4. 日志文件；
5. 敏感信息。

`.gitignore` 必须至少忽略：

```text
backend/target/
*.class
*.jar
*.war
.idea/
*.iml
.vscode/
.DS_Store
frontend/node_modules/
frontend/dist/
*.log
logs/
.env
.env.local
.env.*.local
application-local.yml
application-dev-local.yml
application-prod-local.yml
```

必须保留模板文件：

```text
.env.example
.env.template
*.example
*.template
```

---

## 10. 测试与验收规则

后端基础测试：

```bash
cd backend
mvn test
mvn spring-boot:run
```

基础访问地址：

```text
http://localhost:8080/health
http://localhost:8080/doc.html
```

每个后端接口完成后，必须说明：

1. 请求方式；
2. 请求地址；
3. 请求参数；
4. 返回结果；
5. 成功用例；
6. 失败用例；
7. 如何用 Knife4j、curl 或 Apifox 测试。

每次修改后，至少执行：

```bash
cd backend
mvn test
```

---

## 11. 学习要求

你不仅要完成代码，还要教我。

每完成一个接口，要解释：

1. Controller 做什么；
2. Service 做什么；
3. Mapper 做什么；
4. Entity / DTO / VO 分别做什么；
5. 为什么这里需要或不需要事务；
6. 这个接口对应哪个业务流程；
7. 这个接口可能出什么 bug；
8. Java 初学者应该掌握哪些知识点。

解释时要通俗，不要只说术语。

---

## 12. 严禁事项

1. 不要一次性生成多个大模块。
2. 不要绕过用户确认直接修改代码。
3. 不要随意删除现有文件。
4. 不要修改无关目录。
5. 不要提交 `backend/target`。
6. 不要提交 `.idea`。
7. 不要提交 `.env`。
8. 不要把业务状态写成魔法字符串。
9. 不要用 `double` 或 `float` 表示金额。
10. 不要把库存只设计成一个简单数量。
11. 不要把药品 ERP 做成普通进销存。
12. 不要引入当前阶段用不到的复杂技术。
13. 不要把 `stock_transaction` 和 `stock_movement` 当成两张表。
14. 不要在没有确认的情况下修改数据库结构。
15. 不要在没有确认的情况下推送 GitHub。

```
```
