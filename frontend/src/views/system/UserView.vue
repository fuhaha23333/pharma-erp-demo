<template>
  <div>
    <PageHeader
      eyebrow="SYSTEM · USERS"
      title="用户管理"
      description="维护演示账号、所属部门、启停状态与角色。关键变更必须填写原因并由后端记录。"
    >
      <template #actions>
        <ElButton
          v-if="hasPermission(PERMISSIONS.SYS_USER_WRITE)"
          type="primary"
          :icon="Plus"
          @click="openCreate"
        >
          创建用户
        </ElButton>
      </template>
    </PageHeader>

    <SectionCard>
      <div class="filter-bar">
        <ElInput
          v-model="query.username"
          clearable
          placeholder="登录账号"
          @keyup.enter="search"
        />
        <ElInput
          v-model="query.displayName"
          clearable
          placeholder="用户姓名"
          @keyup.enter="search"
        />
        <ElSelect v-model="query.status" clearable placeholder="账号状态">
          <ElOption label="启用" value="ACTIVE" />
          <ElOption label="停用" value="DISABLED" />
          <ElOption label="锁定" value="LOCKED" />
        </ElSelect>
        <ElInput
          v-model.number="query.departmentId"
          clearable
          placeholder="部门 ID"
          @keyup.enter="search"
        />
        <div class="filter-bar__actions">
          <ElButton :icon="Refresh" @click="resetQuery">重置</ElButton>
          <ElButton type="primary" :icon="Search" @click="search">查询</ElButton>
        </div>
      </div>
    </SectionCard>

    <SectionCard flush>
      <template #header>
        <div>
          <h2>用户账号</h2>
          <p>共 {{ page.total }} 条，当前第 {{ page.pageNo }} 页</p>
        </div>
      </template>

      <ElTable v-loading="loading" :data="page.records" row-key="id">
        <ElTableColumn label="用户" min-width="190">
          <template #default="{ row }: { row: User }">
            <div class="user-cell">
              <span>{{ row.displayName.slice(0, 1) }}</span>
              <div>
                <div class="table-primary">{{ row.displayName }}</div>
                <div class="table-secondary">{{ row.username }}</div>
              </div>
            </div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="部门" min-width="150">
          <template #default="{ row }: { row: User }">
            <div>{{ row.departmentName || '—' }}</div>
            <div class="table-secondary">ID {{ row.departmentId }}</div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="角色" min-width="240">
          <template #default="{ row }: { row: User }">
            <div v-if="row.roles.length" class="role-tags">
              <ElTag
                v-for="role in row.roles"
                :key="role.id"
                size="small"
                :type="role.riskLevel === 'HIGH' ? 'danger' : 'info'"
                effect="plain"
              >
                {{ role.roleName }}
              </ElTag>
            </div>
            <span v-else class="table-secondary">暂无角色</span>
          </template>
        </ElTableColumn>
        <ElTableColumn label="联系方式" min-width="180">
          <template #default="{ row }: { row: User }">
            <div>{{ row.mobile || '—' }}</div>
            <div class="table-secondary">{{ row.email || '未填写邮箱' }}</div>
          </template>
        </ElTableColumn>
        <ElTableColumn label="状态" width="105">
          <template #default="{ row }: { row: User }">
            <StatusTag :value="row.status" />
          </template>
        </ElTableColumn>
        <ElTableColumn label="最后登录" min-width="170">
          <template #default="{ row }: { row: User }">
            {{ formatDateTime(row.lastLoginAt) }}
          </template>
        </ElTableColumn>
        <ElTableColumn label="操作" width="250" fixed="right">
          <template #default="{ row }: { row: User }">
            <div class="inline-actions">
              <ElButton
                v-if="hasPermission(PERMISSIONS.SYS_USER_WRITE)"
                link
                type="primary"
                @click="openEdit(row)"
              >
                编辑
              </ElButton>
              <ElButton
                v-if="
                  hasPermission(PERMISSIONS.SYS_USER_ROLE_ASSIGN) &&
                  hasPermission(PERMISSIONS.SYS_ROLE_READ)
                "
                link
                type="primary"
                @click="openRoleDialog(row)"
              >
                分配角色
              </ElButton>
              <ElButton
                v-if="hasPermission(PERMISSIONS.SYS_USER_STATUS)"
                link
                :type="row.status === 'ACTIVE' ? 'danger' : 'success'"
                :disabled="row.status === 'LOCKED' || row.id === authState.user?.id"
                @click="openStatusDialog(row)"
              >
                {{ row.status === 'ACTIVE' ? '停用' : '启用' }}
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
          @size-change="loadUsers"
          @current-change="loadUsers"
        />
      </div>
    </SectionCard>

    <ElDialog
      v-model="userDialog.visible"
      :title="userDialog.mode === 'create' ? '创建演示用户' : '编辑用户'"
      width="620px"
      destroy-on-close
      @closed="resetUserForm"
    >
      <ElForm
        ref="userFormRef"
        :model="userForm"
        :rules="userRules"
        label-position="top"
      >
        <div class="two-column-form">
          <ElFormItem v-if="userDialog.mode === 'create'" label="登录账号" prop="username">
            <ElInput v-model="userForm.username" placeholder="字母、数字、点、下划线或连字符" />
          </ElFormItem>
          <ElFormItem label="用户姓名" prop="displayName">
            <ElInput v-model="userForm.displayName" placeholder="请输入真实岗位姓名或演示姓名" />
          </ElFormItem>
          <ElFormItem
            v-if="userDialog.mode === 'create'"
            label="初始密码"
            prop="initialPassword"
          >
            <ElInput
              v-model="userForm.initialPassword"
              type="password"
              show-password
              autocomplete="new-password"
              placeholder="8–72 位，不会回显"
            />
          </ElFormItem>
          <ElFormItem label="部门 ID" prop="departmentId">
            <ElInputNumber
              v-model="userForm.departmentId"
              :min="1"
              :precision="0"
              controls-position="right"
              style="width: 100%"
            />
            <p class="form-tip">
              当前后端尚无部门目录接口，默认使用登录用户所属部门 {{ authState.user?.departmentId }}。
            </p>
          </ElFormItem>
          <ElFormItem label="手机号码" prop="mobile">
            <ElInput v-model="userForm.mobile" placeholder="选填" />
          </ElFormItem>
          <ElFormItem label="电子邮箱" prop="email">
            <ElInput v-model="userForm.email" placeholder="选填" />
          </ElFormItem>
        </div>
        <ElFormItem
          v-if="userDialog.mode === 'edit'"
          label="修改原因"
          prop="changeReason"
        >
          <ElInput
            v-model="userForm.changeReason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="说明本次修改的业务原因"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="userDialog.visible = false">取消</ElButton>
          <ElButton type="primary" :loading="userDialog.saving" @click="saveUser">
            保存
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="statusDialog.visible"
      :title="statusDialog.target?.status === 'ACTIVE' ? '停用用户' : '启用用户'"
      width="480px"
      destroy-on-close
    >
      <ElAlert
        :title="
          statusDialog.target?.status === 'ACTIVE'
            ? '停用后该账号将不能继续登录'
            : '启用后该账号将恢复登录能力'
        "
        type="warning"
        :closable="false"
        show-icon
      />
      <ElForm label-position="top" class="dialog-form">
        <ElFormItem label="变更原因" required>
          <ElInput
            v-model="statusDialog.reason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="原因会进入审计记录"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="statusDialog.visible = false">取消</ElButton>
          <ElButton
            :type="statusDialog.target?.status === 'ACTIVE' ? 'danger' : 'success'"
            :loading="statusDialog.saving"
            @click="saveStatus"
          >
            确认变更
          </ElButton>
        </div>
      </template>
    </ElDialog>

    <ElDialog
      v-model="roleDialog.visible"
      title="分配用户角色"
      width="620px"
      destroy-on-close
    >
      <ElAlert
        title="此操作会替换用户当前全部有效角色"
        description="停用角色和互斥角色组合会由后端阻断；高风险角色请谨慎分配。"
        type="warning"
        :closable="false"
        show-icon
      />
      <ElForm label-position="top" class="dialog-form">
        <ElFormItem label="目标角色">
          <ElSelect
            v-model="roleDialog.roleIds"
            v-loading="roleDialog.loading"
            multiple
            filterable
            collapse-tags
            collapse-tags-tooltip
            placeholder="可留空以撤销全部角色"
            style="width: 100%"
          >
            <ElOption
              v-for="role in availableRoles"
              :key="role.id"
              :label="`${role.roleName}（${role.roleCode}）`"
              :value="role.id"
              :disabled="role.status !== 'ACTIVE'"
            >
              <span>{{ role.roleName }}</span>
              <StatusTag
                class="role-option-status"
                :value="role.riskLevel"
                effect="plain"
              />
            </ElOption>
          </ElSelect>
        </ElFormItem>
        <ElFormItem label="分配或撤销原因" required>
          <ElInput
            v-model="roleDialog.reason"
            type="textarea"
            :rows="3"
            maxlength="500"
            show-word-limit
            placeholder="说明授权目的和依据"
          />
        </ElFormItem>
      </ElForm>
      <template #footer>
        <div class="dialog-footer">
          <ElButton @click="roleDialog.visible = false">取消</ElButton>
          <ElButton
            type="primary"
            :loading="roleDialog.saving"
            :disabled="roleDialog.loading || !roleDialog.loaded"
            @click="saveRoles"
          >
            保存角色
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
} from 'element-plus'
import { onMounted, reactive, ref } from 'vue'
import {
  assignUserRoles,
  changeUserStatus,
  createUser,
  getRoles,
  getUsers,
  updateUser,
} from '@/api/system'
import { getErrorMessage } from '@/api/http'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatusTag from '@/components/StatusTag.vue'
import { PERMISSIONS } from '@/constants/permissions'
import { authState, hasPermission } from '@/stores/auth'
import type { PageResult } from '@/types/api'
import type { Role, User, UserPageQuery } from '@/types/system'
import { formatDateTime } from '@/utils/datetime'
import { optionalText } from '@/utils/format'

