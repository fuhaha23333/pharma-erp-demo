<template>
  <section class="section-card" :class="{ 'section-card--flush': flush }">
    <header v-if="title || $slots.header" class="section-card__header">
      <slot name="header">
        <div>
          <h2>{{ title }}</h2>
          <p v-if="description">{{ description }}</p>
        </div>
      </slot>
      <div v-if="$slots.actions" class="section-card__actions">
        <slot name="actions" />
      </div>
    </header>
    <div class="section-card__body">
      <slot />
    </div>
  </section>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    title?: string
    description?: string
    flush?: boolean
  }>(),
  {
    flush: false,
  },
)
</script>
