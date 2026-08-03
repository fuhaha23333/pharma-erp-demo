package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import lombok.Data;

@Data
@Schema(description = "新增供应商资质请求")
public class SupplierQualificationRequest {

    @NotBlank
    @Pattern(
            regexp = "BUSINESS_LICENSE|DRUG_PRODUCTION_LICENSE|DRUG_OPERATION_LICENSE|AUTHORIZATION|OTHER",
            message = "供应商资质类型非法")
    @Schema(allowableValues = {
        "BUSINESS_LICENSE", "DRUG_PRODUCTION_LICENSE", "DRUG_OPERATION_LICENSE", "AUTHORIZATION", "OTHER"
    })
    private String qualificationType;

    @NotBlank
    @Size(max = 100)
    private String certificateNo;

    @Size(max = 200)
    private String issuingAuthority;

    private LocalDate issuedOn;

    private LocalDate validFrom;

    private LocalDate validUntil;

    @Size(max = 500)
    private String remark;
}
