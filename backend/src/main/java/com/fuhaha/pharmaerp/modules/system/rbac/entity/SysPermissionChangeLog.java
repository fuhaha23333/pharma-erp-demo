package com.fuhaha.pharmaerp.modules.system.rbac.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("sys_permission_change_log")
public class SysPermissionChangeLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String changeNo;

    private Long operatorId;

    private String targetType;

    private Long targetId;

    private String changeType;

    private String changeReason;

    private String beforeData;

    private String afterData;

    private LocalDateTime occurredAt;
}
