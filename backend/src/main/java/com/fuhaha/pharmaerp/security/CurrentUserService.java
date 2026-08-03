package com.fuhaha.pharmaerp.security;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysUser;
import com.fuhaha.pharmaerp.modules.system.rbac.enums.UserStatus;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysUserMapper;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class CurrentUserService {

    private final SysUserMapper userMapper;

    public CurrentUserService(SysUserMapper userMapper) {
        this.userMapper = userMapper;
    }

    public Long requireUserId() {
        return requireUser().getId();
    }

    public SysUser requireUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new BizException(401, "请先登录");
        }
        SysUser user = userMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                .eq(SysUser::getUsername, authentication.getName()));
        if (user == null || !UserStatus.ACTIVE.name().equals(user.getStatus())) {
            throw new BizException(401, "当前账号不存在或已停用");
        }
        return user;
    }
}
