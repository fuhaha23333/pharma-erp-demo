<template>
  <div>
    <PageHeader
      eyebrow="SYSTEM · ROLES"
      title="角色管理"
      description="角色承载岗位权限。高风险角色、停用状态和权限变更都会由后端校验并留痕。"
    >
      <template #actions>
        <ElButton
          v-if="hasPermission(PERMISSIONS.SYS_ROLE_WRITE)"
          type="primary"
          :icon="Plus"
          @click="openCreate"
        >
          创建角色
        </ElButton>
      </template>
    </PageHeader>

    <SectionCard>
      <div class="filter-bar">
        <ElInput
          v-model="query.keyword"
          clearable
          placeholder="角色编码或名称"
          @keyup.enter="search"
        />
        <ElSelect v-model="query.status" clearable placeholder="角色状态">
          <ElOption label="启用" value="ACTIVE" />
          <ElOption label="停用" value="DISABLED" />
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
          <h2>角色目录</h2>
          <p>共 {{ page.total }} 个角色；内置角色可维护名称和权限，但编码不可变</p>
        </div>
      </template>

      <ElTable v-loading="loading" :data="page.records" row-key="id">
        <ElTableColumn label="角色" min-width="220">
          <template #default="{ row }: { row: Role }">
            <div class="table-primary">{{ row.roleName }}</div>
            <div class="table-code">{{ row.roleCode }}</div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="风险等级" width="115">
          <template #default="{ row }: { row: Role }">
            <StatusTag :value="row.riskLevel" />
          </template>
        </ElTableColumn>
        <ElTableColumn label="来源" width="105">
          <template #default="{ row }: { row: Role }">
            <ElTag :type="row.isBuiltin ? 'warning' : 'info'" effect="plain">
              {{ row.isBuiltin ? '系统内置' : '自定义' }}
            </ElTag>
          </template>
        </ElTableColumn>
        <ElTableColumn label="权限数" width="100">
          <template #default="{ row }: { row: Role }">
            {{ row.permissions?.length || 0 }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="说明" min-width="260" show-overflow-tooltip>
          <template #default="{ row }: { row: Role }">
            {{ row.description || '—' }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="状态" width="105">
          <template #default="{ row }: { row: Role }">
            <StatusTag :value="row.status" />
          </template>
        </ElTableColumn>
        <ElTableColumn label="更新时间" min-width="170">
          <template #default="{ row }: { row: Role }">
            {{ formatDateTime(row.updatedAt) }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="操作" width="190" fixed="right">
          <template #default="{ row }: { row: Role }">
            <div class="inline-actions">
              <ElButton
                v-if="hasPermission(PERMISSIONS.SYS_ROLE_WRITE)"
                link
                type="primary"
                @click="openEdit(row)"
              >
                编辑
              </ElButton>
              <ElButton
                v-if="
                  hasPermission(PERMISSIONS.SYS_ROLE_PERMISSION_ASSIGN) &&
                  hasPermission(PERMISSIONS.SYS_PERMISSION_READ)
                "
                link
                type="primary"
                :disabled="row.status !== 'ACTIVE'"
                @click="openPermissionDialog(row)"
              >
                配置权限
              </ElButton>
            </div>
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
          @size-change="loadRoles"
          @current-change="loadRoles"
        />
      </div>
    </SectionCard>

    <ElDialog
      v-model="roleDialog.visible"
      :title="roleDialog.mode === 'create' ? '创建角色' : '编辑角色'"
      width="560px"
      destroy-on-close
      @closed="resetRoleForm"
    >
      <ElForm
        ref="roleFormRef"
        :model="roleForm"
        :rules="roleRules"
        label-position="top"
      >
        <ElFormItem v-if="roleDialog.mode === 'create'" label="角色编码" prop="roleCode">
          <ElInput v-model="roleForm.roleCode" placeholder="例如：QUALITY_ASSISTANT" />
          <p class="form-tip">必须以大写字母开头，只能包含大写字母、数字和下划线。</p>
        </ElFormItem>
        <div class="two-column-form">
          <ElFormItem label="角色名称" prop="roleName">
            <ElInput v-model="roleForm.roleName" placeholder="请输入角色名称" />
          </ElFormItem>
          <ElFormItem label="风险等级" prop="riskLevel">
            <ElSelect v-model="roleForm.riskLevel" style="width: 100%">
              <ElOption label="普通" value="NORMAL" />
              <ElOption label="高风险" value="HIGH" />
            </ElSelect>
          </ElFormItem>
        </div>
        <ElFormItem v-if="roleDialog.mode === 'edit'" label="角色状态" prop="status">
          <ElRadioGroup v-model="roleForm.status">
            <ElRadioButton value="ACTIVE">启用</ElRadioButton>
            <ElRadioButton value="DISABLED">停用</ElRadioButton>
          </ElRadioGroup>
        </ElFormItem>
        <ElFormItem label="角色说明" prop="description">
          <ElInput
            v-model="roleForm.description"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
          />
        </ElFormItem>
        <ElFormItem
          v-if="roleDialog.mode === 'edit'"
          label="修改原因"
          prop="changeReason"
        >
          <ElInput
            v-model="roleForm.changeReason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="说明名称、风险或状态变更原因"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="roleDialog.visible = false">取消</ElButton>
          <ElButton type="primary" :loading="roleDialog.saving" @click="saveRole">
            保存
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="permissionDialog.visible"
      title="配置角色权限"
      width="720px"
      destroy-on-close
    >
      <div class="permission-dialog-head">
        <div>
          <strong>{{ permissionDialog.target?.roleName }}</strong>
          <span>{{ permissionDialog.target?.roleCode }}</span>
        </div>
        <StatusTag :value="permissionDialog.target?.riskLevel" />
      </div>
      <ElAlert
        title="权限采用精确勾选"
        description="父节点与子节点不会自动联动，确保提交的权限 ID 与后端配置完全一致；停用权限不可新增分配。"
        type="info"
        :closable="false"
        show-icon
      />
      <div v-loading="permissionDialog.loading" class="permission-tree-wrap">
        <ElTree
          ref="permissionTreeRef"
          :data="permissionTree"
          :props="treeProps"
          node-key="id"
          show-checkbox
          check-strictly
          default-expand-all
          :expand-on-click-node="false"
        >
          <template #default="{ data }: { data: PermissionTreeNode }">
            <div class="permission-node">
              <span>{{ data.permissionName }}</span>
              <code>{{ data.permissionCode }}</code>
              <StatusTag v-if="data.status !== 'ACTIVE'" :value="data.status" />
            </div>
          </template>
        </ElTree>
      </div>
      <ElForm label-position="top">
        <ElFormItem label="配置原因" required>
          <ElInput
            v-model="permissionDialog.reason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="说明本次授权调整的业务原因"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="permissionDialog.visible = false">取消</ElButton>
          <ElButton
            type="primary"
            :loading="permissionDialog.saving"
            :disabled="permissionDialog.loading || !permissionDialog.loaded"
            @click="savePermissions"
          >
            保存权限
          </ElButton>
        </div>
      </template>
    </ElDialog>
  </div>
</template>

<script setup lang="ts">
import { Plus, Refresh, Search } from '@element-plus/icons-vue'
import {
  ElMessage,
  type FormInstance,
  type FormRules,
  type TreeInstance,
} from 'element-plus'
import { nextTick, onMounted, reactive, ref } from 'vue'
import { getErrorMessage } from '@/api/http'
import {
  assignRolePermissions,
  createRole,
  getPermissionTree,
  getRole,
  getRoles,
  updateRole,
} from '@/api/system'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { PERMISSIONS } from '@/constants/permissions'
import { hasPermission } from '@/stores/auth'
import type { PageResult } from '@/types/api'
import type { PermissionNode, Role, RolePageQuery } from '@/types/system'
import { formatDateTime } from '@/utils/datetime'
import { optionalText } from '@/utils/format'

interface RoleFormModel {
  roleCode: string
  roleName: string
  riskLevel: 'NORMAL' | 'HIGH'
  status: 'ACTIVE' | 'DISABLED'
  description: string
  changeReason: string
}

interface PermissionTreeNode extends PermissionNode {
  disabled: boolean
  children: PermissionTreeNode[]
}

const loading = ref(false)
const page = reactive<PageResult<Role>>({
  records: [],
  total: 0,
  pageNo: 1,
  pageSize: 20,
})
const query = reactive<RolePageQuery>({
  pageNo: 1,
  pageSize: 20,
  keyword: '',
  status: '',
})

const roleFormRef = ref<FormInstance>()
const roleDialog = reactive({
  visible: false,
  saving: false,
  mode: 'create' as 'create' | 'edit',
  roleId: 0,
})
const roleForm = reactive<RoleFormModel>({
  roleCode: '',
  roleName: '',
  riskLevel: 'NORMAL',
  status: 'ACTIVE',
  description: '',
  changeReason: '',
})
const roleRules: FormRules<RoleFormModel> = {
  roleCode: [
    {
      validator: (_rule, value, callback) => {
        if (roleDialog.mode === 'edit') return callback()
        if (!value) return callback(new Error('请输入角色编码'))
        if (!/^[A-Z][A-Z0-9_]*$/.test(value)) {
          return callback(new Error('角色编码格式不正确'))
        }
        callback()
      },
      trigger: 'blur',
    },
  ],
  roleName: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
  riskLevel: [{ required: true, message: '请选择风险等级', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
  changeReason: [
    {
      validator: (_rule, value, callback) => {
        if (roleDialog.mode === 'create' || value?.trim()) return callback()
        callback(new Error('请填写修改原因'))
      },
      trigger: 'blur',
    },
  ],
}

const permissionTreeRef = ref<TreeInstance>()
const permissionTree = ref<PermissionTreeNode[]>([])
const treeProps = {
  label: 'permissionName',
  children: 'children',
  disabled: 'disabled',
}
const permissionDialog = reactive({
  visible: false,
  loading: false,
  loaded: false,
  saving: false,
  target: null as Role | null,
  reason: '',
})

function mapPermissionTree(nodes: PermissionNode[]): PermissionTreeNode[] {
  return nodes.map((node) => ({
    ...node,
    disabled: node.status !== 'ACTIVE',
    children: mapPermissionTree(node.children || []),
  }))
}

async function loadRoles(): Promise<void> {
  loading.value = true
  try {
    Object.assign(page, await getRoles(query))
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

function search(): void {
  query.pageNo = 1
  void loadRoles()
}

function resetQuery(): void {
  Object.assign(query, { pageNo: 1, pageSize: 20, keyword: '', status: '' })
  void loadRoles()
}

function resetRoleForm(): void {
  roleFormRef.value?.resetFields()
  Object.assign(roleForm, {
    roleCode: '',
    roleName: '',
    riskLevel: 'NORMAL',
    status: 'ACTIVE',
    description: '',
    changeReason: '',
  })
}

function openCreate(): void {
  resetRoleForm()
  roleDialog.mode = 'create'
  roleDialog.roleId = 0
  roleDialog.visible = true
}

function openEdit(role: Role): void {
  roleDialog.mode = 'edit'
  roleDialog.roleId = role.id
  Object.assign(roleForm, {
    roleCode: role.roleCode,
    roleName: role.roleName,
    riskLevel: role.riskLevel,
    status: role.status,
    description: role.description || '',
    changeReason: '',
  })
  roleDialog.visible = true
}

async function saveRole(): Promise<void> {
  const valid = await roleFormRef.value?.validate().catch(() => false)
  if (!valid) return
  roleDialog.saving = true
  try {
    if (roleDialog.mode === 'create') {
      await createRole({
        roleCode: roleForm.roleCode.trim(),
        roleName: roleForm.roleName.trim(),
        riskLevel: roleForm.riskLevel,
        description: optionalText(roleForm.description),
      })
      ElMessage.success('角色创建成功')
    } else {
      await updateRole(roleDialog.roleId, {
        roleName: roleForm.roleName.trim(),
        riskLevel: roleForm.riskLevel,
        status: roleForm.status,
        description: optionalText(roleForm.description),
        changeReason: roleForm.changeReason.trim(),
      })
      ElMessage.success('角色已更新')
    }
    roleDialog.visible = false
    await loadRoles()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    roleDialog.saving = false
  }
}

async function openPermissionDialog(role: Role): Promise<void> {
  permissionDialog.target = role
  permissionDialog.reason = ''
  permissionDialog.loaded = false
  permissionTree.value = []
  permissionDialog.visible = true
  permissionDialog.loading = true
  try {
    const [tree, detail] = await Promise.all([
      getPermissionTree(true),
      getRole(role.id),
    ])
    permissionTree.value = mapPermissionTree(tree)
    await nextTick()
    permissionTreeRef.value?.setCheckedKeys(
      detail.permissions.filter((permission) => permission.status === 'ACTIVE').map((item) => item.id),
    )
    permissionDialog.loaded = true
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    permissionDialog.loading = false
  }
}

async function savePermissions(): Promise<void> {
  if (!permissionDialog.loaded) {
    ElMessage.warning('权限树尚未成功加载，不能提交变更')
    return
  }
  if (!permissionDialog.target || !permissionDialog.reason.trim()) {
    ElMessage.warning('请填写权限配置原因')
    return
  }
  const checkedKeys = permissionTreeRef.value?.getCheckedKeys(false) ?? []
  const permissionIds = checkedKeys.map(Number).filter(Number.isFinite)
  permissionDialog.saving = true
  try {
    await assignRolePermissions(
      permissionDialog.target.id,
      permissionIds,
      permissionDialog.reason.trim(),
    )
    ElMessage.success('角色权限已更新')
    permissionDialog.visible = false
    await loadRoles()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    permissionDialog.saving = false
  }
}

onMounted(loadRoles)
</script>

<style scoped>
.two-column-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}

.permission-dialog-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  padding: 13px 15px;
  border: 1px solid #e5eae6;
  border-radius: 10px 4px 10px 4px;
  background: #fafaf7;
}

.permission-dialog-head strong,
.permission-dialog-head span {
  display: block;
}

.permission-dialog-head strong {
  color: #20332d;
  font-size: 14px;
}

.permission-dialog-head span {
  margin-top: 4px;
  color: #7f8d88;
  font-family: Consolas, monospace;
  font-size: 11px;
}

.permission-tree-wrap {
  max-height: 390px;
  min-height: 140px;
  overflow: auto;
  margin: 18px 0;
  padding: 12px;
  border: 1px solid #e5eae6;
  border-radius: 10px;
}

.permission-node {
  display: flex;
  min-width: 0;
  flex: 1;
  align-items: center;
  gap: 10px;
}

.permission-node > span {
  color: #30423c;
  font-size: 12px;
}

.permission-node code {
  overflow: hidden;
  color: #7e8b87;
  font-size: 10px;
  text-overflow: ellipsis;
}

@media (max-width: 620px) {
  .two-column-form {
    grid-template-columns: 1fr;
  }
}
</style>
