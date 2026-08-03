package com.fuhaha.pharmaerp.modules.quality.supplier.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("sys_attachment")
public class SupplierAttachment {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String attachmentNo;

    private String businessType;

    private Long businessId;

    private String category;

    private String originalName;

    private String storageKey;

    private String contentType;

    private Long fileSize;

    private String sha256;

    private String status;

    private Long uploadedBy;

    private LocalDateTime uploadedAt;

    private Long invalidatedBy;

    private LocalDateTime invalidatedAt;

    private String invalidReason;
}
