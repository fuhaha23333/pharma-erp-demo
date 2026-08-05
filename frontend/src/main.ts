import { createApp, type Plugin } from 'vue'
import {
  ElAlert,
  ElButton,
  ElConfigProvider,
  ElDatePicker,
  ElDialog,
  ElDropdown,
  ElDropdownItem,
  ElDropdownMenu,
  ElEmpty,
  ElForm,
  ElFormItem,
  ElIcon,
  ElInput,
  ElInputNumber,
  ElLoading,
  ElOption,
  ElPagination,
  ElRadioButton,
  ElRadioGroup,
  ElSelect,
  ElSwitch,
  ElTable,
  ElTableColumn,
  ElTag,
  ElTimeline,
  ElTimelineItem,
  ElTooltip,
  ElTree,
  ElTreeSelect,
} from 'element-plus'
import 'element-plus/dist/index.css'
import '@/styles/base.css'
import App from '@/App.vue'
import router from '@/router'
import { installUnauthorizedHandler } from '@/api/http'
import { expireSession } from '@/stores/auth'

const app = createApp(App)

const elementPlugins: Plugin[] = [
  ElAlert,
  ElButton,
  ElConfigProvider,
  ElDatePicker,
  ElDialog,
  ElDropdown,
  ElDropdownItem,
  ElDropdownMenu,
  ElEmpty,
  ElForm,
  ElFormItem,
  ElIcon,
  ElInput,
  ElInputNumber,
  ElLoading,
  ElOption,
  ElPagination,
  ElRadioButton,
  ElRadioGroup,
  ElSelect,
  ElSwitch,
  ElTable,
  ElTableColumn,
  ElTag,
  ElTimeline,
  ElTimelineItem,
  ElTooltip,
  ElTree,
  ElTreeSelect,
]

elementPlugins.forEach((plugin) => app.use(plugin))
app.use(router)

installUnauthorizedHandler(() => {
  expireSession()
  if (router.currentRoute.value.name !== 'login') {
    void router.replace({
      name: 'login',
      query: { redirect: router.currentRoute.value.fullPath, reason: 'expired' },
    })
  }
})

app.mount('#app')
