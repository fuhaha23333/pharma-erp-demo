package com.fuhaha.pharmaerp.modules.trace.service;

import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.modules.trace.mapper.BatchTraceMapper;
import com.fuhaha.pharmaerp.modules.trace.vo.DrugBatchTraceVO;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class BatchTraceService {

    private final BatchTraceMapper batchTraceMapper;
    private final CurrentUserService currentUserService;
    private final AuditTrailService auditTrailService;

    public BatchTraceService(
            BatchTraceMapper batchTraceMapper,
            CurrentUserService currentUserService,
            AuditTrailService auditTrailService) {
        this.batchTraceMapper = batchTraceMapper;
        this.currentUserService = currentUserService;
        this.auditTrailService = auditTrailService;
    }

    @Transactional
    public List<DrugBatchTraceVO> traceByBatchNo(String batchNo, String drugCode) {
        if (!StringUtils.hasText(batchNo)) {
            throw new BizException("生产批号不能为空");
        }

        String normalizedBatchNo = batchNo.trim();
        String normalizedDrugCode = StringUtils.hasText(drugCode) ? drugCode.trim() : null;
        List<DrugBatchTraceVO> traces = batchTraceMapper.selectBatches(normalizedBatchNo, normalizedDrugCode);
        if (traces.isEmpty()) {
            throw new BizException(404, "未查询到对应药品批次");
        }

        traces.forEach(trace -> {
            trace.setInventories(batchTraceMapper.selectInventories(trace.getBatchId()));
            trace.setEvents(batchTraceMapper.selectEvents(trace.getBatchId()));
        });

        auditTrailService.recordOperation(
                currentUserService.requireUserId(),
                "TRACE",
                "QUERY",
                "DRUG_BATCH",
                traces.size() == 1 ? traces.get(0).getBatchId() : null,
                "按生产批号查询药品完整生命周期",
                null,
                Map.of(
                        "batchNo", normalizedBatchNo,
                        "drugCode", normalizedDrugCode == null ? "" : normalizedDrugCode,
                        "matchedBatchCount", traces.size()));
        return traces;
    }
}
