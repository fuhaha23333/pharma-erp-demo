package com.fuhaha.pharmaerp.modules.master.drug.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DrugUpdateDTO {

    @NotBlank(message = "药品名称不能为空")
    @Size(max = 100, message = "药品名称长度不能超过100个字符")
    private String drugName;

    @NotBlank(message = "药品通用名称不能为空")
    @Size(max = 100, message = "药品通用名称长度不能超过100个字符")
    private String genericName;

    @NotBlank(message = "批准文号不能为空")
    @Size(max = 64, message = "批准文号长度不能超过64个字符")
    private String approvalNo;

    @NotBlank(message = "剂型不能为空")
    @Size(max = 50, message = "剂型长度不能超过50个字符")
    private String dosageForm;

    @NotBlank(message = "规格不能为空")
    @Size(max = 100, message = "规格长度不能超过100个字符")
    private String specification;

    @NotBlank(message = "生产厂家不能为空")
    @Size(max = 150, message = "生产厂家长度不能超过150个字符")
    private String manufacturer;

    @NotBlank(message = "基本单位不能为空")
    @Size(max = 20, message = "基本单位长度不能超过20个字符")
    private String basicUnit;

    @NotBlank(message = "储存条件不能为空")
    @Size(max = 50, message = "储存条件长度不能超过50个字符")
    private String storageCondition;

    @Size(max = 500, message = "备注长度不能超过500个字符")
    private String remark;
}
