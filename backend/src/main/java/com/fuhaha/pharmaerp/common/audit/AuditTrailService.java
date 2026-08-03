package com.fuhaha.pharmaerp.common.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fuhaha.pharmaerp.common.audit.entity.BusinessStatusHistory;
import com.fuhaha.pharmaerp.common.audit.entity.SysOperationLog;
import com.fuhaha.pharmaerp.common.audit.mapper.BusinessStatusHistoryMapper;
import com.fuhaha.pharmaerp.common.audit.mapper.SysOperationLogMapper;
import com.fuhaha.pharmaerp.modules.system.rbac.entity.SysPermissionChangeLog;
import com.fuhaha.pharmaerp.modules.system.rbac.mapper.SysPermissionChangeLogMapper;
import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Service
public class AuditTrailService {

    private final SysOperationLogMapper operationLogMapper;
    private final BusinessStatusHistoryMapper statusHistoryMapper;
    private final SysPermissionChangeLogMapper permissionChangeLogMapper;
    private final ObjectMapper objectMapper;

    public AuditTrailService(
            SysOperationLogMapper operationLogMapper,
            BusinessStatusHistoryMapper statusHistoryMapper,
            SysPermissionChangeLogMapper permissionChangeLogMapper,
            ObjectMapper objectMapper) {
        this.operationLogMapper = operationLogMapper;
        this.statusHistoryMapper = statusHistoryMapper;
        this.permissionChangeLogMapper = permissionChangeLogMapper;
        this.objectMapper = objectMapper;
    }

    public void recordOperation(
            Long operatorId,
            String moduleCode,
            String operationType,
            String businessType,
            Long businessId,
            String summary,
            Object beforeData,
            Object afterData) {
        SysOperationLog log = new SysOperationLog();
        log.setRequestId(resolveRequestId());
        log.setOperatorId(operatorId);
        log.setModuleCode(moduleCode);
        log.setOperationType(operationType);
        log.setBusinessType(businessType);
        log.setBusinessId(businessId);
        log.setOperationSummary(summary);
        log.setBeforeData(toJson(beforeData));
        log.setAfterData(toJson(afterData));
        log.setSuccess(1);
        log.setClientIp(limit(resolveRequestValue(HttpServletRequest::getRemoteAddr), 64));
        log.setUserAgent(limit(resolveRequestValue(request -> request.getHeader("User-Agent")), 500));
        log.setOccurredAt(nowUtc());
        operationLogMapper.insert(log);
    }

    public void recordStatusChange(
            String businessType,
            Long businessId,
            String businessNo,
            String fromStatus,
            String toStatus,
            String reason,
            Long operatorId) {
        BusinessStatusHistory history = new BusinessStatusHistory();
        history.setBusinessType(businessType);
        history.setBusinessId(businessId);
        history.setBusinessNo(businessNo);
        history.setFromStatus(fromStatus);
        history.setToStatus(toStatus);
        history.setChangeReason(reason);
        history.setOperatorId(operatorId);
        history.setOccurredAt(nowUtc());
        statusHistoryMapper.insert(history);
    }

    public void recordPermissionChange(
            Long operatorId,
            String targetType,
            Long targetId,
            String changeType,
            String reason,
            Object beforeData,
            Object afterData) {
        SysPermissionChangeLog log = new SysPermissionChangeLog();
        log.setChangeNo("PCL-" + UUID.randomUUID().toString().replace("-", ""));
        log.setOperatorId(operatorId);
        log.setTargetType(targetType);
        log.setTargetId(targetId);
        log.setChangeType(changeType);
        log.setChangeReason(reason);
        log.setBeforeData(toJson(beforeData));
        log.setAfterData(toJson(afterData));
        log.setOccurredAt(nowUtc());
        permissionChangeLogMapper.insert(log);
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("审计数据序列化失败", exception);
        }
    }

    private String resolveRequestId() {
        String requestId = resolveRequestValue(request -> request.getHeader("X-Request-Id"));
        return StringUtils.hasText(requestId) ? limit(requestId, 64) : UUID.randomUUID().toString();
    }

    private String limit(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    private String resolveRequestValue(RequestValueResolver resolver) {
        if (!(RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attributes)) {
            return null;
        }
        return resolver.resolve(attributes.getRequest());
    }

    private LocalDateTime nowUtc() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }

    @FunctionalInterface
    private interface RequestValueResolver {

        String resolve(HttpServletRequest request);
    }
}
