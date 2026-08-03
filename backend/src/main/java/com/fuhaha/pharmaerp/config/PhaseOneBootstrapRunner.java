package com.fuhaha.pharmaerp.config;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysDepartment;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysPermission;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRole;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRoleConflict;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysRolePermission;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUser;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUserRole;
import com.fuhaha.pharmaerp.modules.system.rbac.enums.ActivationStatus;
import com.fuhaha.pharmaerp.modules.system.rbac.enums.UserRoleStatus;
import com.fuhaha.pharmaerp.modules.system.rbac.enums.UserStatus;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysDepartmentMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysPermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleConflictMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRolePermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserRoleMapper;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Component
@ConditionalOnProperty(name = "pharma.bootstrap.enabled", havingValue = "true")
public class PhaseOneBootstrapRunner implements ApplicationRunner {

    private static final List<PermissionSeed> PERMISSIONS = List.of(
            permission(PermissionCodes.SYS_USER_READ, "查看用户", "SYS", "/system/users/**"),
            permission(PermissionCodes.SYS_USER_WRITE, "维护用户", "SYS", "/system/users/**"),
            permission(PermissionCodes.SYS_USER_STATUS, "启停用户", "SYS", "/system/users/*/status"),
            permission(PermissionCodes.SYS_USER_ROLE_ASSIGN, "分配用户角色", "SYS", "/system/users/*/roles"),
            permission(PermissionCodes.SYS_ROLE_READ, "查看角色", "SYS", "/system/roles/**"),
            permission(PermissionCodes.SYS_ROLE_WRITE, "维护角色", "SYS", "/system/roles/**"),
            permission(PermissionCodes.SYS_ROLE_PERMISSION_ASSIGN, "配置角色权限", "SYS", "/system/roles/*/permissions"),
            permission(PermissionCodes.SYS_PERMISSION_READ, "查看基础权限", "SYS", "/system/permissions/**"),
            permission(PermissionCodes.SYS_PERMISSION_WRITE, "维护基础权限", "SYS", "/system/permissions/**"),
            permission(PermissionCodes.SUPPLIER_READ, "查看供应商资质", "SUPPLIER", "/quality/suppliers/**"),
            permission(PermissionCodes.SUPPLIER_WRITE, "维护供应商资质", "SUPPLIER", "/quality/suppliers/**"),
            permission(PermissionCodes.SUPPLIER_SUBMIT, "提交供应商审核", "SUPPLIER", "/quality/suppliers/*/submit"),
            permission(PermissionCodes.SUPPLIER_REVIEW, "审核供应商资质", "SUPPLIER", "/quality/suppliers/*/reviews/*"),
            permission(PermissionCodes.TRACE_READ, "查询药品追溯", "TRACE", "/trace/batches/**"));

    private static final Set<String> SYSTEM_PERMISSIONS = Set.of(
            PermissionCodes.SYS_USER_READ,
            PermissionCodes.SYS_USER_WRITE,
            PermissionCodes.SYS_USER_STATUS,
            PermissionCodes.SYS_USER_ROLE_ASSIGN,
            PermissionCodes.SYS_ROLE_READ,
            PermissionCodes.SYS_ROLE_WRITE,
            PermissionCodes.SYS_ROLE_PERMISSION_ASSIGN,
            PermissionCodes.SYS_PERMISSION_READ,
            PermissionCodes.SYS_PERMISSION_WRITE);

    private static final List<RoleSeed> ROLES = List.of(
            role("SUPER_ADMIN", "超级管理员", "HIGH", allPermissionCodes()),
            role("ENTERPRISE_ADMIN", "企业管理员", "HIGH", union(
                    SYSTEM_PERMISSIONS, Set.of(PermissionCodes.SUPPLIER_READ, PermissionCodes.TRACE_READ))),
            role("QUALITY_HEAD", "质量负责人", "HIGH", Set.of(
                    PermissionCodes.SUPPLIER_READ,
                    PermissionCodes.SUPPLIER_REVIEW,
                    PermissionCodes.TRACE_READ)),
            role("PURCHASING_MANAGER", "采购经理", "NORMAL", Set.of(
                    PermissionCodes.SUPPLIER_READ,
                    PermissionCodes.TRACE_READ)),
            role("PURCHASER", "采购员", "NORMAL", Set.of(
                    PermissionCodes.SUPPLIER_READ,
                    PermissionCodes.SUPPLIER_WRITE,
                    PermissionCodes.SUPPLIER_SUBMIT,
                    PermissionCodes.TRACE_READ)),
            role("WAREHOUSE_MANAGER", "仓库主管", "NORMAL", Set.of(PermissionCodes.TRACE_READ)),
            role("WAREHOUSE_OPERATOR", "仓库管理员", "NORMAL", Set.of(PermissionCodes.TRACE_READ)),
            role("SALES_MANAGER", "销售经理", "NORMAL", Set.of(PermissionCodes.TRACE_READ)),
            role("SALES", "销售人员", "NORMAL", Set.of(PermissionCodes.TRACE_READ)));

