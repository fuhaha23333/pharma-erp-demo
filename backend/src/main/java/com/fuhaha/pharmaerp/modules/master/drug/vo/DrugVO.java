package com.fuhaha.pharmaerp.modules.master.drug.vo;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class DrugVO {

    private Long id;

    private String drugCode;

    private String drugName;

    private String genericName;

    private String approvalNo;

    private String dosageForm;

    private String specification;

    private String manufacturer;

    private String basicUnit;

    private String storageCondition;

    private String status;

    private String statusName;

    private String remark;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
