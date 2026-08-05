<template>
  <div class="standalone-result">
    <div class="result-page">
      <div class="result-page__code">404</div>
      <h1>没有找到这个页面</h1>
      <p>地址可能已经变更，或该功能尚未进入第一阶段范围。</p>
      <ElButton type="primary" @click="$router.push('/')">返回首页</ElButton>
    </div>
  </div>
</template>
