package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "创建供应商草稿请求")
public class SupplierCreateRequest {

    @NotBlank
    @Size(max = 32)
    @Schema(description = "供应商编码", example = "SUP-0001")
    private String supplierCode;

    @NotBlank
    @Size(max = 200)
    @Schema(description = "企业名称")
    private String supplierName;

    @NotBlank
    @Pattern(regexp = "PRODUCTION|WHOLESALE", message = "供应商类型只能为PRODUCTION或WHOLESALE")
    @Schema(description = "供应商类型", allowableValues = {"PRODUCTION", "WHOLESALE"})
    private String supplierType;

    @NotBlank
    @Size(max = 32)
    @Schema(description = "统一社会信用代码")
    private String unifiedSocialCreditCode;

    @Size(max = 100)
    private String contactName;

    @Size(max = 32)
    private String contactPhone;

    @Email
    @Size(max = 128)
    private String contactEmail;

    @Size(max = 500)
    private String address;
}
