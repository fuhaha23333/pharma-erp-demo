package com.fuhaha.pharmaerp.modules.trace.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.modules.trace.mapper.BatchTraceMapper;
import com.fuhaha.pharmaerp.modules.trace.vo.BatchInventoryVO;
import com.fuhaha.pharmaerp.modules.trace.vo.BatchTraceEventVO;
import com.fuhaha.pharmaerp.modules.trace.vo.DrugBatchTraceVO;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BatchTraceServiceTest {

    @Mock
    private BatchTraceMapper batchTraceMapper;

    @Mock
    private CurrentUserService currentUserService;

    @Mock
    private AuditTrailService auditTrailService;

    @InjectMocks
    private BatchTraceService batchTraceService;

    @Test
    void shouldAssembleInventoryEventsAndAuditTheQuery() {
        DrugBatchTraceVO batch = new DrugBatchTraceVO();
        batch.setBatchId(10L);
        batch.setBatchNo("LOT-001");
        BatchInventoryVO inventory = new BatchInventoryVO();
        BatchTraceEventVO event = new BatchTraceEventVO();

        when(batchTraceMapper.selectBatches("LOT-001", "DRUG-001")).thenReturn(List.of(batch));
        when(batchTraceMapper.selectInventories(10L)).thenReturn(List.of(inventory));
        when(batchTraceMapper.selectEvents(10L)).thenReturn(List.of(event));
        when(currentUserService.requireUserId()).thenReturn(7L);

        List<DrugBatchTraceVO> result = batchTraceService.traceByBatchNo(" LOT-001 ", " DRUG-001 ");

        assertThat(result).containsExactly(batch);
        assertThat(batch.getInventories()).containsExactly(inventory);
        assertThat(batch.getEvents()).containsExactly(event);
        verify(auditTrailService).recordOperation(
                eq(7L), eq("TRACE"), eq("QUERY"), eq("DRUG_BATCH"), eq(10L),
                eq("按生产批号查询药品完整生命周期"), eq(null), any());
    }

    @Test
    void shouldReturnNotFoundWhenBatchDoesNotExist() {
        when(batchTraceMapper.selectBatches("UNKNOWN", null)).thenReturn(List.of());

        assertThatThrownBy(() -> batchTraceService.traceByBatchNo("UNKNOWN", null))
                .isInstanceOf(BizException.class)
                .extracting("code")
                .isEqualTo(404);
    }
}
