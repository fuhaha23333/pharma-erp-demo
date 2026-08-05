<template>
  <div v-loading="loading" class="supplier-detail-page">
    <template v-if="supplier">
      <PageHeader
        eyebrow="QUALITY · SUPPLIER RECORD"
        :title="supplier.supplierName"
        :description="`${supplier.supplierCode} · ${supplierTypeLabel(supplier.supplierType)} · 所有时间按浏览器本地时区展示`"
      >
        <template #actions>
          <ElButton :icon="Back" @click="$router.push('/quality/suppliers')">返回列表</ElButton>
          <ElButton
            v-if="canEdit"
            :icon="Edit"
            @click="openEditSupplier"
          >
            编辑档案
          </ElButton>
          <ElButton
            v-if="canSubmit"
            type="primary"
            :icon="Promotion"
            :loading="submitting"
            @click="confirmSubmit"
          >
            提交审核
          </ElButton>
          <ElTooltip
            v-if="canReview"
            :content="reviewerConflict ? '提交人不能审核本人提交的资料' : '作出审核决定'"
          >
            <span>
              <ElButton
                type="warning"
                :icon="Stamp"
                :disabled="reviewerConflict"
                @click="openReview"
              >
                审核
              </ElButton>
            </span>
          </ElTooltip>
        </template>
      </PageHeader>

      <section class="status-hero" :class="`status-hero--${supplier.qualificationStatus}`">
        <div>
          <p>当前准入状态</p>
          <div class="status-hero__title">
            <StatusTag :value="supplier.qualificationStatus" effect="dark" />
            <span>{{ statusMessage }}</span>
          </div>
        </div>
        <div class="status-hero__flow">
          <div
            v-for="step in workflow"
            :key="step.value"
            :class="{
              active: step.value === supplier.qualificationStatus,
              complete: isWorkflowComplete(step.value),
            }"
          >
            <i />
            <span>{{ step.label }}</span>
          </div>
        </div>
      </section>

      <div class="detail-layout">
        <div>
          <SectionCard title="企业档案" description="主体识别信息与联系方式">
            <div class="detail-grid">
              <div class="detail-field">
                <label>供应商编码</label>
                <strong>{{ supplier.supplierCode }}</strong>
              </div>
              <div class="detail-field">
                <label>企业类型</label>
                <span>{{ supplierTypeLabel(supplier.supplierType) }}</span>
              </div>
              <div class="detail-field detail-field--wide">
                <label>统一社会信用代码</label>
                <code class="table-code">{{ supplier.unifiedSocialCreditCode }}</code>
              </div>
              <div class="detail-field">
                <label>联系人</label>
                <span>{{ supplier.contactName || '—' }}</span>
              </div>
              <div class="detail-field">
                <label>联系电话</label>
                <span>{{ supplier.contactPhone || '—' }}</span>
              </div>
              <div class="detail-field detail-field--wide">
                <label>联系邮箱</label>
                <span>{{ supplier.contactEmail || '—' }}</span>
              </div>
              <div class="detail-field detail-field--wide">
                <label>企业地址</label>
                <span>{{ supplier.address || '—' }}</span>
              </div>
              <div class="detail-field">
                <label>审核通过时间</label>
                <span>{{ formatDateTime(supplier.approvedAt) }}</span>
              </div>
              <div class="detail-field">
                <label>综合有效期至</label>
                <span>{{ supplier.validUntil || '—' }}</span>
              </div>
            </div>
          </SectionCard>

          <SectionCard
            title="资质与附件"
            description="提交时每类必需资质至少要有一份当前有效附件"
          >
            <template #actions>
              <ElButton
                v-if="canEdit"
                size="small"
                type="primary"
                plain
                :icon="Plus"
                @click="openQualification()"
              >
                新增资质
              </ElButton>
            </template>

            <ElTable
              v-if="supplier.qualifications.length"
              :data="supplier.qualifications"
              row-key="id"
            >
              <ElTableColumn type="expand">
                <template #default="{ row }: { row: SupplierQualification }">
                  <div class="attachment-panel">
                    <div class="attachment-panel__head">
                      <span>受控附件元数据</span>
                      <ElButton
                        v-if="canEdit"
                        size="small"
                        :icon="Paperclip"
                        @click="openAttachment(row)"
                      >
                        登记附件
                      </ElButton>
                    </div>
                    <ElTable
                      v-if="row.attachments.length"
                      :data="row.attachments"
                      size="small"
                    >
                      <ElTableColumn label="文件名" min-width="170" prop="originalName" />
                      <ElTableColumn label="分类" width="105" prop="category" />
                      <ElTableColumn label="大小" width="90">
                        <template #default="{ row: attachment }: { row: SupplierAttachment }">
                          {{ formatFileSize(attachment.fileSize) }}
                        </template>
                      </ElTableColumn>
                      <ElTableColumn label="存储键" min-width="180" show-overflow-tooltip>
                        <template #default="{ row: attachment }: { row: SupplierAttachment }">
                          <code class="table-code">{{ attachment.storageKey }}</code>
                        </template>
                      </ElTableColumn>
                      <ElTableColumn label="SHA-256" min-width="180" show-overflow-tooltip>
                        <template #default="{ row: attachment }: { row: SupplierAttachment }">
                          <code class="table-code">{{ attachment.sha256 }}</code>
                        </template>
                      </ElTableColumn>
                      <ElTableColumn label="登记时间" min-width="170">
                        <template #default="{ row: attachment }: { row: SupplierAttachment }">
                          {{ formatDateTime(attachment.uploadedAt) }}
                        </template>
                      </ElTableColumn>
                    </ElTable>
                    <ElEmpty v-else :image-size="54" description="尚未登记附件元数据" />
                  </div>
                </template>
              </ElTableColumn>
              <ElTableColumn label="资质类型" min-width="180">
                <template #default="{ row }: { row: SupplierQualification }">
                  <div class="table-primary">{{ qualificationTypeLabel(row.qualificationType) }}</div>
                  <div class="table-secondary">ID {{ row.id }}</div>
                </template>
              </ElTableColumn>
              <ElTableColumn label="证书编号" min-width="170" prop="certificateNo" />
              <ElTableColumn label="发证机关" min-width="160">
                <template #default="{ row }: { row: SupplierQualification }">
                  {{ row.issuingAuthority || '—' }}
                </template>
              </ElTableColumn>
              <ElTableColumn label="有效期" min-width="185">
                <template #default="{ row }: { row: SupplierQualification }">
                  {{ row.validFrom || '—' }} 至 {{ row.validUntil || '长期' }}
                </template>
              </ElTableColumn>
              <ElTableColumn label="附件" width="90">
                <template #default="{ row }: { row: SupplierQualification }">
                  {{ row.attachments.length }} 份
                </template>
              </ElTableColumn>
              <ElTableColumn label="状态" width="105">
                <template #default="{ row }: { row: SupplierQualification }">
                  <StatusTag :value="row.status" />
                </template>
              </ElTableColumn>
              <ElTableColumn v-if="canEdit" label="操作" width="150" fixed="right">
                <template #default="{ row }: { row: SupplierQualification }">
                  <ElButton link type="primary" @click="openQualification(row)">编辑</ElButton>
                  <ElButton link type="primary" @click="openAttachment(row)">附件</ElButton>
                </template>
              </ElTableColumn>
            </ElTable>

            <div v-else class="empty-hint">
              <ElIcon :size="34"><Files /></ElIcon>
              <h3>尚未登记任何资质</h3>
              <p>先登记营业执照、匹配企业类型的许可证和授权文件。</p>
              <ElButton v-if="canEdit" type="primary" plain @click="openQualification()">
                新增第一份资质
              </ElButton>
            </div>
          </SectionCard>

          <SectionCard title="审核历史" description="每次提交生成独立轮次，旧结论不会被覆盖">
            <ElTimeline v-if="supplier.reviews.length">
              <ElTimelineItem
                v-for="review in supplier.reviews"
                :key="review.id"
                :timestamp="formatDateTime(review.reviewedAt || review.submittedAt)"
                :type="reviewTimelineType(review.status)"
                placement="top"
              >
                <div class="review-card">
                  <div class="review-card__head">
                    <div>
                      <strong>第 {{ review.reviewRound }} 轮 · {{ review.reviewNo }}</strong>
                      <span>提交人 ID {{ review.submittedBy }}</span>
                    </div>
                    <StatusTag :value="review.status" />
                  </div>
                  <div class="review-card__body">
                    <p>
                      <span>提交时间</span>
                      {{ formatDateTime(review.submittedAt) }}
                    </p>
                    <p>
                      <span>审核人</span>
                      {{ review.reviewerId ? `ID ${review.reviewerId}` : '等待审核' }}
                    </p>
                    <p v-if="review.reviewOpinion">
                      <span>审核意见</span>
                      {{ review.reviewOpinion }}
                    </p>
                    <p v-if="review.rejectionReason" class="review-card__rejection">
                      <span>驳回原因</span>
                      {{ review.rejectionReason }}
                    </p>
                  </div>
                </div>
              </ElTimelineItem>
            </ElTimeline>
            <ElEmpty v-else description="尚未提交审核" />
          </SectionCard>
        </div>

        <aside>
          <SectionCard title="提交完整性检查" description="仅作前端提示，后端会重新严格校验">
            <div class="checklist">
              <div v-for="item in requiredChecklist" :key="item.type">
                <span :class="{ passed: item.passed }">
                  <ElIcon>
                    <CircleCheckFilled v-if="item.passed" />
                    <WarningFilled v-else />
                  </ElIcon>
                </span>
                <div>
                  <strong>{{ item.label }}</strong>
                  <p>{{ item.message }}</p>
                </div>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="职责分离" description="供应商审核的第一阶段守卫">
            <div class="guard-list">
              <p><ElIcon><Lock /></ElIcon> 提交人不能审核本人资料</p>
              <p><ElIcon><DocumentChecked /></ElIcon> 驳回必须填写原因</p>
              <p><ElIcon><Clock /></ElIcon> 每次提交固化资质快照</p>
              <p><ElIcon><View /></ElIcon> 已完成结论只读保留</p>
            </div>
          </SectionCard>
        </aside>
      </div>
    </template>

    <div v-else-if="!loading" class="result-page">
      <div class="result-page__code">!</div>
      <h1>供应商记录不可用</h1>
      <p>记录可能不存在，或当前账号没有读取权限。</p>
      <ElButton type="primary" @click="$router.push('/quality/suppliers')">
        返回供应商列表
      </ElButton>
    </div>

    <ElDialog
      v-model="supplierDialog.visible"
      title="编辑供应商档案"
      width="680px"
      destroy-on-close
    >
      <ElForm
        ref="supplierFormRef"
        :model="supplierForm"
        :rules="supplierRules"
        label-position="top"
      >
        <div class="two-column-form">
          <ElFormItem class="span-two" label="企业名称" prop="supplierName">
            <ElInput v-model="supplierForm.supplierName" />
          </ElFormItem>
          <ElFormItem label="企业类型" prop="supplierType">
            <ElSelect v-model="supplierForm.supplierType" style="width: 100%">
              <ElOption
                v-for="option in supplierTypeOptions"
                :key="option.value"
                :label="option.label"
                :value="option.value"
              />
            </ElSelect>
          </ElFormItem>
          <ElFormItem label="统一社会信用代码" prop="unifiedSocialCreditCode">
            <ElInput v-model="supplierForm.unifiedSocialCreditCode" />
          </ElFormItem>
          <ElFormItem label="联系人">
            <ElInput v-model="supplierForm.contactName" />
          </ElFormItem>
          <ElFormItem label="联系电话">
            <ElInput v-model="supplierForm.contactPhone" />
          </ElFormItem>
          <ElFormItem class="span-two" label="联系邮箱" prop="contactEmail">
            <ElInput v-model="supplierForm.contactEmail" />
          </ElFormItem>
          <ElFormItem class="span-two" label="企业地址">
            <ElInput v-model="supplierForm.address" type="textarea" :rows="2" maxlength="500" />
          </ElFormItem>
          <ElFormItem class="span-two" label="修改原因" prop="changeReason">
            <ElInput
              v-model="supplierForm.changeReason"
              type="textarea"
              :rows="3"
              maxlength="500"
              show-word-limit
            />
          </ElFormItem>
        </div>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="supplierDialog.visible = false">取消</ElButton>
          <ElButton
            type="primary"
            :loading="supplierDialog.saving"
            @click="saveSupplier"
          >
            保存
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="qualificationDialog.visible"
      :title="qualificationDialog.qualificationId ? '编辑资质' : '新增资质'"
      width="620px"
      destroy-on-close
      @closed="resetQualificationForm"
    >
      <ElForm
        ref="qualificationFormRef"
        :model="qualificationForm"
        :rules="qualificationRules"
        label-position="top"
      >
        <div class="two-column-form">
          <ElFormItem label="资质类型" prop="qualificationType">
            <ElSelect v-model="qualificationForm.qualificationType" style="width: 100%">
              <ElOption
                v-for="option in qualificationTypeOptions"
                :key="option.value"
                :label="option.label"
                :value="option.value"
              />
            </ElSelect>
          </ElFormItem>
          <ElFormItem label="证书编号" prop="certificateNo">
            <ElInput v-model="qualificationForm.certificateNo" />
          </ElFormItem>
          <ElFormItem class="span-two" label="发证机关">
            <ElInput v-model="qualificationForm.issuingAuthority" />
          </ElFormItem>
          <ElFormItem label="发证日期">
            <ElDatePicker
              v-model="qualificationForm.issuedOn"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="选择日期"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem label="有效期开始">
            <ElDatePicker
              v-model="qualificationForm.validFrom"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="选择日期"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem label="有效期截止">
            <ElDatePicker
              v-model="qualificationForm.validUntil"
              type="date"
              value-format="YYYY-MM-DD"
              placeholder="长期有效可留空"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem class="span-two" label="备注">
            <ElInput
              v-model="qualificationForm.remark"
              type="textarea"
              :rows="3"
              maxlength="500"
              show-word-limit
            />
          </ElFormItem>
        </div>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="qualificationDialog.visible = false">取消</ElButton>
          <ElButton
            type="primary"
            :loading="qualificationDialog.saving"
            @click="saveQualification"
          >
            保存资质
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="attachmentDialog.visible"
      title="登记受控附件元数据"
      width="650px"
      destroy-on-close
      @closed="resetAttachmentForm"
    >
      <ElAlert
        title="当前接口不上传文件内容"
        description="文件应先写入受控存储，本页面只登记存储键、大小、类型和 SHA-256 摘要，不会伪造上传成功。"
        type="warning"
        :closable="false"
        show-icon
      />
      <ElForm
        ref="attachmentFormRef"
        class="dialog-form"
        :model="attachmentForm"
        :rules="attachmentRules"
        label-position="top"
      >
        <div class="two-column-form">
          <ElFormItem label="附件分类" prop="category">
            <ElSelect v-model="attachmentForm.category" style="width: 100%">
              <ElOption label="许可证件" value="LICENSE" />
              <ElOption label="授权文件" value="AUTHORIZATION" />
              <ElOption label="其他" value="OTHER" />
            </ElSelect>
          </ElFormItem>
          <ElFormItem label="原始文件名" prop="originalName">
            <ElInput v-model="attachmentForm.originalName" placeholder="例如：营业执照.pdf" />
          </ElFormItem>
          <ElFormItem class="span-two" label="受控存储键" prop="storageKey">
            <ElInput
              v-model="attachmentForm.storageKey"
              placeholder="例如：supplier/SUP-0001/license/xxx.pdf"
            />
          </ElFormItem>
          <ElFormItem label="内容类型" prop="contentType">
            <ElInput v-model="attachmentForm.contentType" placeholder="application/pdf" />
          </ElFormItem>
          <ElFormItem label="文件大小（字节）" prop="fileSize">
            <ElInputNumber
              v-model="attachmentForm.fileSize"
              :min="0"
              :precision="0"
              controls-position="right"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem class="span-two" label="SHA-256 摘要" prop="sha256">
            <ElInput
              v-model="attachmentForm.sha256"
              placeholder="64 位十六进制字符"
              maxlength="64"
            />
          </ElFormItem>
        </div>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="attachmentDialog.visible = false">取消</ElButton>
          <ElButton
            type="primary"
            :loading="attachmentDialog.saving"
            @click="saveAttachment"
          >
            登记元数据
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="reviewDialog.visible"
      title="供应商资质审核"
      width="580px"
      destroy-on-close
    >
      <ElAlert
        title="审核结论不可覆盖"
        description="通过会计算必需资质的最早有效期；驳回必须填写明确原因。"
        type="warning"
        :closable="false"
        show-icon
      />
      <ElForm label-position="top" class="dialog-form">
        <ElFormItem label="审核决定" required>
          <ReviewDecisionField v-model="reviewForm.decision" />
        </ElFormItem>
        <ElFormItem label="审核意见">
          <ElInput
            v-model="reviewForm.reviewOpinion"
            type="textarea"
            :rows="3"
            maxlength="1000"
            show-word-limit
            placeholder="记录核验依据和结论"
          />
        </ElFormItem>
        <ElFormItem
          v-if="reviewForm.decision === 'REJECTED'"
          label="驳回原因"
          required
        >
          <ElInput
            v-model="reviewForm.rejectionReason"
            type="textarea"
            :rows="3"
            maxlength="1000"
            show-word-limit
            placeholder="说明不能通过的具体问题"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="reviewDialog.visible = false">取消</ElButton>
          <ElButton
            :type="reviewForm.decision === 'APPROVED' ? 'success' : 'danger'"
            :loading="reviewDialog.saving"
            @click="saveReview"
          >
            提交审核结论
          </ElButton>
        </div>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
