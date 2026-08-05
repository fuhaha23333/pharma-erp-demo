<template>
  <div>
    <PageHeader
      eyebrow="SYSTEM · PERMISSIONS"
      title="基础权限"
      description="维护菜单、页面、按钮、数据和操作权限目录。权限编码创建后不可修改，父子关系不能形成环。"
    >
      <template #actions>
        <ElButton
          v-if="hasPermission(PERMISSIONS.SYS_PERMISSION_WRITE)"
          type="primary"
          :icon="Plus"
          @click="openCreate()"
        >
          新建根权限
        </ElButton>
      </template>
    </PageHeader>

    <div class="permission-summary">
      <div>
        <span>权限节点</span>
        <strong>{{ summary.total }}</strong>
      </div>
      <div>
        <span>业务模块</span>
        <strong>{{ summary.modules }}</strong>
      </div>
      <div>
        <span>停用节点</span>
        <strong>{{ summary.disabled }}</strong>
      </div>
      <div class="permission-summary__control">
        <span>显示停用权限</span>
        <ElSwitch v-model="includeDisabled" @change="loadPermissions" />
      </div>
    </div>

    <SectionCard flush>
      <template #header>
        <div>
          <h2>权限树</h2>
          <p>树形关系只用于组织和展示，接口授权使用精确权限编码</p>
        </div>
        <ElButton :icon="Refresh" :loading="loading" @click="loadPermissions">
          刷新
        </ElButton>
      </template>

      <ElTable
        v-loading="loading"
        :data="permissionTree"
        row-key="id"
        default-expand-all
        :tree-props="{ children: 'children' }"
      >
        <ElTableColumn label="权限名称" min-width="245">
          <template #default="{ row }: { row: PermissionNode }">
            <div class="permission-name">
              <span :class="`permission-name__type permission-name__type--${row.permissionType}`">
                {{ typeLabel(row.permissionType) }}
              </span>
              <div>
                <div class="table-primary">{{ row.permissionName }}</div>
                <div class="table-code">{{ row.permissionCode }}</div>
              </div>
            </div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="模块" width="115">
          <template #default="{ row }: { row: PermissionNode }">
            <ElTag effect="plain">{{ row.moduleCode }}</ElTag>
          </template>
        </ElTableColumn>
        <ElTableColumn label="资源" min-width="180">
          <template #default="{ row }: { row: PermissionNode }">
            <div>{{ row.resourceKey || row.routePath || '—' }}</div>
            <div v-if="row.routePath" class="table-secondary">{{ row.routePath }}</div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="接口约束" min-width="230">
          <template #default="{ row }: { row: PermissionNode }">
            <div v-if="row.apiPattern" class="api-pattern">
              <span>{{ row.httpMethod || 'ANY' }}</span>
              <code>{{ row.apiPattern }}</code>
            </div>
            <span v-else class="table-secondary">未绑定接口模式</span>
          </template>
        </ElTableColumn>
        <ElTableColumn label="排序" width="80" prop="sortOrder" />
        <ElTableColumn label="状态" width="105">
          <template #default="{ row }: { row: PermissionNode }">
            <StatusTag :value="row.status" />
          </template>
        </ElTableColumn>
        <ElTableColumn label="操作" width="155" fixed="right">
          <template #default="{ row }: { row: PermissionNode }">
            <div
              v-if="hasPermission(PERMISSIONS.SYS_PERMISSION_WRITE)"
              class="inline-actions"
            >
              <ElButton link type="primary" @click="openCreate(row)">新增下级</ElButton>
              <ElButton link type="primary" @click="openEdit(row)">编辑</ElButton>
            </div>
            <span v-else class="table-secondary">只读</span>
          </template>
        </ElTableColumn>
      </ElTable>
    </SectionCard>

    <ElDialog
      v-model="dialog.visible"
      :title="dialog.mode === 'create' ? '创建基础权限' : '编辑基础权限'"
      width="720px"
      destroy-on-close
      @closed="resetForm"
    >
      <ElForm ref="formRef" :model="form" :rules="rules" label-position="top">
        <div class="two-column-form">
          <ElFormItem label="上级权限">
            <ElTreeSelect
              v-model="form.parentId"
              :data="parentOptions"
              node-key="id"
              :props="{ label: 'permissionName', children: 'children', disabled: 'disabled' }"
              check-strictly
              clearable
              default-expand-all
              placeholder="留空表示根权限"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem
            v-if="dialog.mode === 'create'"
            label="权限编码"
            prop="permissionCode"
          >
            <ElInput
              v-model="form.permissionCode"
              placeholder="请输入大写字母、数字和下划线"
            />
          </ElFormItem>
          <ElFormItem label="权限名称" prop="permissionName">
            <ElInput v-model="form.permissionName" placeholder="请输入中文名称" />
          </ElFormItem>
          <ElFormItem label="权限类型" prop="permissionType">
            <ElSelect v-model="form.permissionType" style="width: 100%">
              <ElOption
                v-for="option in permissionTypeOptions"
                :key="option.value"
                :label="option.label"
                :value="option.value"
              />
            </ElSelect>
          </ElFormItem>
          <ElFormItem label="模块编码" prop="moduleCode">
            <ElInput v-model="form.moduleCode" placeholder="例如：SUPPLIER" />
          </ElFormItem>
          <ElFormItem label="资源标识">
            <ElInput v-model="form.resourceKey" placeholder="页面、按钮或业务动作标识" />
          </ElFormItem>
          <ElFormItem label="前端路由">
            <ElInput v-model="form.routePath" placeholder="/quality/suppliers" />
          </ElFormItem>
          <ElFormItem label="HTTP 方法">
            <ElSelect v-model="form.httpMethod" clearable style="width: 100%">
              <ElOption
                v-for="method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']"
                :key="method"
                :label="method"
                :value="method"
              />
            </ElSelect>
          </ElFormItem>
          <ElFormItem label="API 匹配模式">
            <ElInput v-model="form.apiPattern" placeholder="/quality/suppliers/**" />
          </ElFormItem>
          <ElFormItem label="排序值">
            <ElInputNumber
              v-model="form.sortOrder"
              :min="0"
              :precision="0"
              controls-position="right"
              style="width: 100%"
            />
          </ElFormItem>
          <ElFormItem v-if="dialog.mode === 'edit'" label="权限状态" prop="status">
            <ElRadioGroup v-model="form.status">
              <ElRadioButton value="ACTIVE">启用</ElRadioButton>
              <ElRadioButton value="DISABLED">停用</ElRadioButton>
            </ElRadioGroup>
          </ElFormItem>
        </div>
        <ElFormItem label="说明">
          <ElInput
            v-model="form.description"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
          />
        </ElFormItem>
        <ElFormItem
          v-if="dialog.mode === 'edit'"
          label="修改原因"
          prop="changeReason"
        >
          <ElInput
            v-model="form.changeReason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="权限目录变更会写入权限变更日志"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="dialog.visible = false">取消</ElButton>
          <ElButton type="primary" :loading="dialog.saving" @click="savePermission">
            保存
          </ElButton>
        </div>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
