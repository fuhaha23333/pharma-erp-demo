package com.fuhaha.pharmaerp.modules.system.rbac.controller;

import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.system.rbac.service.RbacService;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.CurrentUserVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/system/auth")
@Tag(name = "认证信息", description = "HTTP Basic认证后的当前用户、角色和权限")
public class AuthController {

    private final RbacService rbacService;

    public AuthController(RbacService rbacService) {
        this.rbacService = rbacService;
    }

    @GetMapping("/me")
    @Operation(summary = "获取当前登录用户")
    public Result<CurrentUserVO> me() {
        return Result.success(rbacService.currentUser());
    }
}
