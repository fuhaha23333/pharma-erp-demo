package com.fuhaha.pharmaerp.modules.quality.supplier.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "供应商资质及附件")
public class SupplierQualificationVO {

    private Long id;

    private String qualificationType;

    private String certificateNo;

    private String issuingAuthority;

    private LocalDate issuedOn;

    private LocalDate validFrom;

    private LocalDate validUntil;

    private String status;

    private String remark;

    private List<AttachmentVO> attachments = new ArrayList<>();
}
