<template>
  <div>
    <PageHeader
      eyebrow="TRACEABILITY · BATCH"
      title="药品批号追溯"
      description="根据生产批号还原药品批次、当前库存分布与生命周期事件。查询只读，不允许补造或修改历史。"
    />

    <section class="trace-search">
      <div class="trace-search__copy">
        <p>批号级全过程查询</p>
        <h2>从一枚批号，回到每个业务节点</h2>
        <span>
          同一生产批号可能属于多个药品；结果不唯一时，可追加药品编码精确筛选。
        </span>
      </div>
      <ElForm
        ref="formRef"
        :model="form"
        :rules="rules"
        class="trace-search__form"
        label-position="top"
        @keyup.enter="search"
      >
        <ElFormItem label="生产批号" prop="batchNo">
          <ElInput
            v-model="form.batchNo"
            size="large"
            clearable
            placeholder="例如：20260801A"
            :prefix-icon="Search"
          />
        </ElFormItem>
        <ElFormItem label="药品编码（可选）">
          <ElInput
            v-model="form.drugCode"
            size="large"
            clearable
            placeholder="结果不唯一时用于筛选"
          />
        </ElFormItem>
        <ElButton
          class="trace-search__button"
          type="primary"
          size="large"
          :loading="loading"
          @click="search"
        >
          开始追溯
          <ElIcon class="el-icon--right"><Right /></ElIcon>
        </ElButton>
      </ElForm>
    </section>

    <template v-if="searched">
      <ElAlert
        v-if="results.length > 1"
        class="trace-alert"
        :title="`该生产批号匹配到 ${results.length} 个药品批次`"
        description="系统没有混合结果；请核对药品编码，必要时重新精确查询。"
        type="warning"
        :closable="false"
        show-icon
      />

      <div v-if="results.length" class="trace-results">
        <article v-for="(batch, batchIndex) in results" :key="batch.batchId" class="batch-card">
          <header class="batch-card__header">
            <div class="batch-card__identity">
              <span>{{ String(batchIndex + 1).padStart(2, '0') }}</span>
              <div>
                <p>{{ batch.drugCode }} · {{ batch.batchCode }}</p>
                <h2>{{ batch.genericName || batch.drugName }}</h2>
                <small>{{ batch.dosageForm }} · {{ batch.specification }} · {{ batch.basicUnit }}</small>
              </div>
            </div>
            <div class="batch-card__status">
              <div>
                <label>质量状态</label>
                <StatusTag :value="batch.qualityStatus" />
              </div>
              <div>
                <label>库存状态</label>
                <StatusTag :value="batch.stockStatus" />
              </div>
            </div>
          </header>

          <div class="batch-facts">
            <div>
              <span>生产批号</span>
              <strong>{{ batch.batchNo }}</strong>
            </div>
            <div>
              <span>批准文号</span>
              <strong>{{ batch.approvalNo }}</strong>
            </div>
            <div>
              <span>生产企业</span>
              <strong>{{ batch.manufacturerName || '—' }}</strong>
            </div>
            <div>
              <span>生产日期</span>
              <strong>{{ batch.productionDate || '—' }}</strong>
            </div>
            <div>
              <span>有效期至</span>
              <strong>{{ batch.expiryDate || '—' }}</strong>
            </div>
            <div>
              <span>储存条件</span>
              <strong>{{ batch.storageCondition || '—' }}</strong>
            </div>
          </div>

          <div class="batch-content-grid">
            <section>
              <div class="subsection-heading">
                <div>
                  <p>INVENTORY</p>
                  <h3>当前库存分布</h3>
                </div>
                <span>{{ batch.inventories.length }} 个库存位置</span>
              </div>
              <ElTable
                v-if="batch.inventories.length"
                :data="batch.inventories"
                size="small"
              >
                <ElTableColumn label="仓库 / 库位" min-width="190">
                  <template #default="{ row }: { row: BatchInventory }">
                    <div class="table-primary">{{ row.warehouseName }}</div>
                    <div class="table-secondary">
                      {{ row.warehouseCode }} / {{ row.locationCode }} {{ row.locationName }}
                    </div>
                  </template>
                </ElTableColumn>
                <ElTableColumn label="总数量" width="105" align="right">
                  <template #default="{ row }: { row: BatchInventory }">
                    {{ formatQuantity(row.totalQuantity) }}
                  </template>
                </ElTableColumn>
                <ElTableColumn label="可销售" width="105" align="right">
                  <template #default="{ row }: { row: BatchInventory }">
                    <strong class="quantity-available">
                      {{ formatQuantity(row.availableQuantity) }}
                    </strong>
                  </template>
                </ElTableColumn>
                <ElTableColumn label="已占用" width="100" align="right">
                  <template #default="{ row }: { row: BatchInventory }">
                    {{ formatQuantity(row.reservedQuantity) }}
                  </template>
                </ElTableColumn>
                <ElTableColumn label="隔离" width="100" align="right">
                  <template #default="{ row }: { row: BatchInventory }">
                    {{ formatQuantity(row.quarantinedQuantity) }}
                  </template>
                </ElTableColumn>
                <ElTableColumn label="末笔流水" min-width="150">
                  <template #default="{ row }: { row: BatchInventory }">
                    <code class="table-code">{{ row.lastLedgerNo || '—' }}</code>
                  </template>
                </ElTableColumn>
              </ElTable>
              <ElEmpty v-else :image-size="65" description="该批次没有当前库存余额" />
            </section>

            <section>
              <div class="subsection-heading">
                <div>
                  <p>LIFECYCLE</p>
                  <h3>生命周期事件</h3>
                </div>
                <span>{{ batch.events.length }} 个真实事件</span>
              </div>
              <ElTimeline v-if="batch.events.length" class="event-timeline">
                <ElTimelineItem
                  v-for="event in batch.events"
                  :key="event.eventId"
                  :timestamp="formatDateTime(event.occurredAt)"
                  :type="eventTimelineType(event.eventType)"
                  placement="top"
                >
                  <div class="event-card">
                    <div class="event-card__head">
                      <div>
                        <span>{{ eventTypeLabel(event.eventType) }}</span>
                        <code>{{ event.eventNo }}</code>
                      </div>
                      <ElButton
                        v-if="event.eventData"
                        link
                        type="primary"
                        @click="showEvidence(event)"
                      >
                        查看证据快照
                      </ElButton>
                    </div>
                    <div class="event-card__facts">
                      <p v-if="event.supplierName">
                        <span>供应商</span>
                        {{ event.supplierName }}（{{ event.supplierCode }}）
                      </p>
                      <p v-if="event.customerName">
                        <span>客户去向</span>
                        {{ event.customerName }}（{{ event.customerCode }}）
                      </p>
                      <p v-if="event.warehouseName">
                        <span>仓储位置</span>
                        {{ event.warehouseName }} / {{ event.locationName || event.locationCode }}
                      </p>
                      <p v-if="event.businessNo">
                        <span>来源业务</span>
                        {{ event.businessType }} · {{ event.businessNo }}
                      </p>
                      <p v-if="event.quantity !== undefined && event.quantity !== null">
                        <span>事件数量</span>
                        {{ formatQuantity(event.quantity) }}
                      </p>
                      <p v-if="event.inventoryLedgerNo">
                        <span>库存流水</span>
                        {{ event.inventoryLedgerNo }}
                      </p>
                      <p v-if="event.operatorUsername || event.operatorRealName">
                        <span>操作人</span>
                        {{ event.operatorRealName || event.operatorUsername }}
                        <template v-if="event.operatorUsername">
                          （{{ event.operatorUsername }}）
                        </template>
                      </p>
                    </div>
                  </div>
                </ElTimelineItem>
              </ElTimeline>
              <ElEmpty
                v-else
                :image-size="65"
                description="该批次尚无生命周期事件，系统不会伪造链路"
              />
            </section>
          </div>
        </article>
      </div>

      <SectionCard v-else>
        <div class="trace-empty">
          <span><ElIcon><Search /></ElIcon></span>
          <h2>没有查到匹配批次</h2>
          <p>
            请核对生产批号和药品编码。空结果表示当前数据库没有关联记录，不会自动生成演示事件。
          </p>
        </div>
      </SectionCard>
    </template>

    <SectionCard v-else>
      <div class="trace-initial">
        <div>
          <span>01</span>
          <strong>输入生产批号</strong>
          <p>批号必填，药品编码可选。</p>
        </div>
        <div>
          <span>02</span>
          <strong>定位药品批次</strong>
          <p>同批号多药品时分别展示。</p>
        </div>
        <div>
          <span>03</span>
          <strong>读取真实链路</strong>
          <p>库存和事件均来自后端只读查询。</p>
        </div>
      </div>
    </SectionCard>

    <ElDialog v-model="evidenceDialog.visible" title="事件证据快照" width="720px">
      <ElAlert
        v-if="!evidenceDialog.validJson"
        title="该快照不是有效 JSON，以下按原始文本展示"
        type="warning"
        :closable="false"
        show-icon
      />
      <pre class="evidence-code">{{ evidenceDialog.content }}</pre>
      <template #footer>
        <ElButton type="primary" @click="evidenceDialog.visible = false">关闭</ElButton>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
