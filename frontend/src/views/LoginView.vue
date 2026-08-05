<template>
  <div class="login-page">
    <section class="login-story">
      <div class="login-story__brand">
        <span>药</span>
        <div>
          <strong>药链明鉴</strong>
          <small>PHARMA ERP DEMO</small>
        </div>
      </div>

      <div class="login-story__content">
        <p class="login-story__eyebrow">NATIONAL_DEFAULT · PHASE 01</p>
        <h1>让每一次准入<br />都有证据可循</h1>
        <p>
          供应商资质、岗位权限与批号生命周期，在同一条可信链路中被记录、审核和查询。
        </p>
        <div class="flow-line" aria-label="第一阶段功能">
          <span>身份</span><i />
          <span>授权</span><i />
          <span>准入</span><i />
          <span>追溯</span>
        </div>
      </div>

      <p class="login-story__legal">
        验证型 Demo · 不表示已通过 GSP 检查 · 请勿使用真实经营数据
      </p>
    </section>

    <section class="login-panel">
      <div class="login-card">
        <p class="login-card__eyebrow">欢迎回来</p>
        <h2>登录管理工作台</h2>
        <p class="login-card__intro">使用后端初始化的演示账号。账号密码不会写入本地存储。</p>

        <ElAlert
          v-if="route.query.reason === 'expired'"
          class="login-alert"
          title="登录状态已失效，请重新验证身份"
          type="warning"
          :closable="false"
          show-icon
        />

        <ElForm
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          size="large"
          @keyup.enter="submit"
        >
          <ElFormItem label="登录账号" prop="username">
            <ElInput
              v-model="form.username"
              autocomplete="username"
              placeholder="例如：admin"
              :prefix-icon="User"
            />
          </ElFormItem>
          <ElFormItem label="登录密码" prop="password">
            <ElInput
              v-model="form.password"
              type="password"
              autocomplete="current-password"
              placeholder="请输入密码"
              show-password
              :prefix-icon="Lock"
            />
          </ElFormItem>
          <ElButton
            class="login-submit"
            type="primary"
            size="large"
            :loading="authState.authenticating"
            @click="submit"
          >
            验证身份并进入
            <ElIcon class="el-icon--right"><Right /></ElIcon>
          </ElButton>
        </ElForm>

        <div class="login-security">
          <ElIcon><CircleCheck /></ElIcon>
          <span>HTTP Basic 凭据仅保存在当前页面内存；刷新或关闭页面后需要重新登录。</span>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { CircleCheck, Lock, Right, User } from '@element-plus/icons-vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getErrorMessage } from '@/api/http'
import { authState, login as authenticate } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const formRef = ref<FormInstance>()
const form = reactive({
  username: '',
  password: '',
})

const rules: FormRules = {
  username: [
    { required: true, message: '请输入登录账号', trigger: 'blur' },
    { max: 64, message: '账号不能超过 64 个字符', trigger: 'blur' },
  ],
  password: [{ required: true, message: '请输入登录密码', trigger: 'blur' }],
}

async function submit(): Promise<void> {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) {
    return
  }

  try {
    await authenticate(form.username, form.password)
    ElMessage.success('身份验证成功')
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    await router.replace(redirect.startsWith('/') ? redirect : '/')
  } catch (error) {
    ElMessage.error(getErrorMessage(error))
  }
}
</script>

<style scoped>
.login-page {
  display: grid;
  min-height: 100vh;
  grid-template-columns: minmax(460px, 1.08fr) minmax(420px, 0.92fr);
  background: #f4f3ee;
}

