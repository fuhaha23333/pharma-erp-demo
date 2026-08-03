package com.fuhaha.pharmaerp.modules.system.rbac.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface SysAuthorizationMapper {

    @Select("""
            SELECT DISTINCT r.role_code
            FROM sys_user_role ur
            JOIN sys_role r ON r.id = ur.role_id
            WHERE ur.user_id = #{userId}
              AND ur.status = 'ACTIVE'
              AND r.status = 'ACTIVE'
              AND ur.valid_from <= UTC_TIMESTAMP(3)
              AND (ur.valid_to IS NULL OR ur.valid_to >= UTC_TIMESTAMP(3))
            ORDER BY r.role_code
            """)
    List<String> selectRoleCodesByUserId(@Param("userId") Long userId);

    @Select("""
            SELECT DISTINCT p.permission_code
            FROM sys_user_role ur
            JOIN sys_role r ON r.id = ur.role_id
            JOIN sys_role_permission rp ON rp.role_id = r.id
            JOIN sys_permission p ON p.id = rp.permission_id
            WHERE ur.user_id = #{userId}
              AND ur.status = 'ACTIVE'
              AND r.status = 'ACTIVE'
              AND p.status = 'ACTIVE'
              AND ur.valid_from <= UTC_TIMESTAMP(3)
              AND (ur.valid_to IS NULL OR ur.valid_to >= UTC_TIMESTAMP(3))
            ORDER BY p.permission_code
            """)
    List<String> selectPermissionCodesByUserId(@Param("userId") Long userId);
}
