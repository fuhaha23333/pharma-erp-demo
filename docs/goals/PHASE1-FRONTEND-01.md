# PHASE1-FRONTEND-01 第一阶段前端

## Goal

在 `frontend/` 建立 Vue 3、Vite、Element Plus 前端，以当前分支已经实现并记录在 `backend/PHASE1_API.md` 的接口为唯一联调契约。

## 输入

- `docs/DEMO_SCOPE.md` v1.2 第一阶段执行 Profile；
- `docs/BUSINESS_STATE_MACHINE.md` v1.2；
- `docs/ROLE_PERMISSION_MATRIX.md` v1.2；
- `docs/DATABASE_DESIGN_DEMO.md` v1.2 第一阶段实现映射；
- `backend/PHASE1_API.md`；
- 当前 Controller、DTO、VO 和权限编码。

## 范围

- 登录、退出和当前用户；
- 权限路由、菜单和按钮；
- 用户管理；
- 角色管理；
- 基础权限树；
- 供应商档案、资质附件元数据、提交和审核；
- 批号追溯、库存分布和生命周期事件；
- 统一 API 错误处理、UTC 时间转本地展示；
- 单元测试、生产构建和浏览器联调说明。

## 明确不包含

- 后端和数据库结构修改；
- Drug 原型修改；
- 文件内容上传和下载，当前只登记受控存储元数据；
- 采购、收货、验收、库存写入、销售和出库页面；
- M2 广东追溯码、质量事件和 M3 演示加固；
- 用前端隐藏按钮替代后端鉴权；
- 宣称完整 M1、GSP 合规或生产可用。

## 角色、状态与阻断

- `SUPER_ADMIN`：第一阶段全部权限；
- `ENTERPRISE_ADMIN`：系统管理及供应商、追溯只读；
- `PURCHASER`：供应商维护和提交；
- `QUALITY_HEAD`：供应商审核和追溯；
- 其他第一阶段内置角色按当前后端权限进入追溯页面。

供应商状态为 `DRAFT → UNDER_REVIEW → APPROVED / REJECTED`。提交人不能审核本人提交；驳回原因必填；必需资质和有效附件不完整时不能提交；停用角色和权限不能继续分配；互斥角色不能同时授予同一用户；追溯结果不可修改。

## 配置与数据

- 新增 Vite 开发代理和前端环境变量示例；
- 不修改数据库；
- HTTP Basic 凭据只保存在页面运行内存，刷新后重新登录；
- 服务端 UTC 时间按浏览器时区展示；
- 生产或远程演示必须通过 HTTPS 和反向代理访问后端。

## 测试

```bash
npm --prefix frontend run test
npm --prefix frontend run build
mvn -f backend/pom.xml test
```

## 完成条件

1. 六个页面模块可按真实权限访问；
2. 正常、参数错误、401、403、状态阻断和审核人冲突能显示明确反馈；
3. 前端不伪造不存在的统计、审批节点、上传结果或追溯事件；
4. 自动化测试和生产构建通过；
5. 文档记录启动、登录、联调和浏览器验收步骤；
6. 最终 Git 差异不包含构建产物、依赖目录、密钥或本地环境配置。

## 当前完成证据

当前状态为：代码实现和本地自动化验证完成，真实数据库与多角色浏览器联调待验收。

- `npm --prefix frontend run test`：5 个测试文件、13 个测试全部通过；
- `npm --prefix frontend run build`：TypeScript 类型检查和 Vite 生产构建通过；
- `mvn -f backend/pom.xml test`：15 个测试全部通过，0 失败、0 错误；
- Vite 开发服务器可在 `127.0.0.1:5173` 启动，`/` 和 `/login` 均返回 SPA 入口；
- `frontend/node_modules/` 和 `frontend/dist/` 均被 Git 忽略；
- 未修改数据库结构、迁移脚本或 Drug 原型。

当前环境没有取得可用的后端健康响应，也没有 Chromium/Playwright，因此真实账号登录、供应商跨角色审核和种子批号追溯仍需按 `frontend/README.md` 在可用联调环境中完成。该项是未验证证据，不应表述为已通过或已失败。
