package com.fuhaha.pharmaerp.modules.system.rbac.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "当前登录用户及授权信息")
public class CurrentUserVO {

    private Long id;

    private String username;

    private String displayName;

    private Long departmentId;

    private String departmentName;

    private List<String> roleCodes = new ArrayList<>();

    private List<String> permissionCodes = new ArrayList<>();
}
