package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "修改供应商草稿请求")
public class SupplierUpdateRequest {

    @NotBlank
    @Size(max = 200)
    private String supplierName;

    @NotBlank
    @Pattern(regexp = "PRODUCTION|WHOLESALE", message = "供应商类型只能为PRODUCTION或WHOLESALE")
    private String supplierType;

    @NotBlank
    @Size(max = 32)
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

    @NotBlank
    @Size(max = 500)
    private String changeReason;
}
