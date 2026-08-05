<template>
  <ElRadioGroup
    v-model="decision"
    class="review-decision-field"
    aria-label="审核决定"
  >
    <ElRadioButton
      value="APPROVED"
      class="review-decision-field__option review-decision-field__option--approved"
    >
      <span class="review-decision-field__mark" aria-hidden="true">✓</span>
      <span class="review-decision-field__copy">
        <strong>审核通过</strong>
        <small>资质符合准入要求</small>
      </span>
    </ElRadioButton>
    <ElRadioButton
      value="REJECTED"
      class="review-decision-field__option review-decision-field__option--rejected"
    >
      <span class="review-decision-field__mark" aria-hidden="true">×</span>
      <span class="review-decision-field__copy">
        <strong>审核驳回</strong>
        <small>退回并说明具体原因</small>
      </span>
    </ElRadioButton>
  </ElRadioGroup>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ElRadioButton, ElRadioGroup } from 'element-plus'
import type { ReviewPayload } from '@/types/supplier'

type ReviewDecision = ReviewPayload['decision']

const props = defineProps<{
  modelValue: ReviewDecision
}>()

const emit = defineEmits<{
  'update:modelValue': [value: ReviewDecision]
}>()

const decision = computed({
  get: () => props.modelValue,
  set: (value: ReviewDecision) => emit('update:modelValue', value),
})
</script>

<style scoped>
.review-decision-field {
  display: grid;
  width: 100%;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.review-decision-field__option {
  width: 100%;
}

.review-decision-field__option :deep(.el-radio-button__inner) {
  display: flex;
  width: 100%;
  min-height: 72px;
  align-items: center;
  gap: 11px;
  padding: 13px 15px;
  border: 1px solid #d8dfda;
  border-radius: 10px 4px 10px 4px !important;
  color: #52635d;
  background: #fffefb;
  box-shadow: none !important;
  text-align: left;
  transition:
    border-color 150ms ease,
    background-color 150ms ease,
    color 150ms ease;
}

.review-decision-field__option :deep(.el-radio-button__inner:hover) {
  border-color: #9eada7;
  color: #253c34;
}

.review-decision-field__option--approved.is-active
  :deep(.el-radio-button__inner) {
  border-color: #3f8b71;
  color: #1f654f;
  background: #edf7f2;
}

.review-decision-field__option--rejected.is-active
  :deep(.el-radio-button__inner) {
  border-color: #c8645c;
  color: #9d403a;
  background: #fbefed;
}

.review-decision-field__mark {
  display: grid;
  width: 25px;
  height: 25px;
  flex: 0 0 auto;
  place-items: center;
  border: 1px solid currentColor;
  border-radius: 50%;
  font-size: 15px;
  font-weight: 800;
  line-height: 1;
}

.review-decision-field__copy {
  display: flex;
  min-width: 0;
  flex-direction: column;
  gap: 4px;
}

.review-decision-field__copy strong {
  font-size: 13px;
  line-height: 1.2;
}

.review-decision-field__copy small {
  color: #86928e;
  font-size: 10px;
  line-height: 1.35;
}

@media (max-width: 560px) {
  .review-decision-field {
    grid-template-columns: 1fr;
  }
}
</style>