import { Right, Search } from '@element-plus/icons-vue'
import {
  ElMessage,
  type FormInstance,
  type FormRules,
  type TimelineItemProps,
} from 'element-plus'
import { reactive, ref } from 'vue'
import { getErrorMessage } from '@/api/http'
import { traceBatch } from '@/api/trace'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import type {
  BatchInventory,
  BatchTraceEvent,
  DrugBatchTrace,
} from '@/types/trace'
import { formatDateTime } from '@/utils/datetime'
import { safeJson } from '@/utils/format'

const formRef = ref<FormInstance>()
const form = reactive({
  batchNo: '',
  drugCode: '',
})
const rules: FormRules = {
  batchNo: [
    { required: true, message: '请输入生产批号', trigger: 'blur' },
    { max: 100, message: '生产批号不能超过 100 个字符', trigger: 'blur' },
  ],
}
const loading = ref(false)
const searched = ref(false)
const results = ref<DrugBatchTrace[]>([])

const evidenceDialog = reactive({
  visible: false,
  content: '',
  validJson: true,
})

async function search(): Promise<void> {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  loading.value = true
  try {
    results.value = await traceBatch(
      form.batchNo.trim(),
      form.drugCode.trim() || undefined,
    )
    searched.value = true
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

function formatQuantity(value?: number): string {
  if (value === undefined || value === null) return '—'
  return new Intl.NumberFormat('zh-CN', {
    maximumFractionDigits: 4,
  }).format(value)
}

function eventTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    PURCHASED: '采购确认',
    RECEIVED: '到货收货',
    ACCEPTED: '验收完成',
    STOCKED: '合格入库',
    STOCKED_IN: '合格入库',
    INVENTORY_CHANGED: '库存变化',
    RESERVED: '库存占用',
    OUTBOUND: '销售出库',
    OUTBOUNDED: '销售出库',
    SHIPPED: '发运',
    SIGNED: '签收',
    QUALITY_CHANGED: '质量状态变化',
    FROZEN: '库存冻结',
    UNFROZEN: '解除冻结',
  }
  return labels[type] || type
}

