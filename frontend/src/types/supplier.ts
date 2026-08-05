import type { PageQuery } from '@/types/api'

export type SupplierType = 'PRODUCTION' | 'WHOLESALE'
export type SupplierStatus =
  | 'DRAFT'
  | 'UNDER_REVIEW'
  | 'APPROVED'
  | 'REJECTED'
  | 'EXPIRED'
  | 'DISABLED'
export type QualificationType =
  | 'BUSINESS_LICENSE'
  | 'DRUG_PRODUCTION_LICENSE'
  | 'DRUG_OPERATION_LICENSE'
  | 'AUTHORIZATION'
  | 'OTHER'

export interface SupplierAttachment {
  id: number
  attachmentNo: string
  category: 'LICENSE' | 'AUTHORIZATION' | 'OTHER'
  originalName: string
  storageKey: string
  contentType: string
  fileSize: number
  sha256: string
  status: 'ACTIVE' | 'INVALIDATED'
  uploadedBy: number
  uploadedAt: string
}

export interface SupplierQualification {
  id: number
  qualificationType: QualificationType
  certificateNo: string
  issuingAuthority?: string
  issuedOn?: string
  validFrom?: string
  validUntil?: string
  status: 'DRAFT' | 'VALID' | 'EXPIRED' | 'REVOKED'
  remark?: string
  attachments: SupplierAttachment[]
}

export interface SupplierReview {
  id: number
  reviewNo: string
  reviewRound: number
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'RETURNED'
  submittedBy: number
  submittedAt: string
  reviewerId?: number
  reviewedAt?: string
  reviewOpinion?: string
  rejectionReason?: string
  approvedValidUntil?: string
}

export interface Supplier {
  id: number
  supplierCode: string
  supplierName: string
  supplierType: SupplierType
  unifiedSocialCreditCode: string
  contactName?: string
  contactPhone?: string
  contactEmail?: string
  address?: string
  qualificationStatus: SupplierStatus
  approvedAt?: string
  validUntil?: string
  createdAt: string
  updatedAt: string
  qualifications: SupplierQualification[]
  reviews: SupplierReview[]
}

export interface SupplierPageQuery extends PageQuery {
  keyword?: string
  qualificationStatus?: string
  supplierType?: string
}

export interface SupplierCreatePayload {
  supplierCode: string
  supplierName: string
  supplierType: SupplierType
  unifiedSocialCreditCode: string
  contactName?: string
  contactPhone?: string
  contactEmail?: string
  address?: string
}

export interface SupplierUpdatePayload extends Omit<SupplierCreatePayload, 'supplierCode'> {
  changeReason: string
}

export interface QualificationPayload {
  qualificationType: QualificationType
  certificateNo: string
  issuingAuthority?: string
  issuedOn?: string
  validFrom?: string
  validUntil?: string
  remark?: string
}

export interface AttachmentPayload {
  category: 'LICENSE' | 'AUTHORIZATION' | 'OTHER'
  originalName: string
  storageKey: string
  contentType: string
  fileSize: number
  sha256: string
}

export interface ReviewPayload {
  decision: 'APPROVED' | 'REJECTED'
  reviewOpinion?: string
  rejectionReason?: string
}
