import { createRouter, createWebHistory } from 'vue-router'
import { PERMISSIONS } from '@/constants/permissions'
import { hasPermission, isAuthenticated } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { public: true, title: '登录' },
    },
    {
      path: '/',
      component: () => import('@/layouts/AppShell.vue'),
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { title: '工作台' },
        },
        {
          path: 'system/users',
          name: 'users',
          component: () => import('@/views/system/UserView.vue'),
          meta: { title: '用户管理', permission: PERMISSIONS.SYS_USER_READ },
        },
        {
          path: 'system/roles',
          name: 'roles',
          component: () => import('@/views/system/RoleView.vue'),
          meta: { title: '角色管理', permission: PERMISSIONS.SYS_ROLE_READ },
        },
        {
          path: 'system/permissions',
          name: 'permissions',
          component: () => import('@/views/system/PermissionView.vue'),
          meta: { title: '基础权限', permission: PERMISSIONS.SYS_PERMISSION_READ },
        },
        {
          path: 'quality/suppliers',
          name: 'suppliers',
          component: () => import('@/views/supplier/SupplierListView.vue'),
          meta: { title: '供应商审核', permission: PERMISSIONS.SUPPLIER_READ },
        },
        {
          path: 'quality/suppliers/:supplierId',
          name: 'supplier-detail',
          component: () => import('@/views/supplier/SupplierDetailView.vue'),
          meta: { title: '供应商详情', permission: PERMISSIONS.SUPPLIER_READ },
        },
        {
          path: 'trace/batches',
          name: 'trace',
          component: () => import('@/views/trace/TraceView.vue'),
          meta: { title: '药品追溯', permission: PERMISSIONS.TRACE_READ },
        },
        {
          path: 'forbidden',
          name: 'forbidden',
          component: () => import('@/views/ForbiddenView.vue'),
          meta: { title: '无权访问' },
        },
      ],
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/views/NotFoundView.vue'),
      meta: { public: true, title: '页面不存在' },
    },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach((to) => {
  document.title = to.meta.title
    ? `${String(to.meta.title)} · 药链明鉴`
    : '药链明鉴 · Pharma ERP Demo'

  if (to.meta.public) {
    if (to.name === 'login' && isAuthenticated.value) {
      return { name: 'dashboard' }
    }
    return true
  }

  if (!isAuthenticated.value) {
    return {
      name: 'login',
      query: { redirect: to.fullPath },
    }
  }

  if (to.meta.permission && !hasPermission(to.meta.permission)) {
    return { name: 'forbidden' }
  }

  return true
})

export default router
