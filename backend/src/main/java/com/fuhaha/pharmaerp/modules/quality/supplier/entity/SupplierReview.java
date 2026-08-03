package com.fuhaha.pharmaerp.modules.quality.supplier.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("supplier_review")
public class SupplierReview {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String reviewNo;

    private Long supplierId;

    private Integer reviewRound;

    private String status;

    private Long submittedBy;

    private LocalDateTime submittedAt;

    private Long reviewerId;

    private LocalDateTime reviewedAt;

    private String reviewOpinion;

    private String rejectionReason;

    private String qualificationSnapshot;

    private LocalDate approvedValidUntil;

    private LocalDateTime createdAt;
}
