package com.fuhaha.pharmaerp.modules.quality.supplier.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@Schema(description = "供应商审核记录")
public class SupplierReviewVO {

    private Long id;

    private String reviewNo;

    private Integer reviewRound;

    private String status;

    private Long submittedBy;

    private LocalDateTime submittedAt;

    private Long reviewerId;

    private LocalDateTime reviewedAt;

    private String reviewOpinion;

    private String rejectionReason;

    private LocalDate approvedValidUntil;
}