import {
  Back,
  CircleCheckFilled,
  Clock,
  DocumentChecked,
  Edit,
  Files,
  Lock,
  Paperclip,
  Plus,
  Promotion,
  Stamp,
  View,
  WarningFilled,
} from '@element-plus/icons-vue'
import {
  ElMessage,
  ElMessageBox,
  type FormInstance,
  type FormRules,
  type TimelineItemProps,
} from 'element-plus'
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getErrorMessage } from '@/api/http'
import {
  addQualification,
  getSupplier,
  registerAttachment,
  reviewSupplier,
  submitSupplier,
  updateQualification,
  updateSupplier,
} from '@/api/supplier'
import PageHeader from '@/components/PageHeader.vue'
import ReviewDecisionField from '@/components/ReviewDecisionField.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import {
  qualificationTypeOptions,
  supplierTypeOptions,
} from '@/constants/options'
import { PERMISSIONS } from '@/constants/permissions'
import {
  buildQualificationChecklist,
  isReviewerConflict,
  isSupplierEditable,
  validateReviewDecision,
} from '@/domain/supplierRules'
import { authState, hasPermission } from '@/stores/auth'
import type {
  AttachmentPayload,
  QualificationPayload,
  QualificationType,
  Supplier,
  SupplierAttachment,
  SupplierQualification,
  SupplierType,
} from '@/types/supplier'
import { formatDateTime } from '@/utils/datetime'
import { formatFileSize, optionalText } from '@/utils/format'

