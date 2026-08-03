package com.fuhaha.pharmaerp.modules.quality.supplier.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "供应商详情")
public class SupplierVO {

    private Long id;

    private String supplierCode;

    private String supplierName;

    private String supplierType;

    private String unifiedSocialCreditCode;

    private String contactName;

    private String contactPhone;

    private String contactEmail;

    private String address;

    private String qualificationStatus;

    private LocalDateTime approvedAt;

    private LocalDate validUntil;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private List<SupplierQualificationVO> qualifications = new ArrayList<>();

    private List<SupplierReviewVO> reviews = new ArrayList<>();
}