.login-story {
  position: relative;
  display: flex;
  min-height: 100vh;
  justify-content: space-between;
  flex-direction: column;
  overflow: hidden;
  padding: clamp(30px, 5vw, 72px);
  color: #eff6f2;
  background:
    radial-gradient(circle at 78% 20%, rgba(110, 173, 143, 0.2), transparent 26%),
    linear-gradient(150deg, #173f36 0%, #0d2924 68%, #0a201d 100%);
}

.login-story::before,
.login-story::after {
  position: absolute;
  border: 1px solid rgba(255, 255, 255, 0.07);
  border-radius: 50%;
  content: "";
}

.login-story::before {
  right: -190px;
  bottom: -210px;
  width: 570px;
  height: 570px;
}

.login-story::after {
  right: -65px;
  bottom: -85px;
  width: 320px;
  height: 320px;
}

.login-story__brand {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 14px;
}

.login-story__brand > span {
  display: grid;
  width: 44px;
  height: 44px;
  place-items: center;
  border-radius: 13px 4px 13px 4px;
  color: #163c33;
  background: #dfbd84;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 25px;
  font-weight: 700;
}

.login-story__brand strong,
.login-story__brand small {
  display: block;
}

.login-story__brand strong {
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 22px;
  letter-spacing: 0.12em;
}

.login-story__brand small {
  margin-top: 3px;
  color: #89aaa0;
  font-size: 9px;
  letter-spacing: 0.18em;
}

.login-story__content {
  position: relative;
  z-index: 1;
  max-width: 650px;
  margin: auto 0;
  padding: 60px 0;
}

.login-story__eyebrow {
  margin-bottom: 20px;
  color: #dfbd84;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.2em;
}

.login-story h1 {
  margin-bottom: 24px;
  font-family: "STKaiti", "KaiTi", "PingFang SC", serif;
  font-size: clamp(46px, 6vw, 76px);
  font-weight: 600;
  letter-spacing: 0.06em;
  line-height: 1.18;
}

.login-story__content > p:not(.login-story__eyebrow) {
  max-width: 540px;
  color: #aac1ba;
  font-size: 15px;
  line-height: 1.9;
}

.flow-line {
  display: flex;
  max-width: 520px;
  align-items: center;
  margin-top: 38px;
}

.flow-line span {
  display: grid;
  width: 58px;
  height: 58px;
  flex: 0 0 58px;
  place-items: center;
  border: 1px solid rgba(222, 189, 132, 0.36);
  border-radius: 50%;
  color: #e8d4b2;
  font-size: 12px;
}

.flow-line i {
  height: 1px;
  flex: 1;
  background: linear-gradient(90deg, rgba(222, 189, 132, 0.35), rgba(115, 163, 145, 0.25));
}

.login-story__legal {
  position: relative;
  z-index: 1;
  margin: 0;
  color: #66877d;
  font-size: 10px;
  letter-spacing: 0.05em;
}

.login-panel {
  display: grid;
  min-height: 100vh;
  place-items: center;
  padding: clamp(24px, 6vw, 88px);
}

.login-card {
  width: min(100%, 430px);
}

.login-card__eyebrow {
  margin-bottom: 10px;
  color: #25705b;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.18em;
}

.login-card h2 {
  margin-bottom: 10px;
  color: #172a25;
  font-family: "STKaiti", "KaiTi", serif;
  font-size: 34px;
  letter-spacing: 0.04em;
}

.login-card__intro {
  margin-bottom: 32px;
  color: #77847f;
  font-size: 13px;
  line-height: 1.7;
}

.login-alert {
  margin-bottom: 20px;
}

.login-submit {
  width: 100%;
  height: 48px;
  margin-top: 6px;
}

.login-security {
  display: flex;
  align-items: flex-start;
  gap: 9px;
  margin-top: 22px;
  padding: 13px 14px;
  border: 1px solid #dce8e2;
  border-radius: 10px 4px 10px 4px;
  color: #65736e;
  background: #edf4f0;
  font-size: 11px;
  line-height: 1.55;
}

.login-security .el-icon {
  flex: 0 0 auto;
  margin-top: 2px;
  color: #2c7b65;
}

@media (max-width: 900px) {
  .login-page {
    grid-template-columns: 1fr;
  }

  .login-story {
    min-height: auto;
    padding: 28px 24px 36px;
  }

  .login-story__content {
    padding: 50px 0 30px;
  }

  .login-story h1 {
    font-size: 46px;
  }

  .flow-line,
  .login-story__legal {
    display: none;
  }

  .login-panel {
    min-height: auto;
    padding: 42px 24px 64px;
  }
}
</style>