import { Plus, Refresh } from '@element-plus/icons-vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { computed, onMounted, reactive, ref } from 'vue'
import { getErrorMessage } from '@/api/http'
import {
  createPermission,
  getPermissionTree,
  updatePermission,
} from '@/api/system'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { permissionTypeOptions } from '@/constants/options'
import { PERMISSIONS } from '@/constants/permissions'
import { hasPermission } from '@/stores/auth'
import type {
  PermissionNode,
  PermissionType,
} from '@/types/system'
import { optionalText } from '@/utils/format'

interface PermissionFormModel {
  parentId?: number
  permissionCode: string
  permissionName: string
  permissionType: PermissionType
  moduleCode: string
  resourceKey: string
  routePath: string
  httpMethod: string
  apiPattern: string
  status: 'ACTIVE' | 'DISABLED'
  sortOrder: number
  description: string
  changeReason: string
}

interface ParentOption extends PermissionNode {
  disabled: boolean
  children: ParentOption[]
}

const loading = ref(false)
const includeDisabled = ref(false)
const permissionTree = ref<PermissionNode[]>([])
const formRef = ref<FormInstance>()
const dialog = reactive({
  visible: false,
  saving: false,
  mode: 'create' as 'create' | 'edit',
  permissionId: 0,
})
const form = reactive<PermissionFormModel>({
  parentId: undefined,
  permissionCode: '',
  permissionName: '',
  permissionType: 'ACTION',
  moduleCode: '',
  resourceKey: '',
  routePath: '',
  httpMethod: '',
  apiPattern: '',
  status: 'ACTIVE',
  sortOrder: 0,
  description: '',
  changeReason: '',
})
const rules: FormRules<PermissionFormModel> = {
  permissionCode: [
    {
      validator: (_rule, value, callback) => {
        if (dialog.mode === 'edit') return callback()
        if (!value) return callback(new Error('请输入权限编码'))
        if (!/^[A-Z][A-Z0-9_]*$/.test(value)) {
          return callback(new Error('权限编码必须为大写字母、数字和下划线'))
        }
        callback()
      },
      trigger: 'blur',
    },
  ],
  permissionName: [{ required: true, message: '请输入权限名称', trigger: 'blur' }],
  permissionType: [{ required: true, message: '请选择权限类型', trigger: 'change' }],
  moduleCode: [{ required: true, message: '请输入模块编码', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
  changeReason: [
    {
      validator: (_rule, value, callback) => {
        if (dialog.mode === 'create' || value?.trim()) return callback()
        callback(new Error('请填写修改原因'))
      },
      trigger: 'blur',
    },
  ],
}

function flatten(nodes: PermissionNode[]): PermissionNode[] {
  return nodes.flatMap((node) => [node, ...flatten(node.children || [])])
}

const summary = computed(() => {
  const items = flatten(permissionTree.value)
  return {
    total: items.length,
    modules: new Set(items.map((item) => item.moduleCode)).size,
    disabled: items.filter((item) => item.status !== 'ACTIVE').length,
  }
})

function mapParentOptions(nodes: PermissionNode[]): ParentOption[] {
  return nodes.map((node) => ({
    ...node,
    disabled: dialog.mode === 'edit' && node.id === dialog.permissionId,
    children: mapParentOptions(node.children || []),
  }))
}

const parentOptions = computed(() => mapParentOptions(permissionTree.value))

function typeLabel(type: PermissionType): string {
  return permissionTypeOptions.find((item) => item.value === type)?.label || type
}

async function loadPermissions(): Promise<void> {
  loading.value = true
  try {
    permissionTree.value = await getPermissionTree(includeDisabled.value)
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

function resetForm(): void {
  formRef.value?.resetFields()
  Object.assign(form, {
    parentId: undefined,
    permissionCode: '',
    permissionName: '',
    permissionType: 'ACTION',
    moduleCode: '',
    resourceKey: '',
    routePath: '',
    httpMethod: '',
    apiPattern: '',
    status: 'ACTIVE',
    sortOrder: 0,
    description: '',
    changeReason: '',
  })
}

function openCreate(parent?: PermissionNode): void {
  resetForm()
  dialog.mode = 'create'
  dialog.permissionId = 0
  form.parentId = parent?.id
  form.moduleCode = parent?.moduleCode || ''
  dialog.visible = true
}

function openEdit(permission: PermissionNode): void {
  dialog.mode = 'edit'
  dialog.permissionId = permission.id
  Object.assign(form, {
    parentId: permission.parentId,
    permissionCode: permission.permissionCode,
    permissionName: permission.permissionName,
    permissionType: permission.permissionType,
    moduleCode: permission.moduleCode,
    resourceKey: permission.resourceKey || '',
    routePath: permission.routePath || '',
    httpMethod: permission.httpMethod || '',
    apiPattern: permission.apiPattern || '',
    status: permission.status,
    sortOrder: permission.sortOrder || 0,
    description: permission.description || '',
    changeReason: '',
  })
  dialog.visible = true
}

async function savePermission(): Promise<void> {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  dialog.saving = true
  try {
    const common = {
      parentId: form.parentId,
      permissionName: form.permissionName.trim(),
      permissionType: form.permissionType,
      moduleCode: form.moduleCode.trim(),
      resourceKey: optionalText(form.resourceKey),
      routePath: optionalText(form.routePath),
      httpMethod: optionalText(form.httpMethod),
      apiPattern: optionalText(form.apiPattern),
      sortOrder: form.sortOrder,
      description: optionalText(form.description),
    }
    if (dialog.mode === 'create') {
      await createPermission({
        ...common,
        permissionCode: form.permissionCode.trim(),
      })
      ElMessage.success('权限创建成功')
    } else {
      await updatePermission(dialog.permissionId, {
        ...common,
        status: form.status,
        changeReason: form.changeReason.trim(),
      })
      ElMessage.success('权限已更新')
    }
    dialog.visible = false
    await loadPermissions()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    dialog.saving = false
  }
}

onMounted(loadPermissions)
</script>

<style scoped>
.permission-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(140px, 1fr)) minmax(210px, 1.4fr);
  gap: 12px;
  margin-bottom: 20px;
}

.permission-summary > div {
  display: flex;
  min-height: 88px;
  justify-content: center;
  flex-direction: column;
  padding: 16px 20px;
  border: 1px solid #dfe6e1;
  border-radius: 13px 5px 13px 5px;
  background: rgba(255, 254, 251, 0.9);
}

.permission-summary span {
  color: #7f8c87;
  font-size: 11px;
}

.permission-summary strong {
  margin-top: 6px;
  color: #20352e;
  font-size: 25px;
}

.permission-summary__control {
  align-items: center;
  justify-content: space-between !important;
  flex-direction: row !important;
}

.permission-name {
  display: flex;
  align-items: center;
  gap: 10px;
}

.permission-name__type {
  display: grid;
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  place-items: center;
  border-radius: 9px 3px 9px 3px;
  font-size: 9px;
  font-weight: 800;
}

.permission-name__type--MENU,
.permission-name__type--PAGE {
  color: #286c59;
  background: #e4f0eb;
}

.permission-name__type--BUTTON,
.permission-name__type--ACTION {
  color: #946228;
  background: #f6ead9;
}

.permission-name__type--DATA {
  color: #526998;
  background: #e8ebf3;
}

.api-pattern {
  display: flex;
  align-items: center;
  gap: 7px;
}

.api-pattern span {
  min-width: 42px;
  padding: 3px 5px;
  border-radius: 5px;
  color: #23624f;
  background: #e7f0ec;
  font-size: 9px;
  font-weight: 800;
  text-align: center;
}

.api-pattern code {
  overflow: hidden;
  color: #566761;
  font-size: 11px;
  text-overflow: ellipsis;
}

.two-column-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0 18px;
}

@media (max-width: 760px) {
  .permission-summary {
    grid-template-columns: repeat(2, 1fr);
  }

  .two-column-form {
    grid-template-columns: 1fr;
  }
}
</style>
