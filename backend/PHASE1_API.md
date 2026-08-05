# 第一阶段后端接口

本阶段仅实现后端，不包含前端。接口以代码中的 OpenAPI 注解为准，应用启动后可访问：

- Knife4j：`http://localhost:8080/doc.html`
- Swagger UI：`http://localhost:8080/swagger-ui.html`
- OpenAPI JSON：`http://localhost:8080/v3/api-docs`

自动化测试会检查五个阶段模块的关键路径仍存在于 OpenAPI 文档，防止后续修改时接口文档丢失。

## 认证与初始化

第一阶段使用 Spring Security 的无状态 HTTP Basic 认证。除健康检查和接口文档外，所有请求都必须认证；业务接口再通过权限编码执行方法级鉴权。部署时必须使用 HTTPS。

空数据库首次启动前，先执行根目录的 `pharma_erp_schema.sql`，并通过 Spring Boot 配置或 `SPRING_DATASOURCE_*` 环境变量提供可用的开发库账号。然后仅在首次初始化时设置环境变量：

```bash
export SPRING_DATASOURCE_USERNAME=navicat
read -rsp '请输入 WSL MySQL 密码: ' SPRING_DATASOURCE_PASSWORD
export SPRING_DATASOURCE_PASSWORD

export PHARMA_BOOTSTRAP_ENABLED=true
export PHARMA_BOOTSTRAP_USERNAME=admin
read -rsp '请输入至少12位的独立强密码: ' PHARMA_BOOTSTRAP_PASSWORD
export PHARMA_BOOTSTRAP_PASSWORD
mvn -f backend/pom.xml spring-boot:run
```

初始化过程幂等地创建企业根部门、第一阶段权限、需求文档中的默认角色以及初始超级管理员。密码只从环境变量读取并以 BCrypt 哈希保存；不要把真实密码写入仓库。成功后应关闭 `PHARMA_BOOTSTRAP_ENABLED`。

调用示例：

```bash
curl --user "$PHARMA_BOOTSTRAP_USERNAME:$PHARMA_BOOTSTRAP_PASSWORD" \
  http://localhost:8080/system/auth/me
```

## 接口清单

| 模块 | 方法与路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| 认证 | `GET /system/auth/me` | 已认证 | 当前用户、角色和权限 |

认证失败统一返回 JSON `401`，且不返回 `WWW-Authenticate` 挑战头，避免使用自定义登录页时浏览器再次弹出原生 HTTP Basic 登录窗口。
| 用户 | `POST /system/users` | `SYS_USER_WRITE` | 创建用户，密码保存为 BCrypt 哈希 |
| 用户 | `PUT /system/users/{userId}` | `SYS_USER_WRITE` | 修改姓名、联系方式和部门 |
| 用户 | `PUT /system/users/{userId}/status` | `SYS_USER_STATUS` | 启用或停用账号 |
| 用户 | `PUT /system/users/{userId}/roles` | `SYS_USER_ROLE_ASSIGN` | 替换有效角色并检查互斥规则 |
| 用户 | `GET /system/users/{userId}` | `SYS_USER_READ` | 用户详情 |
| 用户 | `GET /system/users/page` | `SYS_USER_READ` | 用户分页查询 |
| 角色 | `POST /system/roles` | `SYS_ROLE_WRITE` | 创建角色 |
| 角色 | `PUT /system/roles/{roleId}` | `SYS_ROLE_WRITE` | 修改角色 |
| 角色 | `PUT /system/roles/{roleId}/permissions` | `SYS_ROLE_PERMISSION_ASSIGN` | 替换角色权限 |
| 角色 | `GET /system/roles/{roleId}` | `SYS_ROLE_READ` | 角色详情 |
| 角色 | `GET /system/roles/page` | `SYS_ROLE_READ` | 角色分页查询 |
| 权限 | `POST /system/permissions` | `SYS_PERMISSION_WRITE` | 创建基础权限 |
| 权限 | `PUT /system/permissions/{permissionId}` | `SYS_PERMISSION_WRITE` | 修改权限并检查树环路 |
| 权限 | `GET /system/permissions/tree` | `SYS_PERMISSION_READ` | 查询权限树 |
| 供应商 | `POST /quality/suppliers` | `SUPPLIER_WRITE` | 创建供应商草稿 |
| 供应商 | `PUT /quality/suppliers/{supplierId}` | `SUPPLIER_WRITE` | 修改草稿或被驳回的供应商 |
| 供应商 | `POST /quality/suppliers/{supplierId}/qualifications` | `SUPPLIER_WRITE` | 新增资质 |
| 供应商 | `PUT /quality/suppliers/{supplierId}/qualifications/{qualificationId}` | `SUPPLIER_WRITE` | 修改资质 |
| 供应商 | `POST /quality/suppliers/{supplierId}/qualifications/{qualificationId}/attachments` | `SUPPLIER_WRITE` | 登记受控文件元数据和 SHA-256 |
| 供应商 | `POST /quality/suppliers/{supplierId}/submit` | `SUPPLIER_SUBMIT` | 校验必需资质和附件并固化快照 |
| 供应商 | `PUT /quality/suppliers/{supplierId}/reviews/{reviewId}` | `SUPPLIER_REVIEW` | 审核通过或驳回 |
| 供应商 | `GET /quality/suppliers/{supplierId}` | `SUPPLIER_READ` | 资质、附件和审核历史详情 |
| 供应商 | `GET /quality/suppliers/page` | `SUPPLIER_READ` | 供应商分页查询 |
| 追溯 | `GET /trace/batches/{batchNo}` | `TRACE_READ` | 查询批次、库存分布和生命周期事件；可传 `drugCode` |

## 关键状态和阻断规则

供应商状态：`DRAFT -> UNDER_REVIEW -> APPROVED / REJECTED`。`REJECTED` 可修改后再次提交，每次提交都会生成新审核轮次和不可变资质快照。

提交时至少需要营业执照、与供应商类型匹配的生产或经营许可证、授权文件；每类必须有一份当前生效且带有效附件的资质。审核人不能是提交人。用户不能停用自己，停用角色和权限不能继续分配，互斥角色不能同时授予同一用户。

用户、角色、权限、供应商状态、供应商审核和追溯查询都会写入对应的操作、权限变更或状态历史日志。追溯事件本阶段只读，后续采购、验收、库存和销售模块应在业务事务中追加 `batch_trace_event`，不得通过追溯接口伪造事件。

服务端和数据库连接统一使用 UTC 写入时间；前端后续按用户时区转换展示。
