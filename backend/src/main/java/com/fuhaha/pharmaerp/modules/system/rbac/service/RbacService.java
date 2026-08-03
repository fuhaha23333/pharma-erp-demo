package com.fuhaha.pharmaerp.modules.system.rbac.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.PermissionCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.PermissionUpdateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RoleCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RolePageQuery;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RolePermissionAssignRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.RoleUpdateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserCreateRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserPageQuery;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserRoleAssignRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserStatusRequest;
import com.fuhaha.pharmaerp.modules.system.rbac.dto.UserUpdateRequest;
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
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysAuthorizationMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysDepartmentMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysPermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleConflictMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRoleMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysRolePermissionMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserRoleMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.CurrentUserVO;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.PermissionVO;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.RoleSimpleVO;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.RoleVO;
import com.fuhaha.pharmaerp.modules.system.rbac.vo.UserVO;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class RbacService {

    private static final Set<String> USER_STATUSES = Set.of(
            UserStatus.ACTIVE.name(), UserStatus.DISABLED.name(), UserStatus.LOCKED.name());

    private final SysUserMapper userMapper;
    private final SysDepartmentMapper departmentMapper;
    private final SysRoleMapper roleMapper;
    private final SysPermissionMapper permissionMapper;
    private final SysUserRoleMapper userRoleMapper;
    private final SysRolePermissionMapper rolePermissionMapper;
    private final SysRoleConflictMapper roleConflictMapper;
    private final SysAuthorizationMapper authorizationMapper;
    private final PasswordEncoder passwordEncoder;
    private final CurrentUserService currentUserService;
    private final AuditTrailService auditTrailService;

    public RbacService(
            SysUserMapper userMapper,
            SysDepartmentMapper departmentMapper,
            SysRoleMapper roleMapper,
            SysPermissionMapper permissionMapper,
            SysUserRoleMapper userRoleMapper,
            SysRolePermissionMapper rolePermissionMapper,
            SysRoleConflictMapper roleConflictMapper,
            SysAuthorizationMapper authorizationMapper,
            PasswordEncoder passwordEncoder,
            CurrentUserService currentUserService,
            AuditTrailService auditTrailService) {
        this.userMapper = userMapper;
        this.departmentMapper = departmentMapper;
        this.roleMapper = roleMapper;
        this.permissionMapper = permissionMapper;
        this.userRoleMapper = userRoleMapper;
        this.rolePermissionMapper = rolePermissionMapper;
        this.roleConflictMapper = roleConflictMapper;
        this.authorizationMapper = authorizationMapper;
        this.passwordEncoder = passwordEncoder;
        this.currentUserService = currentUserService;
        this.auditTrailService = auditTrailService;
    }

    @Transactional(rollbackFor = Exception.class)
    public UserVO createUser(UserCreateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        ensureDepartmentActive(request.getDepartmentId());
        String username = request.getUsername().trim();
        if (userMapper.selectCount(Wrappers.<SysUser>lambdaQuery()
                .eq(SysUser::getUsername, username)) > 0) {
            throw new BizException(409, "用户账号已存在");
        }

        SysUser user = new SysUser();
        user.setUsername(username);
        user.setDisplayName(request.getDisplayName().trim());
        user.setPasswordHash(passwordEncoder.encode(request.getInitialPassword()));
        user.setDepartmentId(request.getDepartmentId());
        user.setMobile(trimToNull(request.getMobile()));
        user.setEmail(trimToNull(request.getEmail()));
        user.setStatus(UserStatus.ACTIVE.name());
        user.setFailedLoginCount(0);
        user.setCreatedBy(operatorId);
        user.setUpdatedBy(operatorId);
        userMapper.insert(user);

        UserVO result = getUser(user.getId());
        auditTrailService.recordOperation(
                operatorId, "SYS", "CREATE", "SYS_USER", user.getId(),
                "创建系统用户", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public UserVO updateUser(Long userId, UserUpdateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        SysUser user = requireUser(userId);
        UserVO before = toUserVO(user);
        ensureDepartmentActive(request.getDepartmentId());

        user.setDisplayName(request.getDisplayName().trim());
        user.setDepartmentId(request.getDepartmentId());
        user.setMobile(trimToNull(request.getMobile()));
        user.setEmail(trimToNull(request.getEmail()));
        user.setUpdatedBy(operatorId);
        ensureUpdated(userMapper.updateById(user), "用户信息已被其他操作修改，请刷新后重试");

        UserVO after = getUser(userId);
        auditTrailService.recordOperation(
                operatorId, "SYS", "UPDATE", "SYS_USER", userId,
                request.getChangeReason().trim(), before, after);
        return after;
    }

    @Transactional(rollbackFor = Exception.class)
    public void changeUserStatus(Long userId, UserStatusRequest request) {
        Long operatorId = currentUserService.requireUserId();
        SysUser user = requireUser(userId);
        String targetStatus = request.getStatus().trim();
        if (!Set.of(UserStatus.ACTIVE.name(), UserStatus.DISABLED.name()).contains(targetStatus)) {
            throw new BizException("用户目标状态非法");
        }
        if (operatorId.equals(userId) && UserStatus.DISABLED.name().equals(targetStatus)) {
            throw new BizException(409, "不能停用当前登录账号");
        }
        if (targetStatus.equals(user.getStatus())) {
            return;
        }

        String beforeStatus = user.getStatus();
        user.setStatus(targetStatus);
        user.setFailedLoginCount(0);
        user.setLockedUntil(null);
        user.setUpdatedBy(operatorId);
        ensureUpdated(userMapper.updateById(user), "用户状态已被其他操作修改，请刷新后重试");

        auditTrailService.recordStatusChange(
                "SYS_USER", userId, user.getUsername(), beforeStatus, targetStatus,
                request.getReason().trim(), operatorId);
        auditTrailService.recordOperation(
                operatorId, "SYS", "STATUS_CHANGE", "SYS_USER", userId,
                request.getReason().trim(), Map.of("status", beforeStatus), Map.of("status", targetStatus));
    }

    @Transactional(rollbackFor = Exception.class)
    public void assignUserRoles(Long userId, UserRoleAssignRequest request) {
        Long operatorId = currentUserService.requireUserId();
        requireUser(userId);
        Set<Long> targetRoleIds = sanitizeIds(request.getRoleIds(), "角色ID不能为空");
        Map<Long, SysRole> targetRoles = loadActiveRoles(targetRoleIds);
        validateRoleConflicts(targetRoles.keySet());

        List<SysUserRole> existingLinks = userRoleMapper.selectList(Wrappers.<SysUserRole>lambdaQuery()
                .eq(SysUserRole::getUserId, userId));
        Map<Long, SysUserRole> linksByRoleId = existingLinks.stream()
                .collect(Collectors.toMap(SysUserRole::getRoleId, Function.identity()));
        Set<Long> beforeRoleIds = existingLinks.stream()
                .filter(link -> UserRoleStatus.ACTIVE.name().equals(link.getStatus()))
                .map(SysUserRole::getRoleId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        LocalDateTime now = nowUtc();

        for (Long roleId : targetRoleIds) {
            SysUserRole link = linksByRoleId.get(roleId);
            if (link == null) {
                link = new SysUserRole();
                link.setUserId(userId);
                link.setRoleId(roleId);
                link.setStatus(UserRoleStatus.ACTIVE.name());
                link.setValidFrom(now);
                link.setCreatedBy(operatorId);
                link.setUpdatedBy(operatorId);
                userRoleMapper.insert(link);
            } else if (!UserRoleStatus.ACTIVE.name().equals(link.getStatus())) {
                link.setStatus(UserRoleStatus.ACTIVE.name());
                link.setValidFrom(now);
                link.setValidTo(null);
                link.setUpdatedBy(operatorId);
                ensureUpdated(userRoleMapper.updateById(link), "用户角色已被其他操作修改");
            }
        }

        for (SysUserRole link : existingLinks) {
            if (UserRoleStatus.ACTIVE.name().equals(link.getStatus()) && !targetRoleIds.contains(link.getRoleId())) {
                link.setStatus(UserRoleStatus.REVOKED.name());
                link.setValidTo(now);
                link.setUpdatedBy(operatorId);
                ensureUpdated(userRoleMapper.updateById(link), "用户角色已被其他操作修改");
            }
        }

        auditTrailService.recordPermissionChange(
                operatorId, "USER_ROLE", userId, "UPDATE", request.getReason().trim(),
                beforeRoleIds, targetRoleIds);
        auditTrailService.recordOperation(
                operatorId, "SYS", "ASSIGN_ROLE", "SYS_USER", userId,
                request.getReason().trim(), beforeRoleIds, targetRoleIds);
    }

    @Transactional(readOnly = true)
    public UserVO getUser(Long userId) {
        return toUserVO(requireUser(userId));
    }

    @Transactional(readOnly = true)
    public PageResult<UserVO> pageUsers(UserPageQuery query) {
        validateUserStatus(query.getStatus());
        Page<SysUser> page = new Page<>(query.getPageNo(), query.getPageSize());
        LambdaQueryWrapper<SysUser> wrapper = Wrappers.<SysUser>lambdaQuery()
                .like(StringUtils.hasText(query.getUsername()), SysUser::getUsername, trim(query.getUsername()))
                .like(StringUtils.hasText(query.getDisplayName()), SysUser::getDisplayName, trim(query.getDisplayName()))
                .eq(StringUtils.hasText(query.getStatus()), SysUser::getStatus, trim(query.getStatus()))
                .eq(query.getDepartmentId() != null, SysUser::getDepartmentId, query.getDepartmentId())
                .orderByDesc(SysUser::getCreatedAt)
                .orderByDesc(SysUser::getId);
        Page<SysUser> result = userMapper.selectPage(page, wrapper);
        return PageResult.of(
                result.getRecords().stream().map(this::toUserVO).toList(),
                result.getTotal(), query.getPageNo(), query.getPageSize());
    }

    @Transactional(rollbackFor = Exception.class)
    public RoleVO createRole(RoleCreateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        String roleCode = request.getRoleCode().trim();
        String roleName = request.getRoleName().trim();
        if (roleMapper.selectCount(Wrappers.<SysRole>lambdaQuery()
                .eq(SysRole::getRoleCode, roleCode)) > 0) {
            throw new BizException(409, "角色编码已存在");
        }
        if (roleMapper.selectCount(Wrappers.<SysRole>lambdaQuery()
                .eq(SysRole::getRoleName, roleName)) > 0) {
            throw new BizException(409, "角色名称已存在");
        }

        SysRole role = new SysRole();
        role.setRoleCode(roleCode);
        role.setRoleName(roleName);
        role.setRiskLevel(request.getRiskLevel().trim());
        role.setDescription(trimToNull(request.getDescription()));
        role.setStatus(ActivationStatus.ACTIVE.name());
        role.setIsBuiltin(0);
        role.setCreatedBy(operatorId);
        role.setUpdatedBy(operatorId);
        roleMapper.insert(role);

        RoleVO result = getRole(role.getId());
        auditTrailService.recordOperation(
                operatorId, "SYS", "CREATE", "SYS_ROLE", role.getId(),
                "创建角色", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public RoleVO updateRole(Long roleId, RoleUpdateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        SysRole role = requireRole(roleId);
        RoleVO before = toRoleVO(role);
        String roleName = request.getRoleName().trim();
        if (roleMapper.selectCount(Wrappers.<SysRole>lambdaQuery()
                .eq(SysRole::getRoleName, roleName)
                .ne(SysRole::getId, roleId)) > 0) {
            throw new BizException(409, "角色名称已存在");
        }

        role.setRoleName(roleName);
        role.setRiskLevel(request.getRiskLevel().trim());
        role.setStatus(request.getStatus().trim());
        role.setDescription(trimToNull(request.getDescription()));
        role.setUpdatedBy(operatorId);
        ensureUpdated(roleMapper.updateById(role), "角色已被其他操作修改，请刷新后重试");

        RoleVO after = getRole(roleId);
        auditTrailService.recordPermissionChange(
                operatorId, "ROLE", roleId, "UPDATE", request.getChangeReason().trim(), before, after);
        auditTrailService.recordOperation(
                operatorId, "SYS", "UPDATE", "SYS_ROLE", roleId,
                request.getChangeReason().trim(), before, after);
        return after;
    }

    @Transactional(rollbackFor = Exception.class)
    public void assignRolePermissions(Long roleId, RolePermissionAssignRequest request) {
        Long operatorId = currentUserService.requireUserId();
        requireRole(roleId);
        Set<Long> targetPermissionIds = sanitizeIds(request.getPermissionIds(), "权限ID不能为空");
        loadActivePermissions(targetPermissionIds);

        List<SysRolePermission> existingLinks = rolePermissionMapper.selectList(
                Wrappers.<SysRolePermission>lambdaQuery().eq(SysRolePermission::getRoleId, roleId));
        Set<Long> beforePermissionIds = existingLinks.stream()
                .map(SysRolePermission::getPermissionId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<Long, SysRolePermission> linksByPermissionId = existingLinks.stream()
                .collect(Collectors.toMap(SysRolePermission::getPermissionId, Function.identity()));

        for (SysRolePermission link : existingLinks) {
            if (!targetPermissionIds.contains(link.getPermissionId())) {
                rolePermissionMapper.deleteById(link.getId());
            }
        }
        for (Long permissionId : targetPermissionIds) {
            if (!linksByPermissionId.containsKey(permissionId)) {
                SysRolePermission link = new SysRolePermission();
                link.setRoleId(roleId);
                link.setPermissionId(permissionId);
                link.setCreatedBy(operatorId);
                rolePermissionMapper.insert(link);
            }
        }

        auditTrailService.recordPermissionChange(
                operatorId, "ROLE_PERMISSION", roleId, "UPDATE", request.getReason().trim(),
                beforePermissionIds, targetPermissionIds);
        auditTrailService.recordOperation(
                operatorId, "SYS", "ASSIGN_PERMISSION", "SYS_ROLE", roleId,
                request.getReason().trim(), beforePermissionIds, targetPermissionIds);
    }

    @Transactional(readOnly = true)
    public RoleVO getRole(Long roleId) {
        return toRoleVO(requireRole(roleId));
    }

    @Transactional(readOnly = true)
    public PageResult<RoleVO> pageRoles(RolePageQuery query) {
        Page<SysRole> page = new Page<>(query.getPageNo(), query.getPageSize());
        LambdaQueryWrapper<SysRole> wrapper = Wrappers.<SysRole>lambdaQuery()
                .and(StringUtils.hasText(query.getKeyword()), condition -> condition
                        .like(SysRole::getRoleCode, trim(query.getKeyword()))
                        .or()
                        .like(SysRole::getRoleName, trim(query.getKeyword())))
                .eq(StringUtils.hasText(query.getStatus()), SysRole::getStatus, trim(query.getStatus()))
                .orderByAsc(SysRole::getRoleCode);
        Page<SysRole> result = roleMapper.selectPage(page, wrapper);
        return PageResult.of(
                result.getRecords().stream().map(this::toRoleVO).toList(),
                result.getTotal(), query.getPageNo(), query.getPageSize());
    }

    @Transactional(rollbackFor = Exception.class)
    public PermissionVO createPermission(PermissionCreateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        String permissionCode = request.getPermissionCode().trim();
        if (permissionMapper.selectCount(Wrappers.<SysPermission>lambdaQuery()
                .eq(SysPermission::getPermissionCode, permissionCode)) > 0) {
            throw new BizException(409, "权限编码已存在");
        }
        validatePermissionParent(null, request.getParentId());

        SysPermission permission = new SysPermission();
        permission.setParentId(request.getParentId());
        permission.setPermissionCode(permissionCode);
        applyPermissionFields(permission, request.getPermissionName(), request.getPermissionType(),
                request.getModuleCode(), request.getResourceKey(), request.getRoutePath(),
                request.getHttpMethod(), request.getApiPattern(), request.getSortOrder(),
                request.getDescription());
        permission.setStatus(ActivationStatus.ACTIVE.name());
        permission.setCreatedBy(operatorId);
        permission.setUpdatedBy(operatorId);
        permissionMapper.insert(permission);

        PermissionVO result = toPermissionVO(permission);
        auditTrailService.recordPermissionChange(
                operatorId, "PERMISSION", permission.getId(), "CREATE", "创建基础权限", null, result);
        auditTrailService.recordOperation(
                operatorId, "SYS", "CREATE", "SYS_PERMISSION", permission.getId(),
                "创建基础权限", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public PermissionVO updatePermission(Long permissionId, PermissionUpdateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        SysPermission permission = requirePermission(permissionId);
        PermissionVO before = toPermissionVO(permission);
        validatePermissionParent(permissionId, request.getParentId());

        permission.setParentId(request.getParentId());
        applyPermissionFields(permission, request.getPermissionName(), request.getPermissionType(),
                request.getModuleCode(), request.getResourceKey(), request.getRoutePath(),
                request.getHttpMethod(), request.getApiPattern(), request.getSortOrder(),
                request.getDescription());
        permission.setStatus(request.getStatus().trim());
        permission.setUpdatedBy(operatorId);
        ensureUpdated(permissionMapper.updateById(permission), "权限已被其他操作修改，请刷新后重试");

        PermissionVO after = toPermissionVO(requirePermission(permissionId));
        auditTrailService.recordPermissionChange(
                operatorId, "PERMISSION", permissionId, "UPDATE", request.getChangeReason().trim(), before, after);
        auditTrailService.recordOperation(
                operatorId, "SYS", "UPDATE", "SYS_PERMISSION", permissionId,
                request.getChangeReason().trim(), before, after);
        return after;
    }

    @Transactional(readOnly = true)
    public List<PermissionVO> permissionTree(boolean includeDisabled) {
        List<SysPermission> permissions = permissionMapper.selectList(Wrappers.<SysPermission>lambdaQuery()
                .eq(!includeDisabled, SysPermission::getStatus, ActivationStatus.ACTIVE.name())
                .orderByAsc(SysPermission::getSortOrder)
                .orderByAsc(SysPermission::getId));
        return buildPermissionTree(permissions);
    }

    @Transactional(readOnly = true)
    public CurrentUserVO currentUser() {
        SysUser user = currentUserService.requireUser();
        CurrentUserVO vo = new CurrentUserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setDisplayName(user.getDisplayName());
        vo.setDepartmentId(user.getDepartmentId());
        SysDepartment department = departmentMapper.selectById(user.getDepartmentId());
        vo.setDepartmentName(department == null ? null : department.getDepartmentName());
        vo.setRoleCodes(authorizationMapper.selectRoleCodesByUserId(user.getId()));
        vo.setPermissionCodes(authorizationMapper.selectPermissionCodesByUserId(user.getId()));
        return vo;
    }

    private UserVO toUserVO(SysUser user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setDisplayName(user.getDisplayName());
        vo.setDepartmentId(user.getDepartmentId());
        SysDepartment department = departmentMapper.selectById(user.getDepartmentId());
        vo.setDepartmentName(department == null ? null : department.getDepartmentName());
        vo.setMobile(user.getMobile());
        vo.setEmail(user.getEmail());
        vo.setStatus(user.getStatus());
        vo.setLastLoginAt(user.getLastLoginAt());
        vo.setCreatedAt(user.getCreatedAt());
        vo.setUpdatedAt(user.getUpdatedAt());
        vo.setRoles(loadUserRoles(user.getId()));
        return vo;
    }

    private List<RoleSimpleVO> loadUserRoles(Long userId) {
        LocalDateTime now = nowUtc();
        List<SysUserRole> links = userRoleMapper.selectList(Wrappers.<SysUserRole>lambdaQuery()
                .eq(SysUserRole::getUserId, userId)
                .eq(SysUserRole::getStatus, UserRoleStatus.ACTIVE.name())
                .le(SysUserRole::getValidFrom, now)
                .and(wrapper -> wrapper.isNull(SysUserRole::getValidTo).or().ge(SysUserRole::getValidTo, now)));
        if (links.isEmpty()) {
            return List.of();
        }
        Map<Long, SysRole> roles = roleMapper.selectByIds(
                        links.stream().map(SysUserRole::getRoleId).toList()).stream()
                .collect(Collectors.toMap(SysRole::getId, Function.identity()));
        return links.stream()
                .map(link -> roles.get(link.getRoleId()))
                .filter(role -> role != null)
                .map(this::toRoleSimpleVO)
                .sorted(Comparator.comparing(RoleSimpleVO::getRoleCode))
                .toList();
    }

    private RoleVO toRoleVO(SysRole role) {
        RoleVO vo = new RoleVO();
        vo.setId(role.getId());
        vo.setRoleCode(role.getRoleCode());
        vo.setRoleName(role.getRoleName());
        vo.setRiskLevel(role.getRiskLevel());
        vo.setDescription(role.getDescription());
        vo.setStatus(role.getStatus());
        vo.setIsBuiltin(role.getIsBuiltin());
        vo.setCreatedAt(role.getCreatedAt());
        vo.setUpdatedAt(role.getUpdatedAt());

        List<SysRolePermission> links = rolePermissionMapper.selectList(
                Wrappers.<SysRolePermission>lambdaQuery().eq(SysRolePermission::getRoleId, role.getId()));
        if (!links.isEmpty()) {
            List<SysPermission> permissions = permissionMapper.selectByIds(
                    links.stream().map(SysRolePermission::getPermissionId).toList());
            vo.setPermissions(permissions.stream()
                    .sorted(Comparator.comparing(SysPermission::getSortOrder).thenComparing(SysPermission::getId))
                    .map(this::toPermissionVO)
                    .toList());
        }
        return vo;
    }

    private RoleSimpleVO toRoleSimpleVO(SysRole role) {
        RoleSimpleVO vo = new RoleSimpleVO();
        vo.setId(role.getId());
        vo.setRoleCode(role.getRoleCode());
        vo.setRoleName(role.getRoleName());
        vo.setRiskLevel(role.getRiskLevel());
        vo.setStatus(role.getStatus());
        return vo;
    }

    private PermissionVO toPermissionVO(SysPermission permission) {
        PermissionVO vo = new PermissionVO();
        vo.setId(permission.getId());
        vo.setParentId(permission.getParentId());
        vo.setPermissionCode(permission.getPermissionCode());
        vo.setPermissionName(permission.getPermissionName());
        vo.setPermissionType(permission.getPermissionType());
        vo.setModuleCode(permission.getModuleCode());
        vo.setResourceKey(permission.getResourceKey());
        vo.setRoutePath(permission.getRoutePath());
        vo.setHttpMethod(permission.getHttpMethod());
        vo.setApiPattern(permission.getApiPattern());
        vo.setStatus(permission.getStatus());
        vo.setSortOrder(permission.getSortOrder());
        vo.setDescription(permission.getDescription());
        return vo;
    }

    private List<PermissionVO> buildPermissionTree(List<SysPermission> permissions) {
        Map<Long, PermissionVO> nodes = permissions.stream()
                .map(this::toPermissionVO)
                .collect(Collectors.toMap(
                        PermissionVO::getId,
                        Function.identity(),
                        (left, right) -> left,
                        LinkedHashMap::new));
        List<PermissionVO> roots = new ArrayList<>();
        for (PermissionVO node : nodes.values()) {
            PermissionVO parent = node.getParentId() == null ? null : nodes.get(node.getParentId());
            if (parent == null) {
                roots.add(node);
            } else {
                parent.getChildren().add(node);
            }
        }
        return roots;
    }

    private void applyPermissionFields(
            SysPermission permission,
            String permissionName,
            String permissionType,
            String moduleCode,
            String resourceKey,
            String routePath,
            String httpMethod,
            String apiPattern,
            Integer sortOrder,
            String description) {
        permission.setPermissionName(permissionName.trim());
        permission.setPermissionType(permissionType.trim());
        permission.setModuleCode(moduleCode.trim());
        permission.setResourceKey(trimToNull(resourceKey));
        permission.setRoutePath(trimToNull(routePath));
        permission.setHttpMethod(trimToNull(httpMethod));
        permission.setApiPattern(trimToNull(apiPattern));
        permission.setSortOrder(sortOrder == null ? 0 : sortOrder);
        permission.setDescription(trimToNull(description));
    }

    private void validatePermissionParent(Long permissionId, Long parentId) {
        if (parentId == null) {
            return;
        }
        if (parentId.equals(permissionId)) {
            throw new BizException(409, "权限父节点不能指向自身");
        }
        SysPermission parent = requirePermission(parentId);
        Set<Long> visited = new HashSet<>();
        while (parent != null) {
            if (!visited.add(parent.getId())) {
                throw new BizException(409, "现有权限树已包含环形关系");
            }
            if (permissionId != null && permissionId.equals(parent.getId())) {
                throw new BizException(409, "权限父节点不能选择自身的子节点");
            }
            parent = parent.getParentId() == null ? null : permissionMapper.selectById(parent.getParentId());
        }
    }

    private Map<Long, SysRole> loadActiveRoles(Set<Long> roleIds) {
        if (roleIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, SysRole> roles = roleMapper.selectByIds(roleIds).stream()
                .collect(Collectors.toMap(SysRole::getId, Function.identity()));
        if (roles.size() != roleIds.size()) {
            throw new BizException(404, "部分角色不存在");
        }
        roles.values().stream()
                .filter(role -> !ActivationStatus.ACTIVE.name().equals(role.getStatus()))
                .findFirst()
                .ifPresent(role -> {
                    throw new BizException(409, "不能分配已停用角色：" + role.getRoleName());
                });
        return roles;
    }

    private void loadActivePermissions(Set<Long> permissionIds) {
        if (permissionIds.isEmpty()) {
            return;
        }
        List<SysPermission> permissions = permissionMapper.selectByIds(permissionIds);
        if (permissions.size() != permissionIds.size()) {
            throw new BizException(404, "部分权限不存在");
        }
        permissions.stream()
                .filter(permission -> !ActivationStatus.ACTIVE.name().equals(permission.getStatus()))
                .findFirst()
                .ifPresent(permission -> {
                    throw new BizException(409, "不能配置已停用权限：" + permission.getPermissionName());
                });
    }

    private void validateRoleConflicts(Set<Long> roleIds) {
        if (roleIds.size() < 2) {
            return;
        }
        List<SysRoleConflict> conflicts = roleConflictMapper.selectList(Wrappers.<SysRoleConflict>lambdaQuery()
                .eq(SysRoleConflict::getStatus, ActivationStatus.ACTIVE.name())
                .and(wrapper -> wrapper.in(SysRoleConflict::getRoleAId, roleIds)
                        .or()
                        .in(SysRoleConflict::getRoleBId, roleIds)));
        conflicts.stream()
                .filter(conflict -> roleIds.contains(conflict.getRoleAId())
                        && roleIds.contains(conflict.getRoleBId()))
                .findFirst()
                .ifPresent(conflict -> {
                    throw new BizException(409, "角色互斥，不能同时分配：" + conflict.getReason());
                });
    }

    private SysUser requireUser(Long userId) {
        if (userId == null) {
            throw new BizException("用户ID不能为空");
        }
        SysUser user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return user;
    }

    private SysRole requireRole(Long roleId) {
        if (roleId == null) {
            throw new BizException("角色ID不能为空");
        }
        SysRole role = roleMapper.selectById(roleId);
        if (role == null) {
            throw new BizException(404, "角色不存在");
        }
        return role;
    }

    private SysPermission requirePermission(Long permissionId) {
        if (permissionId == null) {
            throw new BizException("权限ID不能为空");
        }
        SysPermission permission = permissionMapper.selectById(permissionId);
        if (permission == null) {
            throw new BizException(404, "权限不存在");
        }
        return permission;
    }

    private void ensureDepartmentActive(Long departmentId) {
        SysDepartment department = departmentMapper.selectById(departmentId);
        if (department == null) {
            throw new BizException(404, "所属部门不存在");
        }
        if (!ActivationStatus.ACTIVE.name().equals(department.getStatus())) {
            throw new BizException(409, "不能选择已停用部门");
        }
    }

    private Set<Long> sanitizeIds(Collection<Long> ids, String nullMessage) {
        Set<Long> result = new LinkedHashSet<>();
        if (ids == null) {
            return result;
        }
        for (Long id : ids) {
            if (id == null) {
                throw new BizException(nullMessage);
            }
            result.add(id);
        }
        return result;
    }

    private void validateUserStatus(String status) {
        if (StringUtils.hasText(status) && !USER_STATUSES.contains(status.trim())) {
            throw new BizException("用户状态查询条件非法");
        }
    }

    private void ensureUpdated(int affectedRows, String message) {
        if (affectedRows != 1) {
            throw new BizException(409, message);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private String trimToNull(String value) {
        String trimmed = trim(value);
        return StringUtils.hasText(trimmed) ? trimmed : null;
    }

    private LocalDateTime nowUtc() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }
}
