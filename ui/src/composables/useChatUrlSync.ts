import { useRouter, useRoute } from 'vue-router'

export function useChatUrlSync() {
  const router = useRouter()
  const route = useRoute()

  /**
   * 更新 URL 中的 chat_id 參數
   */
  const updateChatIdInUrl = (chatId: string) => {
    const query = { ...route.query }
    
    if (chatId === 'new') {
      // 新對話時移除 chat_id 參數，但保留其他參數如 form_id
      delete query.chat_id
    } else {
      // 設置 chat_id 參數，保留其他現有參數
      query.chat_id = chatId
    }
    
    // 檢查是否有 form_id 需要保留
    if (route.query.form_id) {
      query.form_id = route.query.form_id
    }
    
    const newRoute = {
      name: route.name,
      params: route.params,
      query
    }
    
    // 使用 router.replace 避免產生新的歷史記錄
    router.replace(newRoute)
  }

  /**
   * 從 URL 移除 form_id 參數
   */
  const removeFormIdFromUrl = () => {
    const query = { ...route.query }
    delete query.form_id
    
    const newRoute = {
      name: route.name,
      params: route.params,
      query
    }
    
    router.replace(newRoute)
  }

  return {
    updateChatIdInUrl,
    removeFormIdFromUrl
  }
}