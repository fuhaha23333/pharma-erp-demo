package com.fuhaha.pharmaerp.common.entity;

import com.baomidou.mybatisplus.annotation.Version;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public abstract class BaseAuditEntity {

    private Long createdBy;

    private LocalDateTime createdAt;

    private Long updatedBy;

    private LocalDateTime updatedAt;

    @Version
    private Long version;
}