    private final SysDepartmentMapper departmentMapper;
    private final SysUserMapper userMapper;
    private final SysPermissionMapper permissionMapper;
    private final SysRoleMapper roleMapper;
    private final SysRolePermissionMapper rolePermissionMapper;
    private final SysUserRoleMapper userRoleMapper;
    private final SysRoleConflictMapper roleConflictMapper;
    private final PasswordEncoder passwordEncoder;
    private final AuditTrailService auditTrailService;
    private final String username;
    private final String displayName;
    private final String password;
    private final String departmentCode;
    private final String departmentName;

    public PhaseOneBootstrapRunner(
            SysDepartmentMapper departmentMapper,
            SysUserMapper userMapper,
            SysPermissionMapper permissionMapper,
            SysRoleMapper roleMapper,
            SysRolePermissionMapper rolePermissionMapper,
            SysUserRoleMapper userRoleMapper,
            SysRoleConflictMapper roleConflictMapper,
            PasswordEncoder passwordEncoder,
            AuditTrailService auditTrailService,
            @Value("${pharma.bootstrap.username:admin}") String username,
            @Value("${pharma.bootstrap.display-name:系统管理员}") String displayName,
            @Value("${pharma.bootstrap.password:}") String password,
            @Value("${pharma.bootstrap.department-code:ROOT}") String departmentCode,
            @Value("${pharma.bootstrap.department-name:示例药品经营企业}") String departmentName) {
        this.departmentMapper = departmentMapper;
        this.userMapper = userMapper;
        this.permissionMapper = permissionMapper;
        this.roleMapper = roleMapper;
        this.rolePermissionMapper = rolePermissionMapper;
        this.userRoleMapper = userRoleMapper;
        this.roleConflictMapper = roleConflictMapper;
        this.passwordEncoder = passwordEncoder;
        this.auditTrailService = auditTrailService;
        this.username = username;
        this.displayName = displayName;
        this.password = password;
        this.departmentCode = departmentCode;
        this.departmentName = departmentName;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void run(ApplicationArguments args) {
        validateConfiguration();
        BootstrapResult result = new BootstrapResult();
        SysDepartment department = ensureDepartment(result);
        SysUser administrator = ensureAdministrator(department.getId(), result);
        Map<String, SysPermission> permissions = ensurePermissions(administrator.getId(), result);
        Map<String, SysRole> roles = ensureRoles(administrator.getId(), result);
        ensureRolePermissions(roles, permissions, administrator.getId(), result);
        ensureAdministratorRole(administrator.getId(), roles.get("SUPER_ADMIN").getId(), result);
        ensurePurchasingQualityConflict(roles, administrator.getId(), result);

        if (result.changed) {
            auditTrailService.recordOperation(
                    administrator.getId(),
                    "SYS",
                    "BOOTSTRAP",
                    "SYS_USER",
                    administrator.getId(),
                    "初始化第一阶段管理员、角色和权限",
                    null,
                    Map.of("username", administrator.getUsername(), "createdObjects", result.createdObjects));
        }
    }

    private SysDepartment ensureDepartment(BootstrapResult result) {
        SysDepartment department = departmentMapper.selectOne(Wrappers.<SysDepartment>lambdaQuery()
                .eq(SysDepartment::getDepartmentCode, departmentCode.trim()));
        if (department != null) {
            requireActive(department.getStatus(), "初始化部门已停用");
            return department;
        }

        department = new SysDepartment();
        department.setDepartmentCode(departmentCode.trim());
        department.setDepartmentName(departmentName.trim());
        department.setDepartmentType("ENTERPRISE");
        department.setStatus(ActivationStatus.ACTIVE.name());
        department.setSortOrder(0);
        departmentMapper.insert(department);
        result.created("department:" + department.getDepartmentCode());
        return department;
    }

    private SysUser ensureAdministrator(Long departmentId, BootstrapResult result) {
        SysUser administrator = userMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                .eq(SysUser::getUsername, username.trim()));
        if (administrator != null) {
            requireActive(administrator.getStatus(), "初始化管理员账号不是启用状态");
            return administrator;
        }

        administrator = new SysUser();
        administrator.setUsername(username.trim());
        administrator.setDisplayName(displayName.trim());
        administrator.setPasswordHash(passwordEncoder.encode(password));
        administrator.setDepartmentId(departmentId);
        administrator.setStatus(UserStatus.ACTIVE.name());
        administrator.setFailedLoginCount(0);
        userMapper.insert(administrator);
        result.created("user:" + administrator.getUsername());
        return administrator;
    }

