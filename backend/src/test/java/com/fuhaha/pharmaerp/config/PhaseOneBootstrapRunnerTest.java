package com.fuhaha.pharmaerp.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysDepartment;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysPermission;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRole;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRoleConflict;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRolePermission;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUser;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUserRole;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysDepartmentMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysPermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleConflictMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRolePermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserRoleMapper;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class PhaseOneBootstrapRunnerTest {

    @Mock private SysDepartmentMapper departmentMapper;
    @Mock private SysUserMapper userMapper;
    @Mock private SysPermissionMapper permissionMapper;
    @Mock private SysRoleMapper roleMapper;
    @Mock private SysRolePermissionMapper rolePermissionMapper;
    @Mock private SysUserRoleMapper userRoleMapper;
    @Mock private SysRoleConflictMapper roleConflictMapper;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private AuditTrailService auditTrailService;

    private AtomicLong ids;

    @BeforeEach
    void setUp() {
        ids = new AtomicLong(1L);
    }

    @Test
    void shouldRejectWeakBootstrapPasswordBeforeWritingAnything() {
        PhaseOneBootstrapRunner runner = runner("short");

        assertThatThrownBy(() -> runner.run(null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("至少12位");
    }

    @Test
    void shouldCreateAdministratorRolesAndPermissionsWithoutPlaintextPassword() throws Exception {
        when(departmentMapper.selectOne(any())).thenReturn(null);
        when(userMapper.selectOne(any())).thenReturn(null);
        when(permissionMapper.selectOne(any())).thenReturn(null);
        when(roleMapper.selectOne(any())).thenReturn(null);
        when(rolePermissionMapper.selectCount(any())).thenReturn(0L);
        when(userRoleMapper.selectOne(any())).thenReturn(null);
        when(roleConflictMapper.selectCount(any())).thenReturn(0L);
        when(passwordEncoder.encode("A-strong-bootstrap-secret")).thenReturn("{bcrypt}encoded");
        assignIdOnInsert();

        runner("A-strong-bootstrap-secret").run(null);

        ArgumentCaptor<SysUser> userCaptor = ArgumentCaptor.forClass(SysUser.class);
        verify(userMapper).insert(userCaptor.capture());
        assertThat(userCaptor.getValue().getPasswordHash()).isEqualTo("{bcrypt}encoded");
        assertThat(userCaptor.getValue().getPasswordHash()).doesNotContain("A-strong-bootstrap-secret");
        verify(permissionMapper, times(14)).insert(any(SysPermission.class));
        verify(roleMapper, times(9)).insert(any(SysRole.class));
        verify(rolePermissionMapper, atLeastOnce()).insert(any(SysRolePermission.class));
        verify(userRoleMapper).insert(any(SysUserRole.class));
        verify(roleConflictMapper).insert(any(SysRoleConflict.class));
        verify(auditTrailService).recordOperation(
                any(), any(), any(), any(), any(), any(), any(), any());
    }

    private PhaseOneBootstrapRunner runner(String password) {
        return new PhaseOneBootstrapRunner(
                departmentMapper,
                userMapper,
                permissionMapper,
                roleMapper,
                rolePermissionMapper,
                userRoleMapper,
                roleConflictMapper,
                passwordEncoder,
                auditTrailService,
                "admin",
                "系统管理员",
                password,
                "ROOT",
                "示例企业");
    }

    private void assignIdOnInsert() {
        when(departmentMapper.insert(any(SysDepartment.class))).thenAnswer(invocation -> {
            invocation.<SysDepartment>getArgument(0).setId(ids.getAndIncrement());
            return 1;
        });
        when(userMapper.insert(any(SysUser.class))).thenAnswer(invocation -> {
            invocation.<SysUser>getArgument(0).setId(ids.getAndIncrement());
            return 1;
        });
        when(permissionMapper.insert(any(SysPermission.class))).thenAnswer(invocation -> {
            invocation.<SysPermission>getArgument(0).setId(ids.getAndIncrement());
            return 1;
        });
        when(roleMapper.insert(any(SysRole.class))).thenAnswer(invocation -> {
            invocation.<SysRole>getArgument(0).setId(ids.getAndIncrement());
            return 1;
        });
    }
}
