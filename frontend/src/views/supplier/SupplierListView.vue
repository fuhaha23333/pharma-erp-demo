<template>
  <div>
    <PageHeader
      eyebrow="QUALITY · SUPPLIERS"
      title="供应商审核"
      description="从供应商草稿开始，登记必需资质与受控附件元数据，提交后由非提交人完成审核。"
    >
      <template #actions>
        <ElButton
          v-if="hasPermission(PERMISSIONS.SUPPLIER_WRITE)"
          type="primary"
          :icon="Plus"
          @click="openCreate"
        >
          新建供应商
        </ElButton>
      </template>
    </PageHeader>

    <SectionCard>
      <div class="filter-bar">
        <ElInput
          v-model="query.keyword"
          clearable
          placeholder="编码、名称或信用代码"
          @keyup.enter="search"
        />
        <ElSelect v-model="query.supplierType" clearable placeholder="供应商类型">
          <ElOption
            v-for="option in supplierTypeOptions"
            :key="option.value"
            :label="option.label"
            :value="option.value"
          />
        </ElSelect>
        <ElSelect
          v-model="query.qualificationStatus"
          clearable
          placeholder="审核状态"
        >
          <ElOption
            v-for="option in supplierStatusOptions"
            :key="option.value"
            :label="option.label"
            :value="option.value"
          />
        </ElSelect>
        <div class="filter-bar__actions">
          <ElButton :icon="Refresh" @click="resetQuery">重置</ElButton>
          <ElButton type="primary" :icon="Search" @click="search">查询</ElButton>
        </div>
      </div>
    </SectionCard>

    <SectionCard flush>
      <template #header>
        <div>
          <h2>供应商目录</h2>
          <p>共 {{ page.total }} 家；已通过状态只在当前资质有效期内成立</p>
        </div>
      </template>

      <ElTable v-loading="loading" :data="page.records" row-key="id">
        <ElTableColumn label="供应商" min-width="240">
          <template #default="{ row }: { row: Supplier }">
            <div class="supplier-cell">
              <span>{{ row.supplierType === 'PRODUCTION' ? '产' : '批' }}</span>
              <div>
                <div class="table-primary">{{ row.supplierName }}</div>
                <div class="table-code">{{ row.supplierCode }}</div>
              </div>
            </div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="企业类型" width="145">
          <template #default="{ row }: { row: Supplier }">
            {{ supplierTypeLabel(row.supplierType) }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="统一社会信用代码" min-width="185">
          <template #default="{ row }: { row: Supplier }">
            <code class="table-code">{{ row.unifiedSocialCreditCode }}</code>
          </template>
        </ElTableColumn>
        <ElTableColumn label="联系人" min-width="150">
          <template #default="{ row }: { row: Supplier }">
            <div>{{ row.contactName || '—' }}</div>
            <div class="table-secondary">{{ row.contactPhone || '未填写电话' }}</div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="审核状态" width="125">
          <template #default="{ row }: { row: Supplier }">
            <StatusTag :value="row.qualificationStatus" />
          </template>
        </ElTableColumn>
        <ElTableColumn label="有效期至" width="130">
          <template #default="{ row }: { row: Supplier }">
            {{ row.validUntil || '—' }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="更新时间" min-width="170">
          <template #default="{ row }: { row: Supplier }">
            {{ formatDateTime(row.updatedAt) }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="操作" width="125" fixed="right">
          <template #default="{ row }: { row: Supplier }">
            <ElButton link type="primary" @click="openDetail(row.id)">
              查看与办理
              <ElIcon class="el-icon--right"><ArrowRight /></ElIcon>
            </ElButton>
          </template>
        </ElTableColumn>
      </ElTable>

      <div class="pagination-row">
        <ElPagination
          v-model:current-page="query.pageNo"
          v-model:page-size="query.pageSize"
          :total="page.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          @size-change="loadSuppliers"
          @current-change="loadSuppliers"
        />
      </div>
    </SectionCard>

    <ElDialog
      v-model="dialog.visible"
      title="新建供应商草稿"
      width="680px"
      destroy-on-close
      @closed="resetForm"
    >
      <ElAlert
        title="新建后仍需登记资质和附件，并单独提交审核"
        type="info"
        :closable="false"
        show-icon
      />
      <ElForm
        ref="formRef"
        class="supplier-form"
        :model="form"
        :rules="rules"
        label-position="top"
      >
        <div class="two-column-form">
          <ElFormItem label="供应商编码" prop="supplierCode">
            <ElInput v-model="form.supplierCode" placeholder="例如：SUP-0001" />
          </ElFormItem>
          <ElFormItem label="企业类型" prop="supplierType">
            <ElSelect v-model="form.supplierType" style="width: 100%">
              <ElOption
                v-for="option in supplierTypeOptions"
                :key="option.value"
                :label="option.label"
                :value="option.value"
              />
            </ElSelect>
          </ElFormItem>
          <ElFormItem class="span-two" label="企业名称" prop="supplierName">
            <ElInput v-model="form.supplierName" placeholder="与证照主体名称保持一致" />
          </ElFormItem>
          <ElFormItem class="span-two" label="统一社会信用代码" prop="unifiedSocialCreditCode">
            <ElInput
              v-model="form.unifiedSocialCreditCode"
              placeholder="请输入证照上的统一社会信用代码"
            />
          </ElFormItem>
          <ElFormItem label="联系人">
            <ElInput v-model="form.contactName" placeholder="选填" />
          </ElFormItem>
          <ElFormItem label="联系电话">
            <ElInput v-model="form.contactPhone" placeholder="选填" />
          </ElFormItem>
          <ElFormItem class="span-two" label="联系邮箱" prop="contactEmail">
            <ElInput v-model="form.contactEmail" placeholder="选填" />
          </ElFormItem>
          <ElFormItem class="span-two" label="企业地址">
            <ElInput
              v-model="form.address"
              type="textarea"
              :rows="2"
              maxlength="500"
              show-word-limit
            />
          </ElFormItem>
        </div>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="dialog.visible = false">取消</ElButton>
          <ElButton type="primary" :loading="dialog.saving" @click="saveSupplier">
            创建并进入详情
          </ElButton>
        </div>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
import { ArrowRight, Plus, Refresh, Search } from '@element-plus/icons-vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { onMounted, reactive, ref } from 'vue'
import { getErrorMessage } from '@/api/http'
import { createSupplier, getSuppliers } from '@/api/supplier'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import {
  supplierStatusOptions,
  supplierTypeOptions,
} from '@/constants/options'
import { PERMISSIONS } from '@/constants/permissions'
import { hasPermission } from '@/stores/auth'
import type { PageResult } from '@/types/api'
import type {
  Supplier,
  SupplierCreatePayload,
  SupplierPageQuery,
  SupplierType,
} from '@/types/supplier'
import { formatDateTime } from '@/utils/datetime'
import { optionalText } from '@/utils/format'
import { useRouter } from 'vue-router'

interface SupplierFormModel {
  supplierCode: string
  supplierName: string
  supplierType: SupplierType
  unifiedSocialCreditCode: string
  contactName: string
  contactPhone: string
  contactEmail: string
  address: string
}

const router = useRouter()
const loading = ref(false)
const page = reactive<PageResult<Supplier>>({
  records: [],
  total: 0,
  pageNo: 1,
  pageSize: 20,
})
const query = reactive<SupplierPageQuery>({
  pageNo: 1,
  pageSize: 20,
  keyword: '',
  qualificationStatus: '',
  supplierType: '',
})

const formRef = ref<FormInstance>()
const dialog = reactive({ visible: false, saving: false })
const form = reactive<SupplierFormModel>({
  supplierCode: '',
  supplierName: '',
  supplierType: 'WHOLESALE',
  unifiedSocialCreditCode: '',
  contactName: '',
  contactPhone: '',
  contactEmail: '',
  address: '',
})
const rules: FormRules<SupplierFormModel> = {
  supplierCode: [{ required: true, message: '请输入供应商编码', trigger: 'blur' }],
  supplierName: [{ required: true, message: '请输入企业名称', trigger: 'blur' }],
  supplierType: [{ required: true, message: '请选择企业类型', trigger: 'change' }],
  unifiedSocialCreditCode: [
    { required: true, message: '请输入统一社会信用代码', trigger: 'blur' },
  ],
  contactEmail: [{ type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' }],
}

async function loadSuppliers(): Promise<void> {
  loading.value = true
  try {
    Object.assign(page, await getSuppliers(query))
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

function search(): void {
  query.pageNo = 1
  void loadSuppliers()
}

function resetQuery(): void {
  Object.assign(query, {
    pageNo: 1,
    pageSize: 20,
    keyword: '',
    qualificationStatus: '',
    supplierType: '',
  })
  void loadSuppliers()
}

function openCreate(): void {
  resetForm()
  dialog.visible = true
}

function resetForm(): void {
  formRef.value?.resetFields()
  Object.assign(form, {
    supplierCode: '',
    supplierName: '',
    supplierType: 'WHOLESALE',
    unifiedSocialCreditCode: '',
    contactName: '',
    contactPhone: '',
    contactEmail: '',
    address: '',
  })
}

async function saveSupplier(): Promise<void> {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  dialog.saving = true
  try {
    const payload: SupplierCreatePayload = {
      supplierCode: form.supplierCode.trim(),
      supplierName: form.supplierName.trim(),
      supplierType: form.supplierType,
      unifiedSocialCreditCode: form.unifiedSocialCreditCode.trim(),
      contactName: optionalText(form.contactName),
      contactPhone: optionalText(form.contactPhone),
      contactEmail: optionalText(form.contactEmail),
      address: optionalText(form.address),
    }
    const supplier = await createSupplier(payload)
    ElMessage.success('供应商草稿已创建')
    dialog.visible = false
    await router.push({ name: 'supplier-detail', params: { supplierId: supplier.id } })
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    dialog.saving = false
  }
}

function openDetail(supplierId: number): void {
  void router.push({ name: 'supplier-detail', params: { supplierId } })
}

function supplierTypeLabel(type: string): string {
  return supplierTypeOptions.find((option) => option.value === type)?.label || type
}

onMounted(loadSuppliers)
</script>

<style scoped>
.supplier-cell {
  display: flex;
  align-items: center;
  gap: 11px;
}

.supplier-cell > span {
  display: grid;
  width: 36px;
  height: 36px;
  flex: 0 0 36px;
  place-items: center;
  border-radius: 10px 3px 10px 3px;
  color: #286b58;
  background: #e5f0eb;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 16px;
  font-weight: 700;
}

.supplier-form {
  margin-top: 20px;
}

.two-column-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 18px;
}

.span-two {
  grid-column: span 2;
}

@media (max-width: 620px) {
  .two-column-form {
    grid-template-columns: 1fr;
  }

  .span-two {
    grid-column: auto;
  }
}
</style>
