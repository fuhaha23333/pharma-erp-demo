package com.fuhaha.pharmaerp.common.audit.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("sys_operation_log")
public class SysOperationLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String requestId;

    private Long operatorId;

    private String moduleCode;

    private String operationType;

    private String businessType;

    private Long businessId;

    private String operationSummary;

    private String beforeData;

    private String afterData;

    private Integer success;

    private String failureReason;

    private String clientIp;

    private String userAgent;

    private LocalDateTime occurredAt;
}
