package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "供应商审核决定")
public class SupplierReviewDecisionRequest {

    @NotBlank
    @Pattern(regexp = "APPROVED|REJECTED", message = "审核决定只能为APPROVED或REJECTED")
    @Schema(allowableValues = {"APPROVED", "REJECTED"})
    private String decision;

    @Size(max = 1000)
    private String reviewOpinion;

    @Size(max = 1000)
    @Schema(description = "驳回原因；decision为REJECTED时必填")
    private String rejectionReason;
}
