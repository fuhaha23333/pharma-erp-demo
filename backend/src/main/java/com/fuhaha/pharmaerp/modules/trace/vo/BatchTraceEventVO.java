package com.fuhaha.pharmaerp.modules.trace.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@Schema(description = "药品批次生命周期事件")
public class BatchTraceEventVO {

    @Schema(description = "事件主键")
    private Long eventId;

    @Schema(description = "事件编号")
    private String eventNo;

    @Schema(description = "事件类型", example = "ACCEPTED")
    private String eventType;

    @Schema(description = "上游供应商编码")
    private String supplierCode;

    @Schema(description = "上游供应商名称")
    private String supplierName;

    @Schema(description = "下游客户编码")
    private String customerCode;

    @Schema(description = "下游客户名称")
    private String customerName;

    @Schema(description = "仓库编码")
    private String warehouseCode;

    @Schema(description = "仓库名称")
    private String warehouseName;

    @Schema(description = "库位编码")
    private String locationCode;

    @Schema(description = "库位名称")
    private String locationName;

    @Schema(description = "关联库存流水号")
    private String inventoryLedgerNo;

    @Schema(description = "来源业务类型")
    private String businessType;

    @Schema(description = "来源业务主键")
    private Long businessId;

    @Schema(description = "来源业务编号")
    private String businessNo;

    @Schema(description = "事件数量")
    private BigDecimal quantity;

    @Schema(description = "事件证据快照，JSON文本")
    private String eventData;

    @Schema(description = "操作人主键")
    private Long operatorId;

    @Schema(description = "操作人账号")
    private String operatorUsername;

    @Schema(description = "操作人姓名")
    private String operatorRealName;

    @Schema(description = "发生时间（UTC）")
    private LocalDateTime occurredAt;
}