    private Map<String, SysPermission> ensurePermissions(Long operatorId, BootstrapResult result) {
        Map<String, SysPermission> permissions = new LinkedHashMap<>();
        for (PermissionSeed seed : PERMISSIONS) {
            SysPermission permission = permissionMapper.selectOne(Wrappers.<SysPermission>lambdaQuery()
                    .eq(SysPermission::getPermissionCode, seed.code));
            if (permission == null) {
                permission = new SysPermission();
                permission.setPermissionCode(seed.code);
                permission.setPermissionName(seed.name);
                permission.setPermissionType("ACTION");
                permission.setModuleCode(seed.module);
                permission.setResourceKey(seed.code);
                permission.setApiPattern(seed.apiPattern);
                permission.setStatus(ActivationStatus.ACTIVE.name());
                permission.setSortOrder(0);
                permission.setDescription("第一阶段内置权限");
                permission.setCreatedBy(operatorId);
                permission.setUpdatedBy(operatorId);
                permissionMapper.insert(permission);
                result.created("permission:" + seed.code);
            } else {
                requireActive(permission.getStatus(), "初始化权限已停用：" + seed.code);
            }
            permissions.put(seed.code, permission);
        }
        return permissions;
    }

    private Map<String, SysRole> ensureRoles(Long operatorId, BootstrapResult result) {
        Map<String, SysRole> roles = new LinkedHashMap<>();
        for (RoleSeed seed : ROLES) {
            SysRole role = roleMapper.selectOne(Wrappers.<SysRole>lambdaQuery()
                    .eq(SysRole::getRoleCode, seed.code));
            if (role == null) {
                role = new SysRole();
                role.setRoleCode(seed.code);
                role.setRoleName(seed.name);
                role.setRiskLevel(seed.riskLevel);
                role.setDescription("需求分析文档定义的默认角色");
                role.setStatus(ActivationStatus.ACTIVE.name());
                role.setIsBuiltin(1);
                role.setCreatedBy(operatorId);
                role.setUpdatedBy(operatorId);
                roleMapper.insert(role);
                result.created("role:" + seed.code);
            } else {
                requireActive(role.getStatus(), "初始化角色已停用：" + seed.code);
            }
            roles.put(seed.code, role);
        }
        return roles;
    }

    private void ensureRolePermissions(
            Map<String, SysRole> roles,
            Map<String, SysPermission> permissions,
            Long operatorId,
            BootstrapResult result) {
        for (RoleSeed roleSeed : ROLES) {
            SysRole role = roles.get(roleSeed.code);
            for (String permissionCode : roleSeed.permissionCodes) {
                SysPermission permission = permissions.get(permissionCode);
                Long count = rolePermissionMapper.selectCount(Wrappers.<SysRolePermission>lambdaQuery()
                        .eq(SysRolePermission::getRoleId, role.getId())
                        .eq(SysRolePermission::getPermissionId, permission.getId()));
                if (count == null || count == 0) {
                    SysRolePermission link = new SysRolePermission();
                    link.setRoleId(role.getId());
                    link.setPermissionId(permission.getId());
                    link.setCreatedBy(operatorId);
                    rolePermissionMapper.insert(link);
                    result.created("role-permission:" + roleSeed.code + ":" + permissionCode);
                }
            }
        }
    }

