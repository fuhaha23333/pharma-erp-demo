<template>
  <div>
    <PageHeader
      eyebrow="PHASE 01 · OVERVIEW"
      :title="`${greeting}，${authState.user?.displayName || '用户'}`"
      description="这里展示的是当前账号真实可访问的第一阶段能力，不使用虚构统计数据。"
    />

    <section class="hero-panel">
      <div class="hero-panel__content">
        <p>当前执行 Profile</p>
        <h2>PHASE1_CURRENT_API</h2>
        <span>
          当前浏览器入口覆盖身份、RBAC、供应商资质审核与批号级只读追溯。完整采购到销售闭环仍在后续 M1 范围。
        </span>
      </div>
      <div class="hero-panel__stats">
        <div>
          <strong>{{ visibleModules.length }}</strong>
          <span>可访问模块</span>
        </div>
        <div>
          <strong>{{ authState.user?.roleCodes.length || 0 }}</strong>
          <span>有效角色</span>
        </div>
        <div>
          <strong>{{ authState.user?.permissionCodes.length || 0 }}</strong>
          <span>权限编码</span>
        </div>
      </div>
    </section>

    <div class="dashboard-grid">
      <SectionCard title="我的业务入口" description="入口由当前账号的后端权限编码生成">
        <div v-if="visibleModules.length" class="module-grid">
          <RouterLink
            v-for="module in visibleModules"
            :key="module.to"
            :to="module.to"
            class="module-card"
          >
            <span class="module-card__icon">
              <ElIcon><component :is="module.icon" /></ElIcon>
            </span>
            <div>
              <strong>{{ module.title }}</strong>
              <p>{{ module.description }}</p>
            </div>
            <ElIcon class="module-card__arrow"><ArrowRight /></ElIcon>
          </RouterLink>
        </div>
        <ElEmpty v-else description="当前账号没有第一阶段业务入口" />
      </SectionCard>

      <SectionCard title="当前身份" description="来自 /system/auth/me">
        <div class="identity-card">
          <div class="identity-card__avatar">
            {{ authState.user?.displayName?.slice(0, 1) }}
          </div>
          <div>
            <h3>{{ authState.user?.displayName }}</h3>
            <p>{{ authState.user?.username }} · {{ authState.user?.departmentName }}</p>
          </div>
        </div>
        <div class="role-list">
          <ElTag
            v-for="role in authState.user?.roleCodes"
            :key="role"
            effect="plain"
            round
          >
            {{ role }}
          </ElTag>
        </div>
        <ElAlert
          class="identity-alert"
          title="前端可见性不是授权凭证"
          description="即使绕过页面直接发起请求，后端仍会执行方法级权限校验与业务状态守卫。"
          type="info"
          :closable="false"
          show-icon
        />
      </SectionCard>
    </div>

    <SectionCard title="第一阶段业务链" description="只展示当前已经存在接口的节点">
      <div class="phase-flow">
        <div v-for="(step, index) in phaseSteps" :key="step.title" class="phase-step">
          <span class="phase-step__index">{{ String(index + 1).padStart(2, '0') }}</span>
          <div>
            <strong>{{ step.title }}</strong>
            <p>{{ step.description }}</p>
          </div>
          <ElIcon v-if="index < phaseSteps.length - 1"><Right /></ElIcon>
        </div>
      </div>
    </SectionCard>
  </div>
</template>

<script setup lang="ts">
import {
  ArrowRight,
  Connection,
  Key,
  OfficeBuilding,
  Right,
  User,
  UserFilled,
} from '@element-plus/icons-vue'
import { computed } from 'vue'
import PageHeader from '@/components/PageHeader.vue'
import SectionCard from '@/components/SectionCard.vue'
import { PERMISSIONS } from '@/constants/permissions'
import { authState, hasPermission } from '@/stores/auth'

const modules = [
  {
    title: '用户管理',
    description: '账号、部门、状态与角色',
    to: '/system/users',
    icon: User,
    permission: PERMISSIONS.SYS_USER_READ,
  },
  {
    title: '角色管理',
    description: '风险等级与权限配置',
    to: '/system/roles',
    icon: UserFilled,
    permission: PERMISSIONS.SYS_ROLE_READ,
  },
  {
    title: '基础权限',
    description: '权限树与接口资源',
    to: '/system/permissions',
    icon: Key,
    permission: PERMISSIONS.SYS_PERMISSION_READ,
  },
  {
    title: '供应商审核',
    description: '资质、附件、提交与结论',
    to: '/quality/suppliers',
    icon: OfficeBuilding,
    permission: PERMISSIONS.SUPPLIER_READ,
  },
  {
    title: '批号追溯',
    description: '库存分布与生命周期事件',
    to: '/trace/batches',
    icon: Connection,
    permission: PERMISSIONS.TRACE_READ,
  },
]

const visibleModules = computed(() =>
  modules.filter((module) => hasPermission(module.permission)),
)

const greeting = computed(() => {
  const hour = new Date().getHours()
  if (hour < 6) return '夜深了'
  if (hour < 11) return '早上好'
  if (hour < 14) return '中午好'
  if (hour < 18) return '下午好'
  return '晚上好'
})