interface UserFormModel {
  username: string
  displayName: string
  initialPassword: string
  departmentId?: number
  mobile: string
  email: string
  changeReason: string
}

const loading = ref(false)
const page = reactive<PageResult<User>>({
  records: [],
  total: 0,
  pageNo: 1,
  pageSize: 20,
})
const query = reactive<UserPageQuery>({
  pageNo: 1,
  pageSize: 20,
  username: '',
  displayName: '',
  status: '',
  departmentId: undefined,
})

const userFormRef = ref<FormInstance>()
const userDialog = reactive({
  visible: false,
  saving: false,
  mode: 'create' as 'create' | 'edit',
  userId: 0,
})
const userForm = reactive<UserFormModel>({
  username: '',
  displayName: '',
  initialPassword: '',
  departmentId: undefined,
  mobile: '',
  email: '',
  changeReason: '',
})
const userRules: FormRules<UserFormModel> = {
  username: [
    {
      validator: (_rule, value, callback) => {
        if (userDialog.mode === 'edit') return callback()
        if (!value) return callback(new Error('请输入登录账号'))
        if (!/^[A-Za-z0-9._-]+$/.test(value)) {
          return callback(new Error('账号只能包含字母、数字、点、下划线和连字符'))
        }
        callback()
      },
      trigger: 'blur',
    },
  ],
  displayName: [{ required: true, message: '请输入用户姓名', trigger: 'blur' }],
  initialPassword: [
    {
      validator: (_rule, value, callback) => {
        if (userDialog.mode === 'edit') return callback()
        if (!value || value.length < 8 || value.length > 72) {
          return callback(new Error('初始密码必须为 8–72 位'))
        }
        callback()
      },
      trigger: 'blur',
    },
  ],
  departmentId: [{ required: true, message: '请输入部门 ID', trigger: 'change' }],
  email: [{ type: 'email', message: '请输入有效的邮箱地址', trigger: 'blur' }],
  changeReason: [
    {
      validator: (_rule, value, callback) => {
        if (userDialog.mode === 'create' || value?.trim()) return callback()
        callback(new Error('请填写修改原因'))
      },
      trigger: 'blur',
    },
  ],
}

