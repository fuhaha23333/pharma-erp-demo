package com.fuhaha.pharmaerp.modules.quality.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "供应商分页查询")
public class SupplierPageQuery {

    @Min(1)
    private Long pageNo = 1L;

    @Min(1)
    @Max(100)
    private Long pageSize = 20L;

    @Size(max = 200)
    private String keyword;

    @Size(max = 24)
    @Pattern(
            regexp = "DRAFT|UNDER_REVIEW|APPROVED|REJECTED|EXPIRED|DISABLED",
            message = "供应商资质状态非法")
    private String qualificationStatus;

    @Size(max = 16)
    @Pattern(regexp = "PRODUCTION|WHOLESALE", message = "供应商类型非法")
    private String supplierType;
}