const phaseSteps = [
  { title: '身份验证', description: 'HTTP Basic 获取当前用户' },
  { title: '权限执行', description: '角色、权限与职责互斥' },
  { title: '供应商准入', description: '资料、资质、附件与审核' },
  { title: '批号追溯', description: '只读还原库存与事件链' },
]
</script>

<style scoped>
.hero-panel {
  position: relative;
  display: flex;
  min-height: 190px;
  align-items: flex-end;
  justify-content: space-between;
  gap: 30px;
  overflow: hidden;
  margin-bottom: 22px;
  padding: clamp(26px, 4vw, 42px);
  border-radius: 22px 7px 22px 7px;
  color: #edf5f1;
  background:
    radial-gradient(circle at 80% 20%, rgba(86, 161, 132, 0.28), transparent 24%),
    linear-gradient(145deg, #17483b, #102f29);
  box-shadow: 0 20px 50px rgba(17, 54, 45, 0.16);
}

.hero-panel::after {
  position: absolute;
  right: -80px;
  top: -120px;
  width: 310px;
  height: 310px;
  border: 1px solid rgba(255, 255, 255, 0.09);
  border-radius: 50%;
  content: "";
}

.hero-panel__content {
  position: relative;
  z-index: 1;
  max-width: 690px;
}

.hero-panel__content > p {
  margin-bottom: 8px;
  color: #dcb87d;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.18em;
}

.hero-panel h2 {
  margin-bottom: 13px;
  font-size: clamp(25px, 3vw, 38px);
  letter-spacing: 0.04em;
}

.hero-panel__content > span {
  color: #a9c0b8;
  font-size: 13px;
  line-height: 1.8;
}

.hero-panel__stats {
  position: relative;
  z-index: 1;
  display: flex;
  gap: 8px;
}

.hero-panel__stats > div {
  min-width: 94px;
  padding: 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 11px 4px 11px 4px;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(8px);
}

.hero-panel__stats strong,
.hero-panel__stats span {
  display: block;
}

.hero-panel__stats strong {
  font-size: 27px;
}

.hero-panel__stats span {
  margin-top: 4px;
  color: #8eaaa1;
  font-size: 10px;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.6fr) minmax(300px, 0.8fr);
  gap: 20px;
}

.module-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.module-card {
  display: grid;
  min-height: 106px;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 13px;
  padding: 16px;
  border: 1px solid #e4e9e5;
  border-radius: 12px 4px 12px 4px;
  background: #fbfbf8;
  transition:
    border-color 150ms ease,
    transform 150ms ease,
    box-shadow 150ms ease;
}

.module-card:hover {
  border-color: #bdd2c9;
  box-shadow: 0 12px 25px rgba(28, 71, 59, 0.08);
  transform: translateY(-2px);
}

.module-card__icon {
  display: grid;
  width: 42px;
  height: 42px;
  place-items: center;
  border-radius: 11px 4px 11px 4px;
  color: #236853;
  background: #e6f0eb;
  font-size: 19px;
}

.module-card strong {
  color: #20322d;
  font-size: 14px;
}

.module-card p {
  margin: 5px 0 0;
  color: #83908c;
  font-size: 11px;
}

.module-card__arrow {
  color: #a4afab;
}

.identity-card {
  display: flex;
  align-items: center;
  gap: 13px;
}

.identity-card__avatar {
  display: grid;
  width: 52px;
  height: 52px;
  place-items: center;
  border-radius: 15px 5px 15px 5px;
  color: #fff;
  background: linear-gradient(145deg, #317e68, #164d3d);
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 23px;
}

.identity-card h3 {
  margin: 0 0 5px;
  font-size: 15px;
}

.identity-card p {
  margin: 0;
  color: #83908c;
  font-size: 11px;
}

.role-list {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  margin: 18px 0;
}

.identity-alert {
  margin-top: 16px;
}

.phase-flow {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
}

.phase-step {
  position: relative;
  display: grid;
  min-height: 90px;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 12px 18px;
}

.phase-step:not(:last-child) {
  border-right: 1px solid #e6eae6;
}

.phase-step__index {
  color: #d6b171;
  font-family: Georgia, serif;
  font-size: 20px;
  font-style: italic;
}

.phase-step strong {
  color: #263a34;
  font-size: 13px;
}

.phase-step p {
  margin: 5px 0 0;
  color: #86928e;
  font-size: 10px;
  line-height: 1.5;
}

.phase-step > .el-icon {
  color: #b8c1bd;
}

@media (max-width: 1050px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }

  .phase-flow {
    grid-template-columns: repeat(2, 1fr);
  }

  .phase-step:nth-child(2) {
    border-right: 0;
  }
}

@media (max-width: 700px) {
  .hero-panel {
    align-items: stretch;
    flex-direction: column;
  }

  .hero-panel__stats {
    width: 100%;
  }

  .hero-panel__stats > div {
    min-width: 0;
    flex: 1;
  }

  .module-grid,
  .phase-flow {
    grid-template-columns: 1fr;
  }

  .phase-step {
    border-right: 0 !important;
    border-bottom: 1px solid #e6eae6;
  }
}
</style>
