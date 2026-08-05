<template>
  <div class="app-shell">
    <aside class="app-sidebar" :class="{ 'app-sidebar--collapsed': collapsed }">
      <RouterLink class="brand" to="/">
        <span class="brand__mark">药</span>
        <span v-if="!collapsed" class="brand__text">
          <strong>药链明鉴</strong>
          <small>PHARMA ERP DEMO</small>
        </span>
      </RouterLink>

      <nav class="primary-nav" aria-label="主导航">
        <template v-for="group in visibleNavigation" :key="group.label">
          <p v-if="!collapsed" class="primary-nav__label">{{ group.label }}</p>
          <RouterLink
            v-for="item in group.items"
            :key="item.to"
            :to="item.to"
            class="primary-nav__item"
            :title="collapsed ? item.label : undefined"
          >
            <ElIcon><component :is="item.icon" /></ElIcon>
            <span v-if="!collapsed">{{ item.label }}</span>
          </RouterLink>
        </template>
      </nav>

      <div v-if="!collapsed" class="sidebar-note">
        <span class="sidebar-note__pulse" />
        <div>
          <strong>验证型 Demo</strong>
          <small>仅使用演示数据，不可承载真实经营业务</small>
        </div>
      </div>

      <button class="sidebar-collapse" type="button" @click="collapsed = !collapsed">
        <ElIcon>
          <Fold v-if="!collapsed" />
          <Expand v-else />
        </ElIcon>
        <span v-if="!collapsed">收起导航</span>
      </button>
    </aside>

    <div class="app-workspace">
      <header class="topbar">
        <div>
          <p class="topbar__context">NATIONAL_DEFAULT · 第一阶段</p>
          <p class="topbar__title">{{ route.meta.title }}</p>
        </div>
        <div class="topbar__actions">
          <ElTooltip content="接口文档" placement="bottom">
            <a class="icon-button" :href="apiDocUrl" target="_blank" rel="noreferrer">
              <ElIcon><Document /></ElIcon>
            </a>
          </ElTooltip>
          <ElDropdown trigger="click" @command="handleCommand">
            <button class="user-chip" type="button">
              <span class="user-chip__avatar">
                {{ authState.user?.displayName?.slice(0, 1) || '用' }}
              </span>
              <span class="user-chip__identity">
                <strong>{{ authState.user?.displayName }}</strong>
                <small>{{ authState.user?.departmentName || authState.user?.username }}</small>
              </span>
              <ElIcon><ArrowDown /></ElIcon>
            </button>
            <template #dropdown>
              <ElDropdownMenu>
                <ElDropdownItem command="home">返回工作台</ElDropdownItem>
                <ElDropdownItem divided command="logout">退出登录</ElDropdownItem>
              </ElDropdownMenu>
            </template>
          </ElDropdown>
        </div>
      </header>

      <main class="app-content">
        <RouterView v-slot="{ Component }">
          <Transition name="page" mode="out-in">
            <component :is="Component" />
          </Transition>
        </RouterView>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  ArrowDown,
  Connection,
  DataAnalysis,
  Document,
  Expand,
  Fold,
  Key,
  OfficeBuilding,
  User,
  UserFilled,
} from '@element-plus/icons-vue'
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { PERMISSIONS, type PermissionCode } from '@/constants/permissions'
import { authState, hasPermission, logout } from '@/stores/auth'

interface NavigationItem {
  label: string
  to: string
  icon: typeof User
  permission?: PermissionCode
}

interface NavigationGroup {
  label: string
  items: NavigationItem[]
}

const route = useRoute()
const router = useRouter()
const collapsed = ref(false)
const apiDocUrl = `${(import.meta.env.VITE_API_BASE_URL || '/api').replace(/\/$/, '')}/doc.html`

const navigation: NavigationGroup[] = [
  {
    label: '总览',
    items: [{ label: '工作台', to: '/', icon: DataAnalysis }],
  },
  {
    label: '系统与权限',
    items: [
      {
        label: '用户管理',
        to: '/system/users',
        icon: User,
        permission: PERMISSIONS.SYS_USER_READ,
      },
      {
        label: '角色管理',
        to: '/system/roles',
        icon: UserFilled,
        permission: PERMISSIONS.SYS_ROLE_READ,
      },
      {
        label: '基础权限',
        to: '/system/permissions',
        icon: Key,
        permission: PERMISSIONS.SYS_PERMISSION_READ,
      },
    ],
  },
  {
    label: '准入与质量',
    items: [
      {
        label: '供应商审核',
        to: '/quality/suppliers',
        icon: OfficeBuilding,
        permission: PERMISSIONS.SUPPLIER_READ,
      },
    ],
  },
  {
    label: '追溯',
    items: [
      {
        label: '批号追溯',
        to: '/trace/batches',
        icon: Connection,
        permission: PERMISSIONS.TRACE_READ,
      },
    ],
  },
]

const visibleNavigation = computed(() =>
  navigation
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => hasPermission(item.permission)),
    }))
    .filter((group) => group.items.length > 0),
)

function handleCommand(command: string): void {
  if (command === 'logout') {
    logout()
    void router.replace({ name: 'login' })
    return
  }
  if (command === 'home') {
    void router.push({ name: 'dashboard' })
  }
}
</script>
