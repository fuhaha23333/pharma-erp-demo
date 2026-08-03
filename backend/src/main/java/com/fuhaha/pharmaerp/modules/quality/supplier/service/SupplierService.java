package com.fuhaha.pharmaerp.modules.quality.supplier.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fuhaha.pharmaerp.common.audit.AuditTrailService;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.AttachmentMetadataRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierCreateRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierPageQuery;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierQualificationRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierReviewDecisionRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierUpdateRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.Supplier;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.SupplierAttachment;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.SupplierQualification;
import com.fuhaha.pharmaerp.modules.quality.supplier.entity.SupplierReview;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.AttachmentCategory;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.AttachmentStatus;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.SupplierQualificationStatus;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.SupplierQualificationType;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.SupplierReviewStatus;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.SupplierStatus;
import com.fuhaha.pharmaerp.modules.quality.supplier.enums.SupplierType;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierAttachmentMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierQualificationMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.mapper.SupplierReviewMapper;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.AttachmentVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierQualificationVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierReviewVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierVO;
import com.fuhaha.pharmaerp.security.CurrentUserService;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class SupplierService {

    private static final Set<String> EDITABLE_STATUSES = Set.of(
            SupplierStatus.DRAFT.name(), SupplierStatus.REJECTED.name());
    private static final Set<String> QUERY_STATUSES = Set.of(
            SupplierStatus.DRAFT.name(),
            SupplierStatus.UNDER_REVIEW.name(),
            SupplierStatus.APPROVED.name(),
            SupplierStatus.REJECTED.name(),
            SupplierStatus.EXPIRED.name(),
            SupplierStatus.DISABLED.name());
    private static final Set<String> SUBMITTABLE_QUALIFICATION_STATUSES = Set.of(
            SupplierQualificationStatus.DRAFT.name(), SupplierQualificationStatus.VALID.name());
    private static final String ATTACHMENT_BUSINESS_TYPE = "SUPPLIER_QUALIFICATION";

    private final SupplierMapper supplierMapper;
    private final SupplierQualificationMapper qualificationMapper;
    private final SupplierReviewMapper reviewMapper;
    private final SupplierAttachmentMapper attachmentMapper;
    private final CurrentUserService currentUserService;
    private final AuditTrailService auditTrailService;
    private final ObjectMapper objectMapper;

    public SupplierService(
            SupplierMapper supplierMapper,
            SupplierQualificationMapper qualificationMapper,
            SupplierReviewMapper reviewMapper,
            SupplierAttachmentMapper attachmentMapper,
            CurrentUserService currentUserService,
            AuditTrailService auditTrailService,
            ObjectMapper objectMapper) {
        this.supplierMapper = supplierMapper;
        this.qualificationMapper = qualificationMapper;
        this.reviewMapper = reviewMapper;
        this.attachmentMapper = attachmentMapper;
        this.currentUserService = currentUserService;
        this.auditTrailService = auditTrailService;
        this.objectMapper = objectMapper;
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierVO create(SupplierCreateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        String supplierCode = request.getSupplierCode().trim();
        String creditCode = request.getUnifiedSocialCreditCode().trim();
        ensureSupplierUnique(null, supplierCode, creditCode);

        Supplier supplier = new Supplier();
        supplier.setSupplierCode(supplierCode);
        applySupplierFields(supplier, request.getSupplierName(), request.getSupplierType(), creditCode,
                request.getContactName(), request.getContactPhone(), request.getContactEmail(), request.getAddress());
        supplier.setQualificationStatus(SupplierStatus.DRAFT.name());
        supplier.setCreatedBy(operatorId);
        supplier.setUpdatedBy(operatorId);
        supplierMapper.insert(supplier);

        SupplierVO result = getDetail(supplier.getId());
        auditTrailService.recordStatusChange(
                "SUPPLIER", supplier.getId(), supplier.getSupplierCode(), null,
                SupplierStatus.DRAFT.name(), "创建供应商草稿", operatorId);
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "CREATE", "SUPPLIER", supplier.getId(),
                "创建供应商草稿", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierVO update(Long supplierId, SupplierUpdateRequest request) {
        Long operatorId = currentUserService.requireUserId();
        Supplier supplier = requireEditableSupplier(supplierId);
        SupplierVO before = toSupplierVO(supplier, false);
        String creditCode = request.getUnifiedSocialCreditCode().trim();
        ensureSupplierUnique(supplierId, supplier.getSupplierCode(), creditCode);

        applySupplierFields(supplier, request.getSupplierName(), request.getSupplierType(), creditCode,
                request.getContactName(), request.getContactPhone(), request.getContactEmail(), request.getAddress());
        supplier.setUpdatedBy(operatorId);
        ensureUpdated(supplierMapper.updateById(supplier), "供应商已被其他操作修改，请刷新后重试");

        SupplierVO after = getDetail(supplierId);
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "UPDATE", "SUPPLIER", supplierId,
                request.getChangeReason().trim(), before, after);
        return after;
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierQualificationVO addQualification(Long supplierId, SupplierQualificationRequest request) {
        Long operatorId = currentUserService.requireUserId();
        requireEditableSupplier(supplierId);
        validateQualificationDates(request);

        SupplierQualification qualification = new SupplierQualification();
        qualification.setSupplierId(supplierId);
        applyQualificationFields(qualification, request);
        qualification.setStatus(SupplierQualificationStatus.DRAFT.name());
        qualification.setCreatedBy(operatorId);
        qualification.setUpdatedBy(operatorId);
        qualificationMapper.insert(qualification);

        SupplierQualificationVO result = toQualificationVO(qualification);
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "CREATE", "SUPPLIER_QUALIFICATION", qualification.getId(),
                "新增供应商资质", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierQualificationVO updateQualification(
            Long supplierId,
            Long qualificationId,
            SupplierQualificationRequest request) {
        Long operatorId = currentUserService.requireUserId();
        requireEditableSupplier(supplierId);
        SupplierQualification qualification = requireQualification(supplierId, qualificationId);
        SupplierQualificationVO before = toQualificationVO(qualification);
        validateQualificationDates(request);

        applyQualificationFields(qualification, request);
        qualification.setStatus(SupplierQualificationStatus.DRAFT.name());
        qualification.setUpdatedBy(operatorId);
        ensureUpdated(qualificationMapper.updateById(qualification), "供应商资质已被其他操作修改");

        SupplierQualificationVO after = toQualificationVO(requireQualification(supplierId, qualificationId));
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "UPDATE", "SUPPLIER_QUALIFICATION", qualificationId,
                "修改供应商资质", before, after);
        return after;
    }

    @Transactional(rollbackFor = Exception.class)
    public AttachmentVO registerAttachment(
            Long supplierId,
            Long qualificationId,
            AttachmentMetadataRequest request) {
        Long operatorId = currentUserService.requireUserId();
        requireEditableSupplier(supplierId);
        SupplierQualification qualification = requireQualification(supplierId, qualificationId);
        validateAttachmentCategory(qualification, request.getCategory().trim());

        SupplierAttachment attachment = new SupplierAttachment();
        attachment.setAttachmentNo("ATT-" + UUID.randomUUID().toString().replace("-", ""));
        attachment.setBusinessType(ATTACHMENT_BUSINESS_TYPE);
        attachment.setBusinessId(qualificationId);
        attachment.setCategory(request.getCategory().trim());
        attachment.setOriginalName(request.getOriginalName().trim());
        attachment.setStorageKey(request.getStorageKey().trim());
        attachment.setContentType(request.getContentType().trim());
        attachment.setFileSize(request.getFileSize());
        attachment.setSha256(request.getSha256().trim().toLowerCase());
        attachment.setStatus(AttachmentStatus.ACTIVE.name());
        attachment.setUploadedBy(operatorId);
        attachment.setUploadedAt(nowUtc());
        attachmentMapper.insert(attachment);

        AttachmentVO result = toAttachmentVO(attachment);
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "ATTACH", "SUPPLIER_QUALIFICATION", qualificationId,
                "登记供应商资质附件", null, result);
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierReviewVO submitForReview(Long supplierId) {
        Long operatorId = currentUserService.requireUserId();
        Supplier supplier = requireEditableSupplier(supplierId);
        List<SupplierQualification> qualifications = loadQualifications(supplierId);
        selectEffectiveRequiredQualifications(supplier, qualifications);

        SupplierReview latestReview = reviewMapper.selectOne(Wrappers.<SupplierReview>lambdaQuery()
                .eq(SupplierReview::getSupplierId, supplierId)
                .orderByDesc(SupplierReview::getReviewRound)
                .last("LIMIT 1"));
        int nextRound = latestReview == null ? 1 : latestReview.getReviewRound() + 1;
        List<SupplierQualificationVO> snapshot = qualifications.stream()
                .map(this::toQualificationVO)
                .toList();

        SupplierReview review = new SupplierReview();
        review.setReviewNo("SUP-REV-" + UUID.randomUUID().toString().replace("-", ""));
        review.setSupplierId(supplierId);
        review.setReviewRound(nextRound);
        review.setStatus(SupplierReviewStatus.PENDING.name());
        review.setSubmittedBy(operatorId);
        review.setSubmittedAt(nowUtc());
        review.setQualificationSnapshot(toJson(snapshot));
        review.setCreatedAt(nowUtc());
        reviewMapper.insert(review);

        String beforeStatus = supplier.getQualificationStatus();
        supplier.setQualificationStatus(SupplierStatus.UNDER_REVIEW.name());
        supplier.setUpdatedBy(operatorId);
        ensureUpdated(supplierMapper.updateById(supplier), "供应商状态已被其他操作修改");

        auditTrailService.recordStatusChange(
                "SUPPLIER", supplierId, supplier.getSupplierCode(), beforeStatus,
                SupplierStatus.UNDER_REVIEW.name(),
                "提交供应商资质审核", operatorId);
        auditTrailService.recordOperation(
                operatorId, "SUPPLIER", "SUBMIT", "SUPPLIER_REVIEW", review.getId(),
                "提交供应商资质审核", null, toReviewVO(review));
        return toReviewVO(review);
    }

    @Transactional(rollbackFor = Exception.class)
    public SupplierReviewVO review(
            Long supplierId,
            Long reviewId,
            SupplierReviewDecisionRequest request) {
        Long reviewerId = currentUserService.requireUserId();
        Supplier supplier = requireSupplier(supplierId);
        if (!SupplierStatus.UNDER_REVIEW.name().equals(supplier.getQualificationStatus())) {
            throw new BizException(409, "供应商当前不处于审核中状态");
        }
        SupplierReview review = requirePendingReview(supplierId, reviewId);
        if (reviewerId.equals(review.getSubmittedBy())) {
            throw new BizException(409, "提交人不能审核自己的供应商资质");
        }

        String decision = request.getDecision().trim();
        String rejectionReason = trimToNull(request.getRejectionReason());
        if (SupplierReviewStatus.REJECTED.name().equals(decision) && !StringUtils.hasText(rejectionReason)) {
            throw new BizException("驳回供应商资质时必须填写驳回原因");
        }

        List<SupplierQualification> qualifications = List.of();
        LocalDate approvedValidUntil = null;
        if (SupplierReviewStatus.APPROVED.name().equals(decision)) {
            qualifications = loadQualifications(supplierId);
            List<SupplierQualification> effectiveQualifications =
                    selectEffectiveRequiredQualifications(supplier, qualifications);
            approvedValidUntil = effectiveQualifications.stream()
                    .map(SupplierQualification::getValidUntil)
                    .filter(date -> date != null)
                    .min(LocalDate::compareTo)
                    .orElse(null);
        }

        LocalDateTime reviewedAt = nowUtc();
        int reviewUpdated = reviewMapper.update(null, Wrappers.<SupplierReview>lambdaUpdate()
                .eq(SupplierReview::getId, reviewId)
                .eq(SupplierReview::getSupplierId, supplierId)
                .eq(SupplierReview::getStatus, SupplierReviewStatus.PENDING.name())
                .set(SupplierReview::getStatus, decision)
                .set(SupplierReview::getReviewerId, reviewerId)
                .set(SupplierReview::getReviewedAt, reviewedAt)
                .set(SupplierReview::getReviewOpinion, trimToNull(request.getReviewOpinion()))
                .set(SupplierReview::getRejectionReason, rejectionReason)
                .set(SupplierReview::getApprovedValidUntil, approvedValidUntil));
        ensureUpdated(reviewUpdated, "该供应商审核已被其他审核人处理");

        String beforeStatus = supplier.getQualificationStatus();
        if (SupplierReviewStatus.APPROVED.name().equals(decision)) {
            LocalDate today = LocalDate.now(ZoneOffset.UTC);
            for (SupplierQualification qualification : qualifications) {
                if (qualification.getValidUntil() != null
                        && qualification.getValidUntil().isBefore(today)) {
                    qualification.setStatus(SupplierQualificationStatus.EXPIRED.name());
                } else if (qualification.getValidFrom() != null
                        && qualification.getValidFrom().isAfter(today)) {
                    qualification.setStatus(SupplierQualificationStatus.DRAFT.name());
                } else {
                    qualification.setStatus(SupplierQualificationStatus.VALID.name());
                }
                qualification.setUpdatedBy(reviewerId);
                ensureUpdated(qualificationMapper.updateById(qualification), "供应商资质已被其他操作修改");
            }
            supplier.setQualificationStatus(SupplierStatus.APPROVED.name());
            supplier.setApprovedAt(reviewedAt);
            supplier.setValidUntil(approvedValidUntil);
        } else {
            supplier.setQualificationStatus(SupplierStatus.REJECTED.name());
            supplier.setApprovedAt(null);
            supplier.setValidUntil(null);
        }
        supplier.setUpdatedBy(reviewerId);
        ensureUpdated(supplierMapper.updateById(supplier), "供应商状态已被其他操作修改");

        SupplierReview completedReview = reviewMapper.selectById(reviewId);
        auditTrailService.recordStatusChange(
                "SUPPLIER", supplierId, supplier.getSupplierCode(), beforeStatus,
                supplier.getQualificationStatus(),
                SupplierReviewStatus.APPROVED.name().equals(decision) ? "供应商资质审核通过" : rejectionReason,
                reviewerId);
        auditTrailService.recordOperation(
                reviewerId, "SUPPLIER", "REVIEW", "SUPPLIER_REVIEW", reviewId,
                "供应商资质审核" + (SupplierReviewStatus.APPROVED.name().equals(decision) ? "通过" : "驳回"),
                toReviewVO(review), toReviewVO(completedReview));
        return toReviewVO(completedReview);
    }

    @Transactional(readOnly = true)
    public SupplierVO getDetail(Long supplierId) {
        return toSupplierVO(requireSupplier(supplierId), true);
    }

    @Transactional(readOnly = true)
    public PageResult<SupplierVO> page(SupplierPageQuery query) {
        validateQuery(query);
        Page<Supplier> page = new Page<>(query.getPageNo(), query.getPageSize());
        LambdaQueryWrapper<Supplier> wrapper = Wrappers.<Supplier>lambdaQuery()
                .and(StringUtils.hasText(query.getKeyword()), condition -> condition
                        .like(Supplier::getSupplierCode, trim(query.getKeyword()))
                        .or()
                        .like(Supplier::getSupplierName, trim(query.getKeyword()))
                        .or()
                        .like(Supplier::getUnifiedSocialCreditCode, trim(query.getKeyword())))
                .eq(StringUtils.hasText(query.getQualificationStatus()),
                        Supplier::getQualificationStatus, trim(query.getQualificationStatus()))
                .eq(StringUtils.hasText(query.getSupplierType()),
                        Supplier::getSupplierType, trim(query.getSupplierType()))
                .orderByDesc(Supplier::getCreatedAt)
                .orderByDesc(Supplier::getId);
        Page<Supplier> result = supplierMapper.selectPage(page, wrapper);
        return PageResult.of(
                result.getRecords().stream().map(supplier -> toSupplierVO(supplier, false)).toList(),
                result.getTotal(), query.getPageNo(), query.getPageSize());
    }

    private SupplierVO toSupplierVO(Supplier supplier, boolean includeDetails) {
        SupplierVO vo = new SupplierVO();
        vo.setId(supplier.getId());
        vo.setSupplierCode(supplier.getSupplierCode());
        vo.setSupplierName(supplier.getSupplierName());
        vo.setSupplierType(supplier.getSupplierType());
        vo.setUnifiedSocialCreditCode(supplier.getUnifiedSocialCreditCode());
        vo.setContactName(supplier.getContactName());
        vo.setContactPhone(supplier.getContactPhone());
        vo.setContactEmail(supplier.getContactEmail());
        vo.setAddress(supplier.getAddress());
        vo.setQualificationStatus(supplier.getQualificationStatus());
        vo.setApprovedAt(supplier.getApprovedAt());
        vo.setValidUntil(supplier.getValidUntil());
        vo.setCreatedAt(supplier.getCreatedAt());
        vo.setUpdatedAt(supplier.getUpdatedAt());
        if (includeDetails) {
            vo.setQualifications(loadQualifications(supplier.getId()).stream()
                    .map(this::toQualificationVO)
                    .toList());
            vo.setReviews(reviewMapper.selectList(Wrappers.<SupplierReview>lambdaQuery()
                            .eq(SupplierReview::getSupplierId, supplier.getId())
                            .orderByDesc(SupplierReview::getReviewRound))
                    .stream()
                    .map(this::toReviewVO)
                    .toList());
        }
        return vo;
    }

    private SupplierQualificationVO toQualificationVO(SupplierQualification qualification) {
        SupplierQualificationVO vo = new SupplierQualificationVO();
        vo.setId(qualification.getId());
        vo.setQualificationType(qualification.getQualificationType());
        vo.setCertificateNo(qualification.getCertificateNo());
        vo.setIssuingAuthority(qualification.getIssuingAuthority());
        vo.setIssuedOn(qualification.getIssuedOn());
        vo.setValidFrom(qualification.getValidFrom());
        vo.setValidUntil(qualification.getValidUntil());
        vo.setStatus(qualification.getStatus());
        vo.setRemark(qualification.getRemark());
        vo.setAttachments(attachmentMapper.selectList(Wrappers.<SupplierAttachment>lambdaQuery()
                        .eq(SupplierAttachment::getBusinessType, ATTACHMENT_BUSINESS_TYPE)
                        .eq(SupplierAttachment::getBusinessId, qualification.getId())
                        .eq(SupplierAttachment::getStatus, AttachmentStatus.ACTIVE.name())
                        .orderByAsc(SupplierAttachment::getUploadedAt))
                .stream()
                .map(this::toAttachmentVO)
                .toList());
        return vo;
    }

    private SupplierReviewVO toReviewVO(SupplierReview review) {
        SupplierReviewVO vo = new SupplierReviewVO();
        vo.setId(review.getId());
        vo.setReviewNo(review.getReviewNo());
        vo.setReviewRound(review.getReviewRound());
        vo.setStatus(review.getStatus());
        vo.setSubmittedBy(review.getSubmittedBy());
        vo.setSubmittedAt(review.getSubmittedAt());
        vo.setReviewerId(review.getReviewerId());
        vo.setReviewedAt(review.getReviewedAt());
        vo.setReviewOpinion(review.getReviewOpinion());
        vo.setRejectionReason(review.getRejectionReason());
        vo.setApprovedValidUntil(review.getApprovedValidUntil());
        return vo;
    }

    private AttachmentVO toAttachmentVO(SupplierAttachment attachment) {
        AttachmentVO vo = new AttachmentVO();
        vo.setId(attachment.getId());
        vo.setAttachmentNo(attachment.getAttachmentNo());
        vo.setCategory(attachment.getCategory());
        vo.setOriginalName(attachment.getOriginalName());
        vo.setStorageKey(attachment.getStorageKey());
        vo.setContentType(attachment.getContentType());
        vo.setFileSize(attachment.getFileSize());
        vo.setSha256(attachment.getSha256());
        vo.setStatus(attachment.getStatus());
        vo.setUploadedBy(attachment.getUploadedBy());
        vo.setUploadedAt(attachment.getUploadedAt());
        return vo;
    }

    private List<SupplierQualification> selectEffectiveRequiredQualifications(
            Supplier supplier,
            List<SupplierQualification> qualifications) {
        Set<String> requiredTypes = new LinkedHashSet<>();
        requiredTypes.add(SupplierQualificationType.BUSINESS_LICENSE.name());
        requiredTypes.add(SupplierType.PRODUCTION.name().equals(supplier.getSupplierType())
                ? SupplierQualificationType.DRUG_PRODUCTION_LICENSE.name()
                : SupplierQualificationType.DRUG_OPERATION_LICENSE.name());
        requiredTypes.add(SupplierQualificationType.AUTHORIZATION.name());

        var byType = qualifications.stream()
                .collect(Collectors.groupingBy(SupplierQualification::getQualificationType));
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        List<SupplierQualification> selected = new java.util.ArrayList<>();
        for (String requiredType : requiredTypes) {
            List<SupplierQualification> candidates = byType.get(requiredType);
            if (candidates == null || candidates.isEmpty()) {
                throw new BizException(409, "缺少必需资质：" + requiredType);
            }

            List<SupplierQualification> effectiveCandidates = candidates.stream()
                    .filter(qualification -> SUBMITTABLE_QUALIFICATION_STATUSES.contains(qualification.getStatus()))
                    .filter(qualification -> qualification.getIssuedOn() == null
                            || !qualification.getIssuedOn().isAfter(today))
                    .filter(qualification -> qualification.getValidFrom() == null
                            || !qualification.getValidFrom().isAfter(today))
                    .filter(qualification -> qualification.getValidUntil() == null
                            || !qualification.getValidUntil().isBefore(today))
                    .toList();
            if (effectiveCandidates.isEmpty()) {
                throw new BizException(409, "必需资质尚未生效或已过期：" + requiredType);
            }

            SupplierQualification selectedQualification = effectiveCandidates.stream()
                    .filter(this::hasActiveAttachment)
                    .max(Comparator.comparing(
                            SupplierQualification::getValidUntil,
                            Comparator.nullsLast(Comparator.naturalOrder())))
                    .orElseThrow(() -> new BizException(409, "必需资质尚未登记有效附件：" + requiredType));
            selected.add(selectedQualification);
        }
        return selected;
    }

    private boolean hasActiveAttachment(SupplierQualification qualification) {
        Long attachmentCount = attachmentMapper.selectCount(Wrappers.<SupplierAttachment>lambdaQuery()
                .eq(SupplierAttachment::getBusinessType, ATTACHMENT_BUSINESS_TYPE)
                .eq(SupplierAttachment::getBusinessId, qualification.getId())
                .eq(SupplierAttachment::getStatus, AttachmentStatus.ACTIVE.name()));
        return attachmentCount != null && attachmentCount > 0;
    }

    private void applySupplierFields(
            Supplier supplier,
            String supplierName,
            String supplierType,
            String creditCode,
            String contactName,
            String contactPhone,
            String contactEmail,
            String address) {
        supplier.setSupplierName(supplierName.trim());
        supplier.setSupplierType(supplierType.trim());
        supplier.setUnifiedSocialCreditCode(creditCode);
        supplier.setContactName(trimToNull(contactName));
        supplier.setContactPhone(trimToNull(contactPhone));
        supplier.setContactEmail(trimToNull(contactEmail));
        supplier.setAddress(trimToNull(address));
    }

    private void applyQualificationFields(
            SupplierQualification qualification,
            SupplierQualificationRequest request) {
        qualification.setQualificationType(request.getQualificationType().trim());
        qualification.setCertificateNo(request.getCertificateNo().trim());
        qualification.setIssuingAuthority(trimToNull(request.getIssuingAuthority()));
        qualification.setIssuedOn(request.getIssuedOn());
        qualification.setValidFrom(request.getValidFrom());
        qualification.setValidUntil(request.getValidUntil());
        qualification.setRemark(trimToNull(request.getRemark()));
    }

    private void validateQualificationDates(SupplierQualificationRequest request) {
        if (request.getValidFrom() != null && request.getValidUntil() != null
                && request.getValidFrom().isAfter(request.getValidUntil())) {
            throw new BizException("资质有效期开始日期不能晚于截止日期");
        }
        if (request.getIssuedOn() != null && request.getValidUntil() != null
                && request.getIssuedOn().isAfter(request.getValidUntil())) {
            throw new BizException("资质发证日期不能晚于有效期截止日期");
        }
    }

    private void validateAttachmentCategory(SupplierQualification qualification, String category) {
        if (SupplierQualificationType.AUTHORIZATION.name().equals(qualification.getQualificationType())
                && !AttachmentCategory.AUTHORIZATION.name().equals(category)) {
            throw new BizException("授权文件资质的附件分类必须为AUTHORIZATION");
        }
        if (!Set.of(
                        SupplierQualificationType.AUTHORIZATION.name(),
                        SupplierQualificationType.OTHER.name())
                .contains(qualification.getQualificationType())
                && !AttachmentCategory.LICENSE.name().equals(category)) {
            throw new BizException("许可证类资质的附件分类必须为LICENSE");
        }
    }

    private void ensureSupplierUnique(Long supplierId, String supplierCode, String creditCode) {
        if (supplierMapper.selectCount(Wrappers.<Supplier>lambdaQuery()
                .eq(Supplier::getSupplierCode, supplierCode)
                .ne(supplierId != null, Supplier::getId, supplierId)) > 0) {
            throw new BizException(409, "供应商编码已存在");
        }
        if (supplierMapper.selectCount(Wrappers.<Supplier>lambdaQuery()
                .eq(Supplier::getUnifiedSocialCreditCode, creditCode)
                .ne(supplierId != null, Supplier::getId, supplierId)) > 0) {
            throw new BizException(409, "统一社会信用代码已存在");
        }
    }

    private void validateQuery(SupplierPageQuery query) {
        if (StringUtils.hasText(query.getQualificationStatus())
                && !QUERY_STATUSES.contains(query.getQualificationStatus().trim())) {
            throw new BizException("供应商资质状态查询条件非法");
        }
        if (StringUtils.hasText(query.getSupplierType())
                && !Set.of(SupplierType.PRODUCTION.name(), SupplierType.WHOLESALE.name())
                        .contains(query.getSupplierType().trim())) {
            throw new BizException("供应商类型查询条件非法");
        }
    }

    private Supplier requireEditableSupplier(Long supplierId) {
        Supplier supplier = requireSupplier(supplierId);
        if (!EDITABLE_STATUSES.contains(supplier.getQualificationStatus())) {
            throw new BizException(409, "只有草稿或已驳回供应商可以修改");
        }
        return supplier;
    }

    private Supplier requireSupplier(Long supplierId) {
        if (supplierId == null) {
            throw new BizException("供应商ID不能为空");
        }
        Supplier supplier = supplierMapper.selectById(supplierId);
        if (supplier == null) {
            throw new BizException(404, "供应商不存在");
        }
        return supplier;
    }

    private SupplierQualification requireQualification(Long supplierId, Long qualificationId) {
        SupplierQualification qualification = qualificationMapper.selectById(qualificationId);
        if (qualification == null || !supplierId.equals(qualification.getSupplierId())) {
            throw new BizException(404, "供应商资质不存在");
        }
        return qualification;
    }

    private SupplierReview requirePendingReview(Long supplierId, Long reviewId) {
        SupplierReview review = reviewMapper.selectById(reviewId);
        if (review == null || !supplierId.equals(review.getSupplierId())) {
            throw new BizException(404, "供应商审核记录不存在");
        }
        if (!SupplierReviewStatus.PENDING.name().equals(review.getStatus())) {
            throw new BizException(409, "供应商审核记录已处理");
        }
        return review;
    }

    private List<SupplierQualification> loadQualifications(Long supplierId) {
        return qualificationMapper.selectList(Wrappers.<SupplierQualification>lambdaQuery()
                .eq(SupplierQualification::getSupplierId, supplierId)
                .orderByAsc(SupplierQualification::getQualificationType)
                .orderByAsc(SupplierQualification::getId));
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("供应商资质快照序列化失败", exception);
        }
    }

    private void ensureUpdated(int affectedRows, String message) {
        if (affectedRows != 1) {
            throw new BizException(409, message);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private String trimToNull(String value) {
        String trimmed = trim(value);
        return StringUtils.hasText(trimmed) ? trimmed : null;
    }

    private LocalDateTime nowUtc() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }
}
