package com.fuhaha.pharmaerp.modules.quality.supplier.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import java.time.LocalDate;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("supplier_qualification")
public class SupplierQualification extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long supplierId;

    private String qualificationType;

    private String certificateNo;

    private String issuingAuthority;

    private LocalDate issuedOn;

    private LocalDate validFrom;

    private LocalDate validUntil;

    private String status;

    private String remark;
}
