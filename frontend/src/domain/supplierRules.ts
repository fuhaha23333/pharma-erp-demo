import type {
  QualificationType,
  Supplier,
  SupplierReview,
  SupplierStatus,
} from '@/types/supplier'

export interface QualificationCheckItem {
  type: QualificationType
  label: string
  passed: boolean
  message: string
}

export function isSupplierEditable(status: SupplierStatus): boolean {
  return status === 'DRAFT' || status === 'REJECTED'
}

export function isReviewerConflict(
  currentUserId: number | undefined,
  review: SupplierReview | undefined,
): boolean {
  return currentUserId !== undefined && review?.submittedBy === currentUserId
}

export function validateReviewDecision(
  decision: 'APPROVED' | 'REJECTED',
  rejectionReason?: string,
): string | null {
  if (decision === 'REJECTED' && !rejectionReason?.trim()) {
    return '审核驳回时必须填写驳回原因'
  }
  return null
}

export function buildQualificationChecklist(
  supplier: Pick<Supplier, 'supplierType' | 'qualifications'>,
  today = new Date().toISOString().slice(0, 10),
): QualificationCheckItem[] {
  const required: Array<{ type: QualificationType; label: string }> = [
    { type: 'BUSINESS_LICENSE', label: '营业执照' },
    {
      type:
        supplier.supplierType === 'PRODUCTION'
          ? 'DRUG_PRODUCTION_LICENSE'
          : 'DRUG_OPERATION_LICENSE',
      label:
        supplier.supplierType === 'PRODUCTION'
          ? '药品生产许可证'
          : '药品经营许可证',
    },
    { type: 'AUTHORIZATION', label: '授权文件' },
  ]

  return required.map((item) => {
    const validQualifications = supplier.qualifications.filter(
      (candidate) =>
        candidate.qualificationType === item.type &&
          (!candidate.issuedOn || candidate.issuedOn <= today) &&
          (!candidate.validFrom || candidate.validFrom <= today) &&
          (!candidate.validUntil || candidate.validUntil >= today) &&
        ['DRAFT', 'VALID'].includes(candidate.status),
    )
    const qualification =
      validQualifications.find((candidate) =>
        candidate.attachments.some((attachment) => attachment.status === 'ACTIVE'),
      ) ?? validQualifications[0]
    const activeAttachmentCount =
      qualification?.attachments.filter((attachment) => attachment.status === 'ACTIVE')
        .length ?? 0
    const passed = activeAttachmentCount > 0

    return {
      ...item,
      passed,
      message: !qualification
        ? '缺少当前有效的资质记录'
        : passed
          ? `${qualification.certificateNo} · ${activeAttachmentCount} 份有效附件`
          : '资质已登记，但缺少有效附件元数据',
    }
  })
}
