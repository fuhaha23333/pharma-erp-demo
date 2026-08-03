package com.fuhaha.pharmaerp.modules.trace.controller;

import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.trace.service.BatchTraceService;
import com.fuhaha.pharmaerp.modules.trace.vo.DrugBatchTraceVO;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/trace/batches")
@Tag(name = "药品追溯", description = "根据生产批号查询生产、采购、验收、库存、销售及客户去向")
public class BatchTraceController {

    private final BatchTraceService batchTraceService;

    public BatchTraceController(BatchTraceService batchTraceService) {
        this.batchTraceService = batchTraceService;
    }

    @GetMapping("/{batchNo}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.TRACE_READ + "')")
    @Operation(
            summary = "按生产批号查询完整生命周期",
            description = "同一生产批号可能对应多个药品；可传drugCode精确筛选。结果内事件按时间正序排列。")
    public Result<List<DrugBatchTraceVO>> traceByBatchNo(
            @Parameter(description = "生产批号", required = true, example = "20260801A")
            @PathVariable String batchNo,
            @Parameter(description = "药品编码；生产批号不唯一时用于精确筛选")
            @RequestParam(required = false) String drugCode) {
        return Result.success(batchTraceService.traceByBatchNo(batchNo, drugCode));
    }
}
