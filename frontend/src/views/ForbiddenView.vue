<template>
  <div class="result-page">
    <div class="result-page__code">403</div>
    <h1>当前角色无权访问</h1>
    <p>页面入口和按钮会按权限隐藏，最终授权仍由后端接口校验。</p>
    <ElButton type="primary" @click="$router.push('/')">返回工作台</ElButton>
  </div>
</template>
