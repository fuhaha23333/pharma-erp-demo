package com.fuhaha.pharmaerp.modules.system.rbac.service;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.when;

import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserRoleAssignRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRole;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRoleConflict;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUser;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysAuthorizationMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysDepartmentMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysPermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleConflictMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRolePermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserRoleMapper;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.util.LinkedHashSet;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class RbacServiceTest {

    @Mock private SysUserMapper userMapper;
    @Mock private SysDepartmentMapper departmentMapper;
    @Mock private SysRoleMapper roleMapper;
    @Mock private SysPermissionMapper permissionMapper;
    @Mock private SysUserRoleMapper userRoleMapper;
    @Mock private SysRolePermissionMapper rolePermissionMapper;
    @Mock private SysRoleConflictMapper roleConflictMapper;
    @Mock private SysAuthorizationMapper authorizationMapper;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private CurrentUserService currentUserService;
    @Mock private AuditTrailService auditTrailService;

    @InjectMocks
    private RbacService rbacService;

    @Test
    void shouldBlockMutuallyExclusiveRoles() {
        SysUser user = new SysUser();
        user.setId(1L);
        SysRole first = role(10L, "PURCHASER");
        SysRole second = role(20L, "QUALITY_REVIEWER");
        SysRoleConflict conflict = new SysRoleConflict();
        conflict.setRoleAId(10L);
        conflict.setRoleBId(20L);
        conflict.setReason("采购申请与质量审核职责分离");

        when(currentUserService.requireUserId()).thenReturn(99L);
        when(userMapper.selectById(1L)).thenReturn(user);
        when(roleMapper.selectByIds(anyCollection())).thenReturn(List.of(first, second));
        when(roleConflictMapper.selectList(any())).thenReturn(List.of(conflict));

        UserRoleAssignRequest request = new UserRoleAssignRequest();
        request.setRoleIds(new LinkedHashSet<>(List.of(10L, 20L)));
        request.setReason("岗位调整");

        assertThatThrownBy(() -> rbacService.assignUserRoles(1L, request))
                .isInstanceOf(BizException.class)
                .hasMessageContaining("角色互斥")
                .extracting("code")
                .isEqualTo(409);
    }

    private SysRole role(Long id, String code) {
        SysRole role = new SysRole();
        role.setId(id);
        role.setRoleCode(code);
        role.setRoleName(code);
        role.setStatus("ACTIVE");
        return role;
    }
}
