package com.fuhaha.pharmaerp.modules.system.rbac.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "权限节点")
public class PermissionVO {

    private Long id;

    private Long parentId;

    private String permissionCode;

    private String permissionName;

    private String permissionType;

    private String moduleCode;

    private String resourceKey;

    private String routePath;

    private String httpMethod;

    private String apiPattern;

    private String status;

    private Integer sortOrder;

    private String description;

    private List<PermissionVO> children = new ArrayList<>();
}
