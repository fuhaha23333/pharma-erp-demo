# 项目技术栈

## 项目架构

- 前后端分离架构
- 前端通过 HTTP/REST API 与后端交互，数据交换格式使用 JSON

## 前端技术栈

- Vue 3
- Vite

## 后端技术栈

以下内容基于 `backend/pom.xml` 提取，并补充 Redis 与 Spring Security：

| 技术 | 版本或用途 |
| --- | --- |
| Java | 17 |
| Spring Boot | 3.3.5，后端基础框架 |
| Spring Web | Web 与 REST API 开发 |
| Spring Validation | 请求参数校验 |
| Spring Security | 认证与授权 |
| Redis / Spring Data Redis | 缓存、会话及临时数据存储 |
| MyBatis-Plus | 3.5.9，数据持久层框架 |
| MyBatis-Plus JSQLParser | 3.5.9，SQL 解析支持 |
| MySQL Connector/J | MySQL 数据库驱动 |
| Knife4j | 4.5.0，OpenAPI 3 接口文档 |
| Lombok | 简化 Java 样板代码 |
| Maven | 项目构建与依赖管理 |
| Spring Boot Test | 后端测试支持 |
