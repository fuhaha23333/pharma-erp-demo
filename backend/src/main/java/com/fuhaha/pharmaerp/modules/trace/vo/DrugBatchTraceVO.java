package com.fuhaha.pharmaerp.modules.trace.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "一个药品批次的完整追溯结果")
public class DrugBatchTraceVO {

    @Schema(description = "批次主键")
    private Long batchId;

    @Schema(description = "系统批次编码")
    private String batchCode;

    @Schema(description = "生产批号")
    private String batchNo;

    @Schema(description = "药品主键")
    private Long drugId;

    @Schema(description = "药品编码")
    private String drugCode;

    @Schema(description = "药品商品名称")
    private String drugName;

    @Schema(description = "药品通用名称")
    private String genericName;

    @Schema(description = "批准文号或进口注册证号")
    private String approvalNo;

    @Schema(description = "剂型")
    private String dosageForm;

    @Schema(description = "规格")
    private String specification;

    @Schema(description = "基本计量单位")
    private String basicUnit;

    @Schema(description = "储存条件")
    private String storageCondition;

    @Schema(description = "生产企业主键")
    private Long manufacturerId;

    @Schema(description = "生产企业编码")
    private String manufacturerCode;

    @Schema(description = "生产企业名称")
    private String manufacturerName;

    @Schema(description = "生产日期")
    private LocalDate productionDate;

    @Schema(description = "有效期截止日")
    private LocalDate expiryDate;

    @Schema(description = "批次质量状态")
    private String qualityStatus;

    @Schema(description = "批次库存状态")
    private String stockStatus;

    @Schema(description = "当前库存分布")
    private List<BatchInventoryVO> inventories = new ArrayList<>();

    @Schema(description = "按发生时间升序排列的生命周期事件")
    private List<BatchTraceEventVO> events = new ArrayList<>();
}