    private void ensureAdministratorRole(
            Long administratorId,
            Long superAdminRoleId,
            BootstrapResult result) {
        SysUserRole link = userRoleMapper.selectOne(Wrappers.<SysUserRole>lambdaQuery()
                .eq(SysUserRole::getUserId, administratorId)
                .eq(SysUserRole::getRoleId, superAdminRoleId));
        if (link == null) {
            link = new SysUserRole();
            link.setUserId(administratorId);
            link.setRoleId(superAdminRoleId);
            link.setStatus(UserRoleStatus.ACTIVE.name());
            link.setValidFrom(LocalDateTime.now(ZoneOffset.UTC));
            link.setCreatedBy(administratorId);
            link.setUpdatedBy(administratorId);
            userRoleMapper.insert(link);
            result.created("user-role:" + administratorId + ":SUPER_ADMIN");
        } else if (!UserRoleStatus.ACTIVE.name().equals(link.getStatus())) {
            throw new IllegalStateException("初始化管理员的超级管理员授权已被撤销，请人工核查后处理");
        }
    }

    private void ensurePurchasingQualityConflict(
            Map<String, SysRole> roles,
            Long operatorId,
            BootstrapResult result) {
        Long purchaserId = roles.get("PURCHASER").getId();
        Long qualityHeadId = roles.get("QUALITY_HEAD").getId();
        Long firstId = Math.min(purchaserId, qualityHeadId);
        Long secondId = Math.max(purchaserId, qualityHeadId);
        Long count = roleConflictMapper.selectCount(Wrappers.<SysRoleConflict>lambdaQuery()
                .eq(SysRoleConflict::getRoleAId, firstId)
                .eq(SysRoleConflict::getRoleBId, secondId));
        if (count == null || count == 0) {
            SysRoleConflict conflict = new SysRoleConflict();
            conflict.setRoleAId(firstId);
            conflict.setRoleBId(secondId);
            conflict.setConflictScope("USER");
            conflict.setReason("采购提交与质量审核职责分离");
            conflict.setStatus(ActivationStatus.ACTIVE.name());
            conflict.setCreatedBy(operatorId);
            conflict.setUpdatedBy(operatorId);
            roleConflictMapper.insert(conflict);
            result.created("role-conflict:PURCHASER:QUALITY_HEAD");
        }
    }

    private void validateConfiguration() {
        if (!StringUtils.hasText(username) || !StringUtils.hasText(displayName)
                || !StringUtils.hasText(departmentCode) || !StringUtils.hasText(departmentName)) {
            throw new IllegalStateException("启用第一阶段初始化时，管理员和部门配置不能为空");
        }
        if (!StringUtils.hasText(password) || password.length() < 12) {
            throw new IllegalStateException("PHARMA_BOOTSTRAP_PASSWORD必须至少12位，且不能写入代码仓库");
        }
    }

    private void requireActive(String status, String message) {
        if (!ActivationStatus.ACTIVE.name().equals(status)) {
            throw new IllegalStateException(message);
        }
    }

    private static PermissionSeed permission(String code, String name, String module, String apiPattern) {
        return new PermissionSeed(code, name, module, apiPattern);
    }

    private static RoleSeed role(String code, String name, String riskLevel, Set<String> permissionCodes) {
        return new RoleSeed(code, name, riskLevel, permissionCodes);
    }

    private static Set<String> allPermissionCodes() {
        Set<String> result = new LinkedHashSet<>();
        PERMISSIONS.forEach(permission -> result.add(permission.code));
        return result;
    }

    private static Set<String> union(Set<String> left, Set<String> right) {
        Set<String> result = new LinkedHashSet<>(left);
        result.addAll(right);
        return result;
    }

    private record PermissionSeed(String code, String name, String module, String apiPattern) {
    }

    private record RoleSeed(String code, String name, String riskLevel, Set<String> permissionCodes) {
    }

    private static final class BootstrapResult {

        private final Set<String> createdObjects = new LinkedHashSet<>();
        private boolean changed;

        private void created(String object) {
            createdObjects.add(object);
            changed = true;
        }
    }
}
