package com.fuhaha.pharmaerp.modules.trace.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import lombok.Data;

@Data
@Schema(description = "批次当前库存分布")
public class BatchInventoryVO {

    @Schema(description = "库存余额主键")
    private Long inventoryBalanceId;

    @Schema(description = "仓库主键")
    private Long warehouseId;

    @Schema(description = "仓库编码")
    private String warehouseCode;

    @Schema(description = "仓库名称")
    private String warehouseName;

    @Schema(description = "库位主键")
    private Long warehouseLocationId;

    @Schema(description = "库位编码")
    private String locationCode;

    @Schema(description = "库位名称")
    private String locationName;

    @Schema(description = "库位类型", example = "NORMAL")
    private String locationType;

    @Schema(description = "账面总数量")
    private BigDecimal totalQuantity;

    @Schema(description = "可销售数量")
    private BigDecimal availableQuantity;

    @Schema(description = "已占用数量")
    private BigDecimal reservedQuantity;

    @Schema(description = "隔离数量")
    private BigDecimal quarantinedQuantity;

    @Schema(description = "库存状态", example = "ACTIVE")
    private String status;

    @Schema(description = "最后一笔库存流水号")
    private String lastLedgerNo;
}
