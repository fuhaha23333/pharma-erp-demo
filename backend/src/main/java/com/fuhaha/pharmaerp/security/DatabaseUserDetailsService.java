package com.fuhaha.pharmaerp.security;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUser;
import com.fuhaha.pharmaerp.modules.system.rbac.enums.UserStatus;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysAuthorizationMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import java.util.LinkedHashSet;
import java.util.Set;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final SysUserMapper userMapper;
    private final SysAuthorizationMapper authorizationMapper;

    public DatabaseUserDetailsService(
            SysUserMapper userMapper,
            SysAuthorizationMapper authorizationMapper) {
        this.userMapper = userMapper;
        this.authorizationMapper = authorizationMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        SysUser user = userMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                .eq(SysUser::getUsername, username));
        if (user == null) {
            throw new UsernameNotFoundException("用户不存在");
        }

        Set<SimpleGrantedAuthority> authorities = new LinkedHashSet<>();
        authorizationMapper.selectRoleCodesByUserId(user.getId()).stream()
                .map(roleCode -> new SimpleGrantedAuthority("ROLE_" + roleCode))
                .forEach(authorities::add);
        authorizationMapper.selectPermissionCodesByUserId(user.getId()).stream()
                .map(SimpleGrantedAuthority::new)
                .forEach(authorities::add);

        boolean active = UserStatus.ACTIVE.name().equals(user.getStatus());
        boolean accountNonLocked = !UserStatus.LOCKED.name().equals(user.getStatus());
        return User.withUsername(user.getUsername())
                .password(user.getPasswordHash())
                .authorities(authorities)
                .disabled(!active)
                .accountLocked(!accountNonLocked)
                .build();
    }
}
