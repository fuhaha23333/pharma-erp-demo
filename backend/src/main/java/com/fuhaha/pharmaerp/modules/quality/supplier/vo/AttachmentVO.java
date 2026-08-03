package com.fuhaha.pharmaerp.modules.quality.supplier.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@Schema(description = "资质附件元数据")
public class AttachmentVO {

    private Long id;

    private String attachmentNo;

    private String category;

    private String originalName;

    private String storageKey;

    private String contentType;

    private Long fileSize;

    private String sha256;

    private String status;

    private Long uploadedBy;

    private LocalDateTime uploadedAt;
}
