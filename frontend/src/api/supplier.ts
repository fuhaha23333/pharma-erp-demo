import { request } from '@/api/http'
import type { PageResult } from '@/types/api'
import type {
  AttachmentPayload,
  QualificationPayload,
  ReviewPayload,
  Supplier,
  SupplierAttachment,
  SupplierCreatePayload,
  SupplierPageQuery,
  SupplierQualification,
  SupplierReview,
  SupplierUpdatePayload,
} from '@/types/supplier'
import { compactParams } from '@/utils/format'

export function getSuppliers(params: SupplierPageQuery): Promise<PageResult<Supplier>> {
  return request<PageResult<Supplier>>({
    method: 'GET',
    url: '/quality/suppliers/page',
    params: compactParams(params),
  })
}

export function getSupplier(supplierId: number): Promise<Supplier> {
  return request<Supplier>({ method: 'GET', url: `/quality/suppliers/${supplierId}` })
}

export function createSupplier(payload: SupplierCreatePayload): Promise<Supplier> {
  return request<Supplier>({ method: 'POST', url: '/quality/suppliers', data: payload })
}

export function updateSupplier(
  supplierId: number,
  payload: SupplierUpdatePayload,
): Promise<Supplier> {
  return request<Supplier>({
    method: 'PUT',
    url: `/quality/suppliers/${supplierId}`,
    data: payload,
  })
}

export function addQualification(
  supplierId: number,
  payload: QualificationPayload,
): Promise<SupplierQualification> {
  return request<SupplierQualification>({
    method: 'POST',
    url: `/quality/suppliers/${supplierId}/qualifications`,
    data: payload,
  })
}

export function updateQualification(
  supplierId: number,
  qualificationId: number,
  payload: QualificationPayload,
): Promise<SupplierQualification> {
  return request<SupplierQualification>({
    method: 'PUT',
    url: `/quality/suppliers/${supplierId}/qualifications/${qualificationId}`,
    data: payload,
  })
}

export function registerAttachment(
  supplierId: number,
  qualificationId: number,
  payload: AttachmentPayload,
): Promise<SupplierAttachment> {
  return request<SupplierAttachment>({
    method: 'POST',
    url: `/quality/suppliers/${supplierId}/qualifications/${qualificationId}/attachments`,
    data: payload,
  })
}

export function submitSupplier(supplierId: number): Promise<SupplierReview> {
  return request<SupplierReview>({
    method: 'POST',
    url: `/quality/suppliers/${supplierId}/submit`,
  })
}

export function reviewSupplier(
  supplierId: number,
  reviewId: number,
  payload: ReviewPayload,
): Promise<SupplierReview> {
  return request<SupplierReview>({
    method: 'PUT',
    url: `/quality/suppliers/${supplierId}/reviews/${reviewId}`,
    data: payload,
  })
}