const statusDialog = reactive({
  visible: false,
  saving: false,
  target: null as User | null,
  reason: '',
})
const roleDialog = reactive({
  visible: false,
  loading: false,
  loaded: false,
  saving: false,
  target: null as User | null,
  roleIds: [] as number[],
  reason: '',
})
const availableRoles = ref<Role[]>([])

async function loadUsers(): Promise<void> {
  loading.value = true
  try {
    const result = await getUsers(query)
    Object.assign(page, result)
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    loading.value = false
  }
}

function search(): void {
  query.pageNo = 1
  void loadUsers()
}

function resetQuery(): void {
  Object.assign(query, {
    pageNo: 1,
    pageSize: 20,
    username: '',
    displayName: '',
    status: '',
    departmentId: undefined,
  })
  void loadUsers()
}

function resetUserForm(): void {
  userFormRef.value?.resetFields()
  Object.assign(userForm, {
    username: '',
    displayName: '',
    initialPassword: '',
    departmentId: authState.user?.departmentId,
    mobile: '',
    email: '',
    changeReason: '',
  })
}

function openCreate(): void {
  resetUserForm()
  userDialog.mode = 'create'
  userDialog.userId = 0
  userDialog.visible = true
}

function openEdit(user: User): void {
  userDialog.mode = 'edit'
  userDialog.userId = user.id
  Object.assign(userForm, {
    username: user.username,
    displayName: user.displayName,
    initialPassword: '',
    departmentId: user.departmentId,
    mobile: user.mobile || '',
    email: user.email || '',
    changeReason: '',
  })
  userDialog.visible = true
}

