package com.fuhaha.pharmaerp.modules.quality.supplier.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("supplier")
public class Supplier extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
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
}