interface SupplierEditForm {
  supplierName: string
  supplierType: SupplierType
  unifiedSocialCreditCode: string
  contactName: string
  contactPhone: string
  contactEmail: string
  address: string
  changeReason: string
}

interface QualificationForm {
  qualificationType: QualificationType
  certificateNo: string
  issuingAuthority: string
  issuedOn: string
  validFrom: string
  validUntil: string
  remark: string
}

interface AttachmentForm {
  category: 'LICENSE' | 'AUTHORIZATION' | 'OTHER'
  originalName: string
  storageKey: string
  contentType: string
  fileSize: number
  sha256: string
}

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const submitting = ref(false)
const supplier = ref<Supplier | null>(null)
const supplierId = computed(() => Number(route.params.supplierId))

const workflow = [
  { value: 'DRAFT', label: '资料草稿' },
  { value: 'UNDER_REVIEW', label: '审核中' },
  { value: 'APPROVED', label: '已通过' },
]

const canEdit = computed(
  () =>
    !!supplier.value &&
    isSupplierEditable(supplier.value.qualificationStatus) &&
    hasPermission(PERMISSIONS.SUPPLIER_WRITE),
)
const canSubmit = computed(
  () =>
    !!supplier.value &&
    isSupplierEditable(supplier.value.qualificationStatus) &&
    hasPermission(PERMISSIONS.SUPPLIER_SUBMIT),
)
const pendingReview = computed(() =>
  supplier.value?.reviews.find((review) => review.status === 'PENDING'),
)
const canReview = computed(
  () =>
    supplier.value?.qualificationStatus === 'UNDER_REVIEW' &&
    !!pendingReview.value &&
    hasPermission(PERMISSIONS.SUPPLIER_REVIEW),
)
const reviewerConflict = computed(
  () => isReviewerConflict(authState.user?.id, pendingReview.value),
)

