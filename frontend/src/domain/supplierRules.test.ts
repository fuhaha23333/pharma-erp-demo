import {
  buildQualificationChecklist,
  isReviewerConflict,
  isSupplierEditable,
  validateReviewDecision,
} from '@/domain/supplierRules'
import type {
  SupplierQualification,
  SupplierReview,
} from '@/types/supplier'

function qualification(
  type: SupplierQualification['qualificationType'],
  attachments = 1,
  validUntil = '2026-12-31',
): SupplierQualification {
  return {
    id: Math.random(),
    qualificationType: type,
    certificateNo: `CERT-${type}`,
    validFrom: '2026-01-01',
    validUntil,
    status: 'DRAFT',
    attachments: Array.from({ length: attachments }, (_, index) => ({
      id: index + 1,
      attachmentNo: `ATT-${index}`,
      category: type === 'AUTHORIZATION' ? 'AUTHORIZATION' : 'LICENSE',
      originalName: 'evidence.pdf',
      storageKey: `controlled/${index}.pdf`,
      contentType: 'application/pdf',
      fileSize: 100,
      sha256: 'a'.repeat(64),
      status: 'ACTIVE',
      uploadedBy: 1,
      uploadedAt: '2026-08-04T01:00:00',
    })),
  }
}

describe('supplierRules', () => {
  it('只有草稿和驳回状态可以修改', () => {
    expect(isSupplierEditable('DRAFT')).toBe(true)
    expect(isSupplierEditable('REJECTED')).toBe(true)
    expect(isSupplierEditable('UNDER_REVIEW')).toBe(false)
    expect(isSupplierEditable('APPROVED')).toBe(false)
  })

  it('批发供应商三类必需资质及附件齐全时通过前端完整性提示', () => {
    const checks = buildQualificationChecklist(
      {
        supplierType: 'WHOLESALE',
        qualifications: [
          qualification('BUSINESS_LICENSE'),
          qualification('DRUG_OPERATION_LICENSE'),
          qualification('AUTHORIZATION'),
        ],
      },
      '2026-08-04',
    )

    expect(checks).toHaveLength(3)
    expect(checks.every((item) => item.passed)).toBe(true)
  })

  it('缺少附件或资质过期时保持阻断提示', () => {
    const checks = buildQualificationChecklist(
      {
        supplierType: 'PRODUCTION',
        qualifications: [
          qualification('BUSINESS_LICENSE', 0),
          qualification('DRUG_PRODUCTION_LICENSE', 1, '2026-01-01'),
          qualification('AUTHORIZATION'),
        ],
      },
      '2026-08-04',
    )

    expect(checks.find((item) => item.type === 'BUSINESS_LICENSE')?.passed).toBe(false)
    expect(
      checks.find((item) => item.type === 'DRUG_PRODUCTION_LICENSE')?.passed,
    ).toBe(false)
  })

  it('同类资质存在多条有效记录时优先采用带有效附件的记录', () => {
    const withoutAttachment = qualification('BUSINESS_LICENSE', 0)
    const withAttachment = qualification('BUSINESS_LICENSE')
    withAttachment.certificateNo = 'CERT-WITH-EVIDENCE'

    const checks = buildQualificationChecklist(
      {
        supplierType: 'WHOLESALE',
        qualifications: [withoutAttachment, withAttachment],
      },
      '2026-08-04',
    )
    const businessLicense = checks.find(
      (item) => item.type === 'BUSINESS_LICENSE',
    )

    expect(businessLicense?.passed).toBe(true)
    expect(businessLicense?.message).toContain('CERT-WITH-EVIDENCE')
  })

  it('阻止提交人审核本人，并要求驳回原因', () => {
    const review = { submittedBy: 8 } as SupplierReview

    expect(isReviewerConflict(8, review)).toBe(true)
    expect(isReviewerConflict(9, review)).toBe(false)
    expect(validateReviewDecision('REJECTED', '   ')).toBe(
      '审核驳回时必须填写驳回原因',
    )
    expect(validateReviewDecision('REJECTED', '许可证信息不一致')).toBeNull()
    expect(validateReviewDecision('APPROVED')).toBeNull()
  })
})
