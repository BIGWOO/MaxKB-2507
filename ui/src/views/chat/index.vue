<template>
  <component
    v-if="chat_show && init_data_end"
    :applicationAvailable="applicationAvailable"
    :is="currentTemplate"
    :application_profile="application_profile"
    :initial_chat_id="chat_id"
    :initial_form_id="form_id"
    :key="route.fullPath"
    v-loading="loading"
  />
  <Auth
    v-else
    :application_profile="application_profile"
    :auth_type="application_profile.authentication_type"
    v-model="is_auth"
    :style="{
      '--el-color-primary': application_profile?.custom_theme?.theme_color,
      '--el-color-primary-light-9': hexToRgba(application_profile?.custom_theme?.theme_color, 0.1)
    }"
  ></Auth>
</template>
<script setup lang="ts">
import { ref, onBeforeMount, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import useStore from '@/stores'
import Auth from '@/views/chat/auth/index.vue'
import { hexToRgba } from '@/utils/theme'
import { useI18n } from 'vue-i18n'
import { getBrowserLang } from '@/locales/index'
const { locale } = useI18n({ useScope: 'global' })
const route = useRoute()
const { application, user } = useStore()

const components: any = import.meta.glob('@/views/chat/**/index.vue', {
  eager: true
})

// 使用響應式的方式獲取路由參數，而不是靜態解構
const mode = computed(() => route.query.mode)
const chat_id = computed(() => route.query.chat_id)
const form_id = computed(() => route.query.form_id)
const accessToken = computed(() => route.params.accessToken)

// Chat 主組件初始化

// 監聽路由變化 (已移除 debug logs)
const is_auth = ref<boolean>(false)
const currentTemplate = computed(() => {
  let modeName = ''
  if (!mode.value || mode.value === 'pc') {
    modeName = show_history.value || !user.isEnterprise() ? 'pc' : 'base'
  } else {
    modeName = mode.value
  }
  const name = `/src/views/chat/${modeName}/index.vue`
  return components[name].default
})
/**
 * 是否显示对话
 */
const chat_show = computed(() => {
  if (init_data_end.value) {
    if (!applicationAvailable.value) {
      return true
    }
    if (application_profile.value) {
      if (application_profile.value.authentication && is_auth.value) {
        return true
      } else if (!application_profile.value.authentication) {
        return true
      }
    }
  }
  return false
})
const loading = ref(false)

const show_history = ref(false)

const application_profile = ref<any>({})
/**

 * 初始化结束
 */
const init_data_end = ref<boolean>(false)

const applicationAvailable = ref<boolean>(true)
function getAppProfile() {
  return application.asyncGetAppProfile(loading).then((res: any) => {
    locale.value = res.data?.language || getBrowserLang()
    show_history.value = res.data?.show_history
    application_profile.value = res.data
  })
}
function getAccessToken(token: string) {
  return application.asyncAppAuthentication(token, loading).then(() => {
    return getAppProfile()
  })
}
onBeforeMount(() => {
  user.changeUserType(2, accessToken.value)
  Promise.all([user.asyncGetProfile(), getAccessToken(accessToken.value)])
    .catch(() => {
      applicationAvailable.value = false
    })
    .finally(() => (init_data_end.value = true))
})
</script>
<style lang="scss"></style>
