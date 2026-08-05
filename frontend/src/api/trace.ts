import { request } from '@/api/http'
import type { DrugBatchTrace } from '@/types/trace'

export function traceBatch(batchNo: string, drugCode?: string): Promise<DrugBatchTrace[]> {
  return request<DrugBatchTrace[]>({
    method: 'GET',
    url: `/trace/batches/${encodeURIComponent(batchNo)}`,
    params: drugCode ? { drugCode } : undefined,
  })
}
