package com.fuhaha.pharmaerp.modules.master.drug.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DrugPageQueryDTO {

    @Min(value = 1, message = "页码不能小于1")
    private Long pageNo = 1L;

    @Min(value = 1, message = "每页条数不能小于1")
    @Max(value = 100, message = "每页条数不能超过100")
    private Long pageSize = 10L;

    @Size(max = 32, message = "药品编码长度不能超过32个字符")
    private String drugCode;

    @Size(max = 100, message = "药品名称长度不能超过100个字符")
    private String drugName;

    @Size(max = 100, message = "药品通用名称长度不能超过100个字符")
    private String genericName;

    @Size(max = 64, message = "批准文号长度不能超过64个字符")
    private String approvalNo;

    @Size(max = 150, message = "生产厂家长度不能超过150个字符")
    private String manufacturer;

    @Size(max = 20, message = "状态长度不能超过20个字符")
    private String status;
}
