package com.fuhaha.pharmaerp.modules.quality.supplier.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.AttachmentMetadataRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierReviewDecisionRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.Supplier;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.SupplierQualification;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.SupplierReview;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierAttachmentMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierQualificationMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierReviewMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierReviewVO;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class SupplierServiceTest {

    @Mock
    private SupplierMapper supplierMapper;

    @Mock
    private SupplierQualificationMapper qualificationMapper;

    @Mock
    private SupplierReviewMapper reviewMapper;

    @Mock
    private SupplierAttachmentMapper attachmentMapper;

    @Mock
    private CurrentUserService currentUserService;

    @Mock
    private AuditTrailService auditTrailService;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private SupplierService supplierService;

    @Test
    void shouldBlockSubmissionWhenRequiredQualificationsAreMissing() {
        Supplier supplier = supplier(1L, "DRAFT", "WHOLESALE");
        when(currentUserService.requireUserId()).thenReturn(10L);
        when(supplierMapper.selectById(1L)).thenReturn(supplier);
        when(qualificationMapper.selectList(any())).thenReturn(List.of());

        assertThatThrownBy(() -> supplierService.submitForReview(1L))
                .isInstanceOf(BizException.class)
                .hasMessageContaining("缺少必需资质")
                .extracting("code")
                .isEqualTo(409);
    }

    @Test
    void shouldBlockSubmitterFromReviewingOwnSubmission() {
        Supplier supplier = supplier(1L, "UNDER_REVIEW", "WHOLESALE");
        SupplierReview review = new SupplierReview();
        review.setId(20L);
        review.setSupplierId(1L);
        review.setSubmittedBy(10L);
        review.setStatus("PENDING");
        SupplierReviewDecisionRequest request = new SupplierReviewDecisionRequest();
        request.setDecision("APPROVED");

        when(currentUserService.requireUserId()).thenReturn(10L);
        when(supplierMapper.selectById(1L)).thenReturn(supplier);
        when(reviewMapper.selectById(20L)).thenReturn(review);

        assertThatThrownBy(() -> supplierService.review(1L, 20L, request))
                .isInstanceOf(BizException.class)
                .hasMessageContaining("不能审核自己的")
                .extracting("code")
                .isEqualTo(409);
    }

    @Test
    void shouldRejectLicenseCategoryForAuthorizationQualification() {
        Supplier supplier = supplier(1L, "DRAFT", "WHOLESALE");
        SupplierQualification qualification = qualification(2L, "AUTHORIZATION", null);
        AttachmentMetadataRequest request = new AttachmentMetadataRequest();
        request.setCategory("LICENSE");

        when(currentUserService.requireUserId()).thenReturn(10L);
        when(supplierMapper.selectById(1L)).thenReturn(supplier);
        when(qualificationMapper.selectById(2L)).thenReturn(qualification);

        assertThatThrownBy(() -> supplierService.registerAttachment(1L, 2L, request))
                .isInstanceOf(BizException.class)
                .hasMessageContaining("AUTHORIZATION")
                .extracting("code")
                .isEqualTo(400);
    }

    @Test
    void shouldAllowAValidReplacementWhenAnOldCertificateExpired() throws Exception {
        Supplier supplier = supplier(1L, "DRAFT", "WHOLESALE");
        List<SupplierQualification> qualifications = List.of(
                qualification(1L, "BUSINESS_LICENSE", LocalDate.now().minusDays(1)),
                qualification(2L, "BUSINESS_LICENSE", LocalDate.now().plusYears(1)),
                qualification(3L, "DRUG_OPERATION_LICENSE", LocalDate.now().plusYears(2)),
                qualification(4L, "AUTHORIZATION", null));

        when(currentUserService.requireUserId()).thenReturn(10L);
        when(supplierMapper.selectById(1L)).thenReturn(supplier);
        when(qualificationMapper.selectList(any())).thenReturn(qualifications);
        when(attachmentMapper.selectCount(any())).thenReturn(1L);
        when(attachmentMapper.selectList(any())).thenReturn(List.of());
        when(reviewMapper.selectOne(any())).thenReturn(null);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(reviewMapper.insert(any(SupplierReview.class))).thenAnswer(invocation -> {
            SupplierReview review = invocation.getArgument(0);
            review.setId(30L);
            return 1;
        });
        when(supplierMapper.updateById(any(Supplier.class))).thenReturn(1);

        SupplierReviewVO result = supplierService.submitForReview(1L);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        assertThat(supplier.getQualificationStatus()).isEqualTo("UNDER_REVIEW");
    }

    private Supplier supplier(Long id, String status, String type) {
        Supplier supplier = new Supplier();
        supplier.setId(id);
        supplier.setSupplierCode("SUP-001");
        supplier.setSupplierType(type);
        supplier.setQualificationStatus(status);
        supplier.setVersion(0L);
        return supplier;
    }

    private SupplierQualification qualification(Long id, String type, LocalDate validUntil) {
        SupplierQualification qualification = new SupplierQualification();
        qualification.setId(id);
        qualification.setSupplierId(1L);
        qualification.setQualificationType(type);
        qualification.setCertificateNo("CERT-" + id);
        qualification.setValidFrom(LocalDate.now().minusYears(1));
        qualification.setValidUntil(validUntil);
        qualification.setStatus("DRAFT");
        qualification.setVersion(0L);
        return qualification;
    }
}