function eventTimelineType(type: string): TimelineItemProps['type'] {
  if (['ACCEPTED', 'STOCKED', 'STOCKED_IN', 'SIGNED', 'UNFROZEN'].includes(type)) {
    return 'success'
  }
  if (['FROZEN', 'QUALITY_CHANGED'].includes(type)) return 'danger'
  if (['OUTBOUND', 'OUTBOUNDED', 'SHIPPED', 'RESERVED'].includes(type)) {
    return 'warning'
  }
  return 'primary'
}

function showEvidence(event: BatchTraceEvent): void {
  const parsed = safeJson(event.eventData)
  evidenceDialog.content = parsed.formatted
  evidenceDialog.validJson = parsed.valid
  evidenceDialog.visible = true
}
</script>

<style scoped>
.trace-search {
  position: relative;
  display: grid;
  grid-template-columns: minmax(260px, 0.7fr) minmax(540px, 1.3fr);
  align-items: end;
  gap: clamp(30px, 5vw, 70px);
  overflow: hidden;
  margin-bottom: 22px;
  padding: clamp(28px, 4vw, 45px);
  border-radius: 20px 7px 20px 7px;
  color: #edf4f1;
  background:
    radial-gradient(circle at 92% -20%, rgba(216, 177, 112, 0.24), transparent 30%),
    linear-gradient(145deg, #17483b, #102f29);
}

.trace-search::after {
  position: absolute;
  right: 30%;
  bottom: -165px;
  width: 280px;
  height: 280px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 50%;
  content: "";
}

.trace-search__copy,
.trace-search__form {
  position: relative;
  z-index: 1;
}

.trace-search__copy > p {
  margin-bottom: 10px;
  color: #dfbc81;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.17em;
}

.trace-search__copy h2 {
  margin-bottom: 12px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: clamp(25px, 3vw, 38px);
  line-height: 1.35;
}

.trace-search__copy span {
  color: #a5bdb4;
  font-size: 12px;
  line-height: 1.8;
}

.trace-search__form {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  align-items: end;
  gap: 12px;
  padding: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 13px 5px 13px 5px;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(10px);
}

.trace-search__form :deep(.el-form-item) {
  margin-bottom: 0;
}

.trace-search__form :deep(.el-form-item__label) {
  color: #c3d3ce;
}

.trace-search__button {
  height: 40px;
}

.trace-alert {
  margin-bottom: 18px;
}

.batch-card {
  overflow: hidden;
  margin-bottom: 24px;
  border: 1px solid #dce4df;
  border-radius: 17px 6px 17px 6px;
  background: rgba(255, 254, 251, 0.95);
  box-shadow: 0 16px 45px rgba(23, 55, 46, 0.07);
}

.batch-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 25px 28px;
  border-bottom: 1px solid #e5ebe6;
  background: linear-gradient(100deg, #fafbf8, #eef5f1);
}

.batch-card__identity {
  display: flex;
  align-items: center;
  gap: 17px;
}

.batch-card__identity > span {
  color: #d0ab70;
  font-family: Georgia, serif;
  font-size: 32px;
  font-style: italic;
}

.batch-card__identity p {
  margin-bottom: 5px;
  color: #6f807a;
  font-family: Consolas, monospace;
  font-size: 10px;
}

.batch-card__identity h2 {
  margin-bottom: 5px;
  color: #1d342d;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 24px;
}

.batch-card__identity small {
  color: #7c8a85;
  font-size: 11px;
}

.batch-card__status {
  display: flex;
  gap: 18px;
}

.batch-card__status label {
  display: block;
  margin-bottom: 6px;
  color: #8a9792;
  font-size: 9px;
}

.batch-facts {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  border-bottom: 1px solid #e6ebe7;
}

.batch-facts > div {
  min-width: 0;
  padding: 17px 20px;
  border-right: 1px solid #e9edea;
}

.batch-facts > div:last-child {
  border-right: 0;
}

.batch-facts span,
.batch-facts strong {
  display: block;
}

.batch-facts span {
  margin-bottom: 6px;
  color: #8b9793;
  font-size: 9px;
}

.batch-facts strong {
  overflow: hidden;
  color: #33463f;
  font-size: 11px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.batch-content-grid {
  display: grid;
  grid-template-columns: minmax(0, 0.95fr) minmax(420px, 1.05fr);
}

.batch-content-grid > section {
  min-width: 0;
  padding: 26px 28px;
}

.batch-content-grid > section + section {
  border-left: 1px solid #e6ebe7;
}

.subsection-heading {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  margin-bottom: 18px;
}

.subsection-heading p {
  margin-bottom: 4px;
  color: #39806a;
  font-size: 9px;
  font-weight: 800;
  letter-spacing: 0.16em;
}

.subsection-heading h3 {
  margin: 0;
  color: #273d35;
  font-size: 15px;
}

.subsection-heading > span {
  color: #899590;
  font-size: 10px;
}

.quantity-available {
  color: #27705b;
}

.event-timeline {
  max-height: 560px;
  overflow-y: auto;
  padding-right: 4px;
}

.event-card {
  padding: 13px 15px;
  border: 1px solid #e5eae6;
  border-radius: 10px 4px 10px 4px;
  background: #fbfbf8;
}

.event-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.event-card__head > div {
  display: flex;
  align-items: center;
  gap: 9px;
}

.event-card__head span {
  color: #263d35;
  font-size: 12px;
  font-weight: 700;
}

.event-card__head code {
  color: #87938f;
  font-size: 9px;
}

.event-card__facts {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px 15px;
  margin-top: 12px;
  padding-top: 11px;
  border-top: 1px solid #e9ece9;
}

.event-card__facts p {
  margin: 0;
  color: #596a64;
  font-size: 10px;
  line-height: 1.5;
}

.event-card__facts span {
  display: block;
  margin-bottom: 2px;
  color: #939d99;
  font-size: 8px;
}

.trace-empty {
  display: flex;
  min-height: 280px;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  text-align: center;
}

.trace-empty > span {
  display: grid;
  width: 58px;
  height: 58px;
  place-items: center;
  border-radius: 17px 6px 17px 6px;
  color: #397a66;
  background: #e5f0eb;
  font-size: 25px;
}

.trace-empty h2 {
  margin: 17px 0 8px;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 23px;
}

.trace-empty p {
  max-width: 560px;
  margin: 0;
  color: #7d8a85;
  font-size: 12px;
  line-height: 1.7;
}

.trace-initial {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
}

.trace-initial > div {
  padding: 18px 26px;
  border-right: 1px solid #e6eae6;
}

.trace-initial > div:last-child {
  border-right: 0;
}

.trace-initial span {
  color: #d1ad72;
  font-family: Georgia, serif;
  font-size: 22px;
  font-style: italic;
}

.trace-initial strong {
  display: block;
  margin-top: 8px;
  color: #2d4039;
  font-size: 13px;
}

.trace-initial p {
  margin: 5px 0 0;
  color: #87938f;
  font-size: 10px;
}

.evidence-code {
  max-height: 480px;
  overflow: auto;
  margin: 14px 0 0;
  padding: 18px;
  border-radius: 10px;
  color: #d8e6e0;
  background: #142b25;
  font-family: "SFMono-Regular", Consolas, monospace;
  font-size: 11px;
  line-height: 1.65;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (max-width: 1200px) {
  .trace-search {
    grid-template-columns: 1fr;
  }

  .batch-facts {
    grid-template-columns: repeat(3, 1fr);
  }

  .batch-facts > div:nth-child(3) {
    border-right: 0;
  }

  .batch-content-grid {
    grid-template-columns: 1fr;
  }

  .batch-content-grid > section + section {
    border-top: 1px solid #e6ebe7;
    border-left: 0;
  }
}

@media (max-width: 760px) {
  .trace-search__form {
    grid-template-columns: 1fr;
  }

  .batch-card__header {
    align-items: flex-start;
    flex-direction: column;
  }

  .batch-facts {
    grid-template-columns: repeat(2, 1fr);
  }

  .batch-facts > div:nth-child(3) {
    border-right: 1px solid #e9edea;
  }

  .batch-facts > div:nth-child(even) {
    border-right: 0;
  }

  .event-card__facts,
  .trace-initial {
    grid-template-columns: 1fr;
  }

  .trace-initial > div {
    border-right: 0;
    border-bottom: 1px solid #e6eae6;
  }
}
</style>
