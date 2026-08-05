<template>
  <ElTag :type="meta.type" :effect="effect" round>
    <span class="status-dot" :class="`status-dot--${meta.tone}`" />
    {{ meta.label }}
  </ElTag>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { TagProps } from 'element-plus'

const props = withDefaults(
  defineProps<{
    value?: string
    effect?: TagProps['effect']
  }>(),
  {
    value: '',
    effect: 'light',
  },
)

const labels: Record<string, { label: string; type: TagProps['type']; tone: string }> = {
  ACTIVE: { label: '启用', type: 'success', tone: 'green' },
  APPROVED: { label: '已通过', type: 'success', tone: 'green' },
  VALID: { label: '有效', type: 'success', tone: 'green' },
  QUALIFIED: { label: '合格', type: 'success', tone: 'green' },
  DRAFT: { label: '待提交', type: 'info', tone: 'slate' },
  PENDING: { label: '待审核', type: 'warning', tone: 'amber' },
  UNDER_REVIEW: { label: '审核中', type: 'warning', tone: 'amber' },
  REJECTED: { label: '已驳回', type: 'danger', tone: 'red' },
  DISABLED: { label: '已停用', type: 'info', tone: 'slate' },
  LOCKED: { label: '已锁定', type: 'danger', tone: 'red' },
  EXPIRED: { label: '已失效', type: 'danger', tone: 'red' },
  REVOKED: { label: '已撤销', type: 'danger', tone: 'red' },
  INVALIDATED: { label: '已作废', type: 'info', tone: 'slate' },
  HIGH: { label: '高风险', type: 'danger', tone: 'red' },
  NORMAL: { label: '普通', type: 'info', tone: 'blue' },
}

const meta = computed(
  () =>
    labels[props.value] ?? {
      label: props.value || '未知',
      type: 'info' as TagProps['type'],
      tone: 'blue',
    },
)
</script>

<style scoped>
.status-dot {
  display: inline-block;
  width: 6px;
  height: 6px;
  margin-right: 5px;
  border-radius: 50%;
  vertical-align: 1px;
  background: currentColor;
}

.status-dot--green {
  color: #287862;
}

.status-dot--amber {
  color: #d58a2a;
}

.status-dot--red {
  color: #c2544c;
}

.status-dot--blue {
  color: #3b739d;
}

.status-dot--slate {
  color: #788681;
}
</style>