const statusMessage = computed(() => {
  const messages: Record<string, string> = {
    DRAFT: '资料仍可编辑；补齐必需资质和附件后方可提交。',
    UNDER_REVIEW: '资料快照已固化，等待非提交人作出审核决定。',
    APPROVED: '当前资质审核通过；后续业务仍需动态检查有效期和许可范围。',
    REJECTED: '本轮审核未通过；修正资料后可以生成新的审核轮次。',
    EXPIRED: '资质已失效，不得作为有效采购来源。',
    DISABLED: '供应商已停用，不得继续业务使用。',
  }
  return messages[supplier.value?.qualificationStatus || ''] || '状态需要人工核查。'
})

function isWorkflowComplete(value: string): boolean {
  const status = supplier.value?.qualificationStatus
  if (status === 'APPROVED') return true
  if (status === 'UNDER_REVIEW') return value === 'DRAFT' || value === 'UNDER_REVIEW'
  if (status === 'REJECTED') return value === 'DRAFT' || value === 'UNDER_REVIEW'
  return value === 'DRAFT'
}

const requiredChecklist = computed(() =>
  supplier.value ? buildQualificationChecklist(supplier.value) : [],
)

async function loadSupplier(): Promise<void> {
  if (!Number.isFinite(supplierId.value) || supplierId.value <= 0) {
    ElMessage.error('供应商 ID 不正确')
    await router.replace('/quality/suppliers')
    return
  }
  loading.value = true
  try {
    supplier.value = await getSupplier(supplierId.value)
  } catch (error) {
    supplier.value = null
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

const supplierFormRef = ref<FormInstance>()
const supplierDialog = reactive({ visible: false, saving: false })
const supplierForm = reactive<SupplierEditForm>({
  supplierName: '',
  supplierType: 'WHOLESALE',
  unifiedSocialCreditCode: '',
  contactName: '',
  contactPhone: '',
  contactEmail: '',
  address: '',
  changeReason: '',
})
const supplierRules: FormRules<SupplierEditForm> = {
  supplierName: [{ required: true, message: '请输入企业名称', trigger: 'blur' }],
  supplierType: [{ required: true, message: '请选择企业类型', trigger: 'change' }],
  unifiedSocialCreditCode: [
    { required: true, message: '请输入统一社会信用代码', trigger: 'blur' },
  ],
  contactEmail: [{ type: 'email', message: '请输入有效邮箱地址', trigger: 'blur' }],
  changeReason: [{ required: true, message: '请填写修改原因', trigger: 'blur' }],
}

function openEditSupplier(): void {
  if (!supplier.value) return
  Object.assign(supplierForm, {
    supplierName: supplier.value.supplierName,
    supplierType: supplier.value.supplierType,
    unifiedSocialCreditCode: supplier.value.unifiedSocialCreditCode,
    contactName: supplier.value.contactName || '',
    contactPhone: supplier.value.contactPhone || '',
    contactEmail: supplier.value.contactEmail || '',
    address: supplier.value.address || '',
    changeReason: '',
  })
  supplierDialog.visible = true
}

async function saveSupplier(): Promise<void> {
  const valid = await supplierFormRef.value?.validate().catch(() => false)
  if (!valid) return
  supplierDialog.saving = true
  try {
    await updateSupplier(supplierId.value, {
      supplierName: supplierForm.supplierName.trim(),
      supplierType: supplierForm.supplierType,
      unifiedSocialCreditCode: supplierForm.unifiedSocialCreditCode.trim(),
      contactName: optionalText(supplierForm.contactName),
      contactPhone: optionalText(supplierForm.contactPhone),
      contactEmail: optionalText(supplierForm.contactEmail),
      address: optionalText(supplierForm.address),
      changeReason: supplierForm.changeReason.trim(),
    })
    ElMessage.success('供应商档案已更新')
    supplierDialog.visible = false
    await loadSupplier()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    supplierDialog.saving = false
  }
}

const qualificationFormRef = ref<FormInstance>()
const qualificationDialog = reactive({
  visible: false,
  saving: false,
  qualificationId: 0,
})
const qualificationForm = reactive<QualificationForm>({
  qualificationType: 'BUSINESS_LICENSE',
  certificateNo: '',
  issuingAuthority: '',
  issuedOn: '',
  validFrom: '',
  validUntil: '',
  remark: '',
})
const qualificationRules: FormRules<QualificationForm> = {
  qualificationType: [{ required: true, message: '请选择资质类型', trigger: 'change' }],
  certificateNo: [{ required: true, message: '请输入证书编号', trigger: 'blur' }],
}

function resetQualificationForm(): void {
  qualificationFormRef.value?.resetFields()
  Object.assign(qualificationForm, {
    qualificationType: 'BUSINESS_LICENSE',
    certificateNo: '',
    issuingAuthority: '',
    issuedOn: '',
    validFrom: '',
    validUntil: '',
    remark: '',
  })
  qualificationDialog.qualificationId = 0
}

function openQualification(qualification?: SupplierQualification): void {
  resetQualificationForm()
  if (qualification) {
    qualificationDialog.qualificationId = qualification.id
    Object.assign(qualificationForm, {
      qualificationType: qualification.qualificationType,
      certificateNo: qualification.certificateNo,
      issuingAuthority: qualification.issuingAuthority || '',
      issuedOn: qualification.issuedOn || '',
      validFrom: qualification.validFrom || '',
      validUntil: qualification.validUntil || '',
      remark: qualification.remark || '',
    })
  }
  qualificationDialog.visible = true
}

async function saveQualification(): Promise<void> {
  const valid = await qualificationFormRef.value?.validate().catch(() => false)
  if (!valid) return
  if (
    qualificationForm.validFrom &&
    qualificationForm.validUntil &&
    qualificationForm.validFrom > qualificationForm.validUntil
  ) {
    ElMessage.warning('有效期开始日期不能晚于截止日期')
    return
  }
  const payload: QualificationPayload = {
    qualificationType: qualificationForm.qualificationType,
    certificateNo: qualificationForm.certificateNo.trim(),
    issuingAuthority: optionalText(qualificationForm.issuingAuthority),
    issuedOn: optionalText(qualificationForm.issuedOn),
    validFrom: optionalText(qualificationForm.validFrom),
    validUntil: optionalText(qualificationForm.validUntil),
    remark: optionalText(qualificationForm.remark),
  }
  qualificationDialog.saving = true
  try {
    if (qualificationDialog.qualificationId) {
      await updateQualification(
        supplierId.value,
        qualificationDialog.qualificationId,
        payload,
      )
      ElMessage.success('资质已更新')
    } else {
      await addQualification(supplierId.value, payload)
      ElMessage.success('资质已新增')
    }
    qualificationDialog.visible = false
    await loadSupplier()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    qualificationDialog.saving = false
  }
}

const attachmentFormRef = ref<FormInstance>()
const attachmentDialog = reactive({
  visible: false,
  saving: false,
  qualification: null as SupplierQualification | null,
})
const attachmentForm = reactive<AttachmentForm>({
  category: 'LICENSE',
  originalName: '',
  storageKey: '',
  contentType: 'application/pdf',
  fileSize: 0,
  sha256: '',
})
const attachmentRules: FormRules<AttachmentForm> = {
  category: [{ required: true, message: '请选择附件分类', trigger: 'change' }],
  originalName: [{ required: true, message: '请输入原始文件名', trigger: 'blur' }],
  storageKey: [{ required: true, message: '请输入受控存储键', trigger: 'blur' }],
  contentType: [{ required: true, message: '请输入内容类型', trigger: 'blur' }],
  fileSize: [{ required: true, message: '请输入文件大小', trigger: 'change' }],
  sha256: [
    { required: true, message: '请输入 SHA-256 摘要', trigger: 'blur' },
    {
      pattern: /^[a-fA-F0-9]{64}$/,
      message: 'SHA-256 必须是 64 位十六进制字符',
      trigger: 'blur',
    },
  ],
}

function resetAttachmentForm(): void {
  attachmentFormRef.value?.resetFields()
  Object.assign(attachmentForm, {
    category: 'LICENSE',
    originalName: '',
    storageKey: '',
    contentType: 'application/pdf',
    fileSize: 0,
    sha256: '',
  })
  attachmentDialog.qualification = null
}

function openAttachment(qualification: SupplierQualification): void {
  resetAttachmentForm()
  attachmentDialog.qualification = qualification
  attachmentForm.category =
    qualification.qualificationType === 'AUTHORIZATION' ? 'AUTHORIZATION' : 'LICENSE'
  attachmentDialog.visible = true
}

async function saveAttachment(): Promise<void> {
  const valid = await attachmentFormRef.value?.validate().catch(() => false)
  if (!valid || !attachmentDialog.qualification) return
  const payload: AttachmentPayload = {
    category: attachmentForm.category,
    originalName: attachmentForm.originalName.trim(),
    storageKey: attachmentForm.storageKey.trim(),
    contentType: attachmentForm.contentType.trim(),
    fileSize: attachmentForm.fileSize,
    sha256: attachmentForm.sha256.trim().toLowerCase(),
  }
  attachmentDialog.saving = true
  try {
    await registerAttachment(
      supplierId.value,
      attachmentDialog.qualification.id,
      payload,
    )
    ElMessage.success('附件元数据已登记')
    attachmentDialog.visible = false
    await loadSupplier()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    attachmentDialog.saving = false
  }
}

async function confirmSubmit(): Promise<void> {
  try {
    await ElMessageBox.confirm(
      '提交后当前资质会固化为不可变快照，审核完成前不能继续修改。确认提交吗？',
      '提交供应商审核',
      {
        confirmButtonText: '确认提交',
        cancelButtonText: '继续检查',
        type: 'warning',
      },
    )
  } catch {
    return
  }
  submitting.value = true
  try {
    await submitSupplier(supplierId.value)
    ElMessage.success('供应商资料已提交审核')
    await loadSupplier()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    submitting.value = false
  }
}

const reviewDialog = reactive({ visible: false, saving: false })
const reviewForm = reactive<{
  decision: 'APPROVED' | 'REJECTED'
  reviewOpinion: string
  rejectionReason: string
}>({
  decision: 'APPROVED',
  reviewOpinion: '',
  rejectionReason: '',
})

function openReview(): void {
  if (reviewerConflict.value) {
    ElMessage.warning('提交人不能审核本人提交的供应商资料')
    return
  }
  Object.assign(reviewForm, {
    decision: 'APPROVED',
    reviewOpinion: '',
    rejectionReason: '',
  })
  reviewDialog.visible = true
}

async function saveReview(): Promise<void> {
  if (!pendingReview.value) {
    ElMessage.warning('没有待处理的审核轮次')
    return
  }
  const validationMessage = validateReviewDecision(
    reviewForm.decision,
    reviewForm.rejectionReason,
  )
  if (validationMessage) {
    ElMessage.warning(validationMessage)
    return
  }
  reviewDialog.saving = true
  try {
    await reviewSupplier(supplierId.value, pendingReview.value.id, {
      decision: reviewForm.decision,
      reviewOpinion: optionalText(reviewForm.reviewOpinion),
      rejectionReason:
        reviewForm.decision === 'REJECTED'
          ? reviewForm.rejectionReason.trim()
          : undefined,
    })
    ElMessage.success(reviewForm.decision === 'APPROVED' ? '审核已通过' : '审核已驳回')
    reviewDialog.visible = false
    await loadSupplier()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    reviewDialog.saving = false
  }
}

function supplierTypeLabel(type: string): string {
  return supplierTypeOptions.find((item) => item.value === type)?.label || type
}

function qualificationTypeLabel(type: string): string {
  return qualificationTypeOptions.find((item) => item.value === type)?.label || type
}

function reviewTimelineType(status: string): TimelineItemProps['type'] {
  if (status === 'APPROVED') return 'success'
  if (status === 'REJECTED') return 'danger'
  if (status === 'PENDING') return 'warning'
  return 'info'
}

onMounted(loadSupplier)
</script>

<style scoped>
.supplier-detail-page {
  min-height: 65vh;
}

.status-hero {
  display: flex;
  min-height: 120px;
  align-items: center;
  justify-content: space-between;
  gap: 30px;
  margin-bottom: 20px;
  padding: 24px 28px;
  border: 1px solid #dfe6e1;
  border-radius: 15px 5px 15px 5px;
  background: linear-gradient(110deg, #f9faf7, #eef4f0);
}

.status-hero--REJECTED,
.status-hero--EXPIRED,
.status-hero--DISABLED {
  background: linear-gradient(110deg, #fbf8f5, #f6ece8);
}

.status-hero > div:first-child > p {
  margin-bottom: 9px;
  color: #7a8883;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.15em;
}

.status-hero__title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.status-hero__title > span {
  max-width: 540px;
  color: #55665f;
  font-size: 12px;
  line-height: 1.6;
}

.status-hero__flow {
  display: flex;
  min-width: 320px;
  align-items: center;
}

.status-hero__flow > div {
  position: relative;
  display: flex;
  flex: 1;
  align-items: center;
  flex-direction: column;
  gap: 7px;
  color: #9ca7a3;
  font-size: 10px;
}

.status-hero__flow > div:not(:last-child)::after {
  position: absolute;
  top: 6px;
  left: calc(50% + 8px);
  width: calc(100% - 16px);
  height: 1px;
  background: #d5ddd8;
  content: "";
}

.status-hero__flow i {
  position: relative;
  z-index: 1;
  width: 13px;
  height: 13px;
  border: 3px solid #e9edea;
  border-radius: 50%;
  background: #aeb9b5;
}

.status-hero__flow .complete i,
.status-hero__flow .active i {
  background: #26745e;
}

.status-hero__flow .complete:not(:last-child)::after {
  background: #80aa9b;
}

.status-hero__flow .active {
  color: #235f4f;
  font-weight: 700;
}

.detail-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 330px;
  align-items: start;
  gap: 20px;
}

.attachment-panel {
  padding: 10px 30px 22px 62px;
  background: #f8faf8;
}

.attachment-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  color: #586a63;
  font-size: 12px;
  font-weight: 700;
}

.review-card {
  padding: 15px 17px;
  border: 1px solid #e4e9e5;
  border-radius: 11px 4px 11px 4px;
  background: #fbfbf8;
}

.review-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 15px;
}

.review-card__head strong,
.review-card__head span {
  display: block;
}

.review-card__head strong {
  color: #263b34;
  font-size: 12px;
}

.review-card__head span {
  margin-top: 4px;
  color: #8a9692;
  font-size: 10px;
}

.review-card__body {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px 18px;
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid #ebeeeb;
}

.review-card__body p {
  margin: 0;
  color: #52645d;
  font-size: 11px;
  line-height: 1.55;
}

.review-card__body p span {
  display: block;
  margin-bottom: 3px;
  color: #929d99;
  font-size: 9px;
}

.review-card__rejection {
  color: #a64d46 !important;
}

.checklist > div {
  display: flex;
  gap: 10px;
  padding: 13px 0;
  border-bottom: 1px solid #ecefec;
}

.checklist > div:last-child {
  border-bottom: 0;
}

.checklist > div > span {
  flex: 0 0 auto;
  color: #c98235;
}

.checklist > div > span.passed {
  color: #28765f;
}

.checklist strong {
  color: #30443d;
  font-size: 12px;
}

.checklist p {
  margin: 4px 0 0;
  color: #82908b;
  font-size: 10px;
  line-height: 1.5;
}

.guard-list p {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 12px;
  color: #5e6e68;
  font-size: 11px;
  line-height: 1.55;
}

.guard-list p:last-child {
  margin-bottom: 0;
}

.guard-list .el-icon {
  flex: 0 0 auto;
  margin-top: 2px;
  color: #2b735e;
}

.two-column-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 18px;
}

.span-two {
  grid-column: span 2;
}

.dialog-form {
  margin-top: 20px;
}

@media (max-width: 1150px) {
  .detail-layout {
    grid-template-columns: 1fr;
  }

  .detail-layout > aside {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }
}

@media (max-width: 760px) {
  .status-hero {
    align-items: stretch;
    flex-direction: column;
  }

  .status-hero__title {
    align-items: flex-start;
    flex-direction: column;
  }

  .status-hero__flow {
    min-width: 0;
  }

  .detail-layout > aside {
    display: block;
  }

  .two-column-form,
  .review-card__body {
    grid-template-columns: 1fr;
  }

  .span-two {
    grid-column: auto;
  }

  .attachment-panel {
    padding-left: 20px;
  }
}
</style>
