export interface BatchInventory {
  inventoryBalanceId: number
  warehouseId: number
  warehouseCode: string
  warehouseName: string
  warehouseLocationId: number
  locationCode: string
  locationName: string
  locationType: string
  totalQuantity: number
  availableQuantity: number
  reservedQuantity: number
  quarantinedQuantity: number
  status: string
  lastLedgerNo?: string
}

export interface BatchTraceEvent {
  eventId: number
  eventNo: string
  eventType: string
  supplierCode?: string
  supplierName?: string
  customerCode?: string
  customerName?: string
  warehouseCode?: string
  warehouseName?: string
  locationCode?: string
  locationName?: string
  inventoryLedgerNo?: string
  businessType?: string
  businessId?: number
  businessNo?: string
  quantity?: number
  eventData?: string
  operatorId?: number
  operatorUsername?: string
  operatorRealName?: string
  occurredAt: string
}

export interface DrugBatchTrace {
  batchId: number
  batchCode: string
  batchNo: string
  drugId: number
  drugCode: string
  drugName?: string
  genericName: string
  approvalNo: string
  dosageForm: string
  specification: string
  basicUnit: string
  storageCondition: string
  manufacturerId?: number
  manufacturerCode?: string
  manufacturerName?: string
  productionDate?: string
  expiryDate?: string
  qualityStatus: string
  stockStatus: string
  inventories: BatchInventory[]
  events: BatchTraceEvent[]
}
