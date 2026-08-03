package com.fuhaha.pharmaerp.modules.quality.supplier.controller;

import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.AttachmentMetadataRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierCreateRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierPageQuery;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierQualificationRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierReviewDecisionRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.dto.SupplierUpdateRequest;
import com.fuhaha.pharmaerp.modules.quality.supplier.service.SupplierService;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.AttachmentVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierQualificationVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierReviewVO;
import com.fuhaha.pharmaerp.modules.quality.supplier.vo.SupplierVO;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/quality/suppliers")
@Tag(name = "供应商资质审核", description = "供应商草稿、资质附件、提交审核和质量审核")
public class SupplierController {

    private final SupplierService supplierService;

    public SupplierController(SupplierService supplierService) {
        this.supplierService = supplierService;
    }

    @PostMapping
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_WRITE + "')")
    @Operation(summary = "创建供应商草稿")
    public Result<SupplierVO> create(@Valid @RequestBody SupplierCreateRequest request) {
        return Result.success(supplierService.create(request));
    }

    @PutMapping("/{supplierId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_WRITE + "')")
    @Operation(summary = "修改供应商草稿", description = "仅DRAFT或REJECTED状态允许修改")
    public Result<SupplierVO> update(
            @PathVariable Long supplierId,
            @Valid @RequestBody SupplierUpdateRequest request) {
        return Result.success(supplierService.update(supplierId, request));
    }

    @PostMapping("/{supplierId}/qualifications")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_WRITE + "')")
    @Operation(summary = "新增供应商资质")
    public Result<SupplierQualificationVO> addQualification(
            @PathVariable Long supplierId,
            @Valid @RequestBody SupplierQualificationRequest request) {
        return Result.success(supplierService.addQualification(supplierId, request));
    }

    @PutMapping("/{supplierId}/qualifications/{qualificationId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_WRITE + "')")
    @Operation(summary = "修改供应商资质")
    public Result<SupplierQualificationVO> updateQualification(
            @PathVariable Long supplierId,
            @PathVariable Long qualificationId,
            @Valid @RequestBody SupplierQualificationRequest request) {
        return Result.success(supplierService.updateQualification(supplierId, qualificationId, request));
    }

    @PostMapping("/{supplierId}/qualifications/{qualificationId}/attachments")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_WRITE + "')")
    @Operation(
            summary = "登记资质附件元数据",
            description = "文件内容由受控文件存储保存，本接口登记存储键、SHA-256摘要和上传人")
    public Result<AttachmentVO> registerAttachment(
            @PathVariable Long supplierId,
            @PathVariable Long qualificationId,
            @Valid @RequestBody AttachmentMetadataRequest request) {
        return Result.success(supplierService.registerAttachment(supplierId, qualificationId, request));
    }

    @PostMapping("/{supplierId}/submit")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_SUBMIT + "')")
    @Operation(
            summary = "提交供应商资质审核",
            description = "校验营业执照、生产或经营许可、授权文件及附件，并固化提交快照")
    public Result<SupplierReviewVO> submit(@PathVariable Long supplierId) {
        return Result.success(supplierService.submitForReview(supplierId));
    }

    @PutMapping("/{supplierId}/reviews/{reviewId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_REVIEW + "')")
    @Operation(
            summary = "审核供应商资质",
            description = "审核人不能是提交人；驳回必须填写原因，审核结论和状态变化不可覆盖")
    public Result<SupplierReviewVO> review(
            @PathVariable Long supplierId,
            @PathVariable Long reviewId,
            @Valid @RequestBody SupplierReviewDecisionRequest request) {
        return Result.success(supplierService.review(supplierId, reviewId, request));
    }

    @GetMapping("/{supplierId}")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_READ + "')")
    @Operation(summary = "查询供应商完整资质与审核历史")
    public Result<SupplierVO> detail(@PathVariable Long supplierId) {
        return Result.success(supplierService.getDetail(supplierId));
    }

    @GetMapping("/page")
    @PreAuthorize("hasAuthority('" + PermissionCodes.SUPPLIER_READ + "')")
    @Operation(summary = "分页查询供应商")
    public Result<PageResult<SupplierVO>> page(@Valid SupplierPageQuery query) {
        return Result.success(supplierService.page(query));
    }
}
