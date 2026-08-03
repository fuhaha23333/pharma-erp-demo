package com.fuhaha.pharmaerp.modules.system.rbac.controller;

import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RoleCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RolePageQuery;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RolePermissionAssignRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RoleUpdateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.service.RbacService;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.RoleVO;
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
@RequestMapping("/system/roles")
@Tag(name = "角色管理", description = "创建角色、维护角色并配置基础权限")
public class RoleController {

    private final RbacService rbacService;

    public RoleController(RbacService rbacService) {
        this.rbacService = rbacService;
    }

    @PostMapping
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_ROLE_WRITE + "')")
    @Operation(summary = "创建角色")
    public Result<RoleVO> create(@Valid @RequestBody RoleCreateRequest request) {
        return Result.success(rbacService.createRole(request));
    }

    @PutMapping("/{roleId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_ROLE_WRITE + "')")
    @Operation(summary = "修改角色")
    public Result<RoleVO> update(
            @PathVariable Long roleId,
            @Valid @RequestBody RoleUpdateRequest request) {
        return Result.success(rbacService.updateRole(roleId, request));
    }

    @PutMapping("/{roleId}/permissions")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_ROLE_PERMISSION_ASSIGN + "')")
    @Operation(summary = "替换角色权限", description = "权限变更写入独立审计日志")
    public Result<Void> assignPermissions(
            @PathVariable Long roleId,
            @Valid @RequestBody RolePermissionAssignRequest request) {
        rbacService.assignRolePermissions(roleId, request);
        return Result.success();
    }

    @GetMapping("/{roleId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_ROLE_READ + "')")
    @Operation(summary = "查询角色详情")
    public Result<RoleVO> detail(@PathVariable Long roleId) {
        return Result.success(rbacService.getRole(roleId));
    }

    @GetMapping("/page")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_ROLE_READ + "')")
    @Operation(summary = "分页查询角色")
    public Result<PageResult<RoleVO>> page(@Valid RolePageQuery query) {
        return Result.success(rbacService.pageRoles(query));
    }
}
