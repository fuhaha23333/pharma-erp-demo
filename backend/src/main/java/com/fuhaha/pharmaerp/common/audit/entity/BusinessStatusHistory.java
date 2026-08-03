package com.fuhaha.pharmaerp.common.audit.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("business_status_history")
public class BusinessStatusHistory {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String businessType;

    private Long businessId;

    private String businessNo;

    private String fromStatus;

    private String toStatus;

    private String changeReason;

    private Long operatorId;

    private LocalDateTime occurredAt;
}
