package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "登记供应商资质附件元数据；文件内容应先写入受控存储，本接口登记其不可变摘要")
public class AttachmentMetadataRequest {

    @NotBlank
    @Pattern(regexp = "LICENSE|AUTHORIZATION|OTHER", message = "附件分类非法")
    private String category;

    @NotBlank
    @Size(max = 255)
    private String originalName;

    @NotBlank
    @Size(max = 500)
    private String storageKey;

    @NotBlank
    @Size(max = 128)
    private String contentType;

    @NotNull
    @Min(0)
    private Long fileSize;

    @NotBlank
    @Pattern(regexp = "^[a-fA-F0-9]{64}$", message = "SHA-256摘要必须为64位十六进制字符")
    private String sha256;
}
