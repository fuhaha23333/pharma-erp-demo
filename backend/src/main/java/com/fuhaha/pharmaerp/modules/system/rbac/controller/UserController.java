package com.fuhaha.pharmaerp.modules.system.rbac.controller;

import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserPageQuery;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserRoleAssignRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserStatusRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserUpdateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.service.RbacService;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.UserVO;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/system/users")
@Tag(name = "用户管理", description = "创建用户、修改部门、启停账号和分配角色")
public class UserController {

    private final RbacService rbacService;

    public UserController(RbacService rbacService) {
        this.rbacService = rbacService;
    }

    @PostMapping
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_WRITE + "')")
    @Operation(summary = "创建用户")
    public Result<UserVO> create(@Valid @RequestBody UserCreateRequest request) {
        return Result.success(rbacService.createUser(request));
    }

    @PutMapping("/{userId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_WRITE + "')")
    @Operation(summary = "修改用户基本信息与所属部门")
    public Result<UserVO> update(
            @PathVariable Long userId,
            @Valid @RequestBody UserUpdateRequest request) {
        return Result.success(rbacService.updateUser(userId, request));
    }

    @PutMapping("/{userId}/status")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_STATUS + "')")
    @Operation(summary = "启用或停用用户")
    public Result<Void> changeStatus(
            @PathVariable Long userId,
            @Valid @RequestBody UserStatusRequest request) {
        rbacService.changeUserStatus(userId, request);
        return Result.success();
    }

    @PutMapping("/{userId}/roles")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_ROLE_ASSIGN + "')")
    @Operation(summary = "替换用户有效角色", description = "自动校验角色状态和互斥规则，并记录权限变更日志")
    public Result<Void> assignRoles(
            @PathVariable Long userId,
            @Valid @RequestBody UserRoleAssignRequest request) {
        rbacService.assignUserRoles(userId, request);
        return Result.success();
    }

    @GetMapping("/{userId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_READ + "')")
    @Operation(summary = "查询用户详情")
    public Result<UserVO> detail(@PathVariable Long userId) {
        return Result.success(rbacService.getUser(userId));
    }

    @GetMapping("/page")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_USER_READ + "')")
    @Operation(summary = "分页查询用户")
    public Result<PageResult<UserVO>> page(@Valid UserPageQuery query) {
        return Result.success(rbacService.pageUsers(query));
    }
}