async function saveUser(): Promise<void> {
  const valid = await userFormRef.value?.validate().catch(() => false)
  if (!valid || !userForm.departmentId) {
    return
  }
  userDialog.saving = true
  try {
    if (userDialog.mode === 'create') {
      await createUser({
        username: userForm.username.trim(),
        displayName: userForm.displayName.trim(),
        initialPassword: userForm.initialPassword,
        departmentId: userForm.departmentId,
        mobile: optionalText(userForm.mobile),
        email: optionalText(userForm.email),
      })
      ElMessage.success('用户创建成功')
    } else {
      await updateUser(userDialog.userId, {
        displayName: userForm.displayName.trim(),
        departmentId: userForm.departmentId,
        mobile: optionalText(userForm.mobile),
        email: optionalText(userForm.email),
        changeReason: userForm.changeReason.trim(),
      })
      ElMessage.success('用户信息已更新')
    }
    userDialog.visible = false
    await loadUsers()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    userDialog.saving = false
  }
}

function openStatusDialog(user: User): void {
  statusDialog.target = user
  statusDialog.reason = ''
  statusDialog.visible = true
}

async function saveStatus(): Promise<void> {
  if (!statusDialog.target || !statusDialog.reason.trim()) {
    ElMessage.warning('请填写状态变更原因')
    return
  }
  statusDialog.saving = true
  try {
    const nextStatus = statusDialog.target.status === 'ACTIVE' ? 'DISABLED' : 'ACTIVE'
    await changeUserStatus(statusDialog.target.id, nextStatus, statusDialog.reason.trim())
    ElMessage.success(nextStatus === 'ACTIVE' ? '用户已启用' : '用户已停用')
    statusDialog.visible = false
    await loadUsers()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    statusDialog.saving = false
  }
}

async function openRoleDialog(user: User): Promise<void> {
  roleDialog.target = user
  roleDialog.roleIds = user.roles.map((role) => role.id)
  roleDialog.reason = ''
  roleDialog.loaded = false
  roleDialog.loading = true
  availableRoles.value = []
  roleDialog.visible = true
  try {
    const result = await getRoles({ pageNo: 1, pageSize: 100 })
    availableRoles.value = result.records
    roleDialog.loaded = true
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    roleDialog.loading = false
  }
}

async function saveRoles(): Promise<void> {
  if (!roleDialog.loaded) {
    ElMessage.warning('角色目录尚未成功加载，不能提交变更')
    return
  }
  if (!roleDialog.target || !roleDialog.reason.trim()) {
    ElMessage.warning('请填写角色分配或撤销原因')
    return
  }
  roleDialog.saving = true
  try {
    await assignUserRoles(roleDialog.target.id, roleDialog.roleIds, roleDialog.reason.trim())
    ElMessage.success('用户角色已更新')
    roleDialog.visible = false
    await loadUsers()
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  } finally {
    roleDialog.saving = false
  }
}

onMounted(loadUsers)
</script>

<style scoped>
.user-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.user-cell > span {
  display: grid;
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  place-items: center;
  border-radius: 9px 3px 9px 3px;
  color: #276a57;
  background: #e6f0eb;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 15px;
}

.role-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
}

.two-column-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  column-gap: 18px;
}

.dialog-form {
  margin-top: 20px;
}

.role-option-status {
  float: right;
  margin-top: 3px;
}

@media (max-width: 620px) {
  .two-column-form {
    grid-template-columns: 1fr;
  }
}
</style>
