package com.fuhaha.pharmaerp.modules.system.rbac.controller;

import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.PermissionCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.PermissionUpdateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.service.RbacService;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.PermissionVO;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/system/permissions")
@Tag(name = "基础权限", description = "菜单、页面、按钮、数据和操作权限目录")
public class PermissionController {

    private final RbacService rbacService;

    public PermissionController(RbacService rbacService) {
        this.rbacService = rbacService;
    }

    @PostMapping
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_PERMISSION_WRITE + "')")
    @Operation(summary = "创建权限")
    public Result<PermissionVO> create(@Valid @RequestBody PermissionCreateRequest request) {
        return Result.success(rbacService.createPermission(request));
    }

    @PutMapping("/{permissionId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_PERMISSION_WRITE + "')")
    @Operation(summary = "修改权限", description = "校验权限树不能指向自身或形成环")
    public Result<PermissionVO> update(
            @PathVariable Long permissionId,
            @Valid @RequestBody PermissionUpdateRequest request) {
        return Result.success(rbacService.updatePermission(permissionId, request));
    }

    @GetMapping("/tree")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SYS_PERMISSION_READ + "')")
    @Operation(summary = "查询权限树")
    public Result<List<PermissionVO>> tree(
            @RequestParam(defaultValue = "false") boolean includeDisabled) {
        return Result.success(rbacService.permissionTree(includeDisabled));
    }
}
