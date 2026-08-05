# 第一阶段前端

本目录是药品批发 ERP 验证型 Demo 的第一阶段浏览器入口，技术栈为 Vue 3、Vite、TypeScript 和 Element Plus。

当前页面严格对应 `backend/PHASE1_API.md`：

- 登录和当前用户；
- 用户管理；
- 角色管理；
- 基础权限树；
- 供应商档案、资质、附件元数据、提交和审核；
- 药品批号只读追溯。

本前端不表示完整 M1 已经完成，不表示系统已通过 GSP 检查或可以承载真实经营数据。

## 1. 环境要求

- Node.js 20.19+ 或 22.12+；本次实际构建使用 Node.js 24.16.0；
- npm；
- 后端默认运行在 `http://127.0.0.1:8080`；
- 已按后端文档初始化数据库和演示管理员。

不要在任何 `.env`、源码、浏览器截图或提交记录中保存真实密码。

## 2. 本地启动

安装依赖：

```bash
npm --prefix frontend install
```

启动后端：

```bash
mvn -f backend/pom.xml spring-boot:run
```

启动前端：

```bash
npm --prefix frontend run dev
```

浏览器访问：

```text
http://127.0.0.1:5173
```

开发环境会把 `/api/**` 代理到 `VITE_DEV_PROXY_TARGET`，并移除 `/api` 前缀。可复制 `.env.example` 为不提交的 `.env.local` 修改目标地址：

```dotenv
VITE_API_BASE_URL=/api
VITE_DEV_PROXY_TARGET=http://127.0.0.1:8080
```

## 3. 认证边界

后端使用无状态 HTTP Basic。前端只在当前 JavaScript 运行内存中保存账号和密码，用于为每次 API 请求生成 `Authorization` 请求头：

- 不写入 `localStorage`；
- 不写入 `sessionStorage`；
- 不写入 Cookie；
- 不写入日志或错误提示；
- 刷新或关闭页面后需要重新登录。

生产或远程演示必须使用 HTTPS，否则 HTTP Basic 凭据可能在网络传输中暴露。

## 4. 权限边界

路由、菜单和按钮根据 `/system/auth/me` 返回的权限编码显示。前端控制只用于改善交互，后端 `@PreAuthorize` 和 Service 状态守卫始终是最终边界。

| 页面 | 进入权限 | 页面内关键权限 |
| --- | --- | --- |
| 用户管理 | `SYS_USER_READ` | `SYS_USER_WRITE`、`SYS_USER_STATUS`；分配角色还需 `SYS_USER_ROLE_ASSIGN` 和 `SYS_ROLE_READ` |
| 角色管理 | `SYS_ROLE_READ` | `SYS_ROLE_WRITE`；配置权限还需 `SYS_ROLE_PERMISSION_ASSIGN` 和 `SYS_PERMISSION_READ` |
| 基础权限 | `SYS_PERMISSION_READ` | `SYS_PERMISSION_WRITE` |
| 供应商审核 | `SUPPLIER_READ` | `SUPPLIER_WRITE`、`SUPPLIER_SUBMIT`、`SUPPLIER_REVIEW` |
| 批号追溯 | `TRACE_READ` | 无，接口只读 |

## 5. 已知接口边界

- 当前没有部门目录接口，创建或编辑用户时使用数字部门 ID，默认带出当前用户部门；
- 当前没有真实文件上传接口，供应商页面只登记已经进入受控文件存储的文件元数据和 SHA-256；
- 当前没有审计日志查询接口，页面会触发后端写审计，但不伪造审计查询页；
- 当前供应商审核为单次审核：提交人不能审核本人，驳回原因必填；
- 追溯接口没有数据时展示真实空结果，不生成模拟采购、库存、销售或客户节点；
- 当前没有前端密码修改或重置接口。

## 6. 浏览器验收

### 登录与权限

1. 输入错误密码，确认页面显示后端 401 信息；
2. 使用初始化管理员登录，确认显示当前姓名、部门、角色和可访问模块；
3. 创建只有 `TRACE_READ` 的角色和用户；
4. 使用该用户重新登录，确认只显示工作台和批号追溯；
5. 直接请求无权接口，确认后端返回 403。

### 用户、角色和权限

1. 创建演示用户，初始密码不足 8 位时前端阻止提交；
2. 修改用户时不填写原因，前端阻止提交；
3. 尝试停用当前登录用户，页面禁用操作，后端也会阻断直接调用；
4. 给用户选择互斥角色，确认后端返回业务冲突；
5. 修改角色权限和权限树父节点，确认原因必填、树环路由后端阻断。

### 供应商审核

1. 采购员创建供应商草稿；
2. 分别登记营业执照、与企业类型匹配的许可证、授权文件；
3. 为每项登记受控存储键、文件大小和 64 位 SHA-256；
4. 缺少任一必需资料时提交，确认后端阻断并显示明确原因；
5. 材料齐全后提交，状态变为 `UNDER_REVIEW`；
6. 用提交人直接审核，确认页面和后端均阻断；
7. 使用具有 `SUPPLIER_REVIEW` 的其他账号通过或驳回；
8. 驳回时不填写原因，确认无法提交；
9. 驳回后修改资料并重新提交，确认产生新的审核轮次。

### 批号追溯

1. 输入存在的生产批号；
2. 查看批次档案、库存位置和按时间排序的真实事件；
3. 同一批号匹配多个药品时，确认结果分开显示，并使用药品编码精确查询；
4. 输入不存在批号，确认显示真实空结果；
5. 查看事件证据 JSON；非法 JSON 按原始文本显示并提示。

## 7. 测试和构建

```bash
npm --prefix frontend run typecheck
npm --prefix frontend run test
npm --prefix frontend run build
```

构建结果位于忽略提交的 `frontend/dist/`。

## 8. 生产反向代理

生产构建默认请求 `/api`。Web 服务器需要：

1. 对 SPA 路由执行 `index.html` fallback；
2. 将 `/api/` 反向代理到 Spring Boot，并移除 `/api` 前缀；
3. 全站启用 HTTPS；
4. 不缓存包含身份信息的 API 响应。

仓库提供不含域名和证书的最小示例：`nginx.conf.example`。
