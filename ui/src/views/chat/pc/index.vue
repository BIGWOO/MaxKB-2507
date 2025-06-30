<template>
  <div
    class="chat-pc layout-bg"
    :class="classObj"
    v-loading="loading"
    :style="{
      '--el-color-primary': applicationDetail?.custom_theme?.theme_color,
      '--el-color-primary-light-9': hexToRgba(applicationDetail?.custom_theme?.theme_color, 0.1)
    }"
  >
    <div class="chat-pc__header" :style="customStyle">
      <div class="flex align-center">
        <div class="mr-12 ml-24 flex">
          <AppAvatar
            v-if="isAppIcon(applicationDetail?.icon)"
            shape="square"
            :size="32"
            style="background: none"
          >
            <img :src="applicationDetail?.icon" alt="" />
          </AppAvatar>
          <AppAvatar
            v-else-if="applicationDetail?.name"
            :name="applicationDetail?.name"
            pinyinColor
            shape="square"
            :size="32"
          />
        </div>
        <h4>{{ applicationDetail?.name }}</h4>
      </div>
    </div>
    <div>
      <div class="flex">
        <div class="chat-pc__left border-r">
          <div class="p-24 pb-0">
            <el-button class="add-button w-full primary" @click="newChat">
              <el-icon>
                <Plus />
              </el-icon>
              <span class="ml-4">{{ $t('chat.createChat') }}</span>
            </el-button>
            <p class="mt-20 mb-8">{{ $t('chat.history') }}</p>
          </div>
          <div class="left-height pt-0">
            <el-scrollbar>
              <div class="p-8 pt-0">
                <common-list
                  :style="{
                    '--el-color-primary': applicationDetail?.custom_theme?.theme_color,
                    '--el-color-primary-light-9': hexToRgba(
                      applicationDetail?.custom_theme?.theme_color,
                      0.1
                    )
                  }"
                  :data="chatLogData"
                  class="mt-8"
                  v-loading="left_loading"
                  :defaultActive="currentChatId"
                  @click="clickListHandle"
                  @mouseenter="mouseenter"
                  @mouseleave="mouseId = ''"
                >
                  <template #default="{ row }">
                    <div class="flex-between">
                      <auto-tooltip :content="row.abstract">
                        {{ row.abstract }}
                      </auto-tooltip>
                      <div @click.stop v-show="mouseId === row.id && row.id !== 'new'">
                        <el-dropdown trigger="click" :teleported="false">
                          <el-icon class="rotate-90 mt-4"><MoreFilled /></el-icon>
                          <template #dropdown>
                            <el-dropdown-menu>
                              <el-dropdown-item @click.stop="editLogTitle(row)">
                                <el-icon><EditPen /></el-icon>
                                {{ $t('common.edit') }}
                              </el-dropdown-item>
                              <el-dropdown-item @click.stop="deleteLog(row)">
                                <el-icon><Delete /></el-icon>
                                {{ $t('common.delete') }}
                              </el-dropdown-item>
                            </el-dropdown-menu>
                          </template>
                        </el-dropdown>
                      </div>
                    </div>
                  </template>

                  <template #empty>
                    <div class="text-center">
                      <el-text type="info">{{ $t('chat.noHistory') }}</el-text>
                    </div>
                  </template>
                </common-list>
              </div>
              <div v-if="chatLogData?.length" class="gradient-divider lighter mt-8">
                <span>{{ $t('chat.only20history') }}</span>
              </div>
            </el-scrollbar>
          </div>
        </div>
        <div class="chat-pc__right">
          <div class="right-header border-b mb-24 p-16-24 flex-between">
            <h4 class="ellipsis-1" style="width: 66%">
              {{ currentChatName }}
            </h4>

            <span class="flex align-center" v-if="currentRecordList.length">
              <AppIcon
                v-if="paginationConfig.total"
                iconName="app-chat-record"
                class="info mr-8"
                style="font-size: 16px"
              ></AppIcon>
              <span v-if="paginationConfig.total" class="lighter">
                {{ paginationConfig.total }} {{ $t('chat.question_count') }}
              </span>
              <el-dropdown class="ml-8">
                <AppIcon
                  iconName="app-export"
                  class="cursor"
                  :title="$t('chat.exportRecords')"
                ></AppIcon>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item @click="exportMarkdown"
                      >{{ $t('common.export') }} Markdown</el-dropdown-item
                    >
                    <el-dropdown-item @click="exportHTML"
                      >{{ $t('common.export') }} HTML</el-dropdown-item
                    >
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </span>
          </div>
          <div class="right-height chat-width">
            <AiChat
              ref="AiChatRef"
              v-model:applicationDetails="applicationDetail"
              :available="applicationAvailable"
              type="ai-chat"
              :appId="applicationDetail?.id"
              :record="currentRecordList"
              :chatId="currentChatId"
              @refresh="refresh"
              @scroll="handleScroll"
            >
            </AiChat>
          </div>
        </div>
      </div>
      <div class="collapse">
        <el-button @click="isCollapse = !isCollapse">
          <el-icon> <component :is="isCollapse ? 'Fold' : 'Expand'" /></el-icon>
        </el-button>
      </div>
    </div>
    <EditTitleDialog ref="EditTitleDialogRef" @refresh="refreshFieldTitle" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { marked } from 'marked'
import { saveAs } from 'file-saver'
import { isAppIcon } from '@/utils/application'
import useStore from '@/stores'
import useResize from '@/layout/hooks/useResize'
import { hexToRgba } from '@/utils/theme'
import EditTitleDialog from './EditTitleDialog.vue'
import { t } from '@/locales'
import { useChatUrlSync } from '@/composables/useChatUrlSync'
useResize()

const { user, log, common } = useStore()
const { updateChatIdInUrl, removeFormIdFromUrl } = useChatUrlSync()

const EditTitleDialogRef = ref()

const isCollapse = ref(false)

const customStyle = computed(() => {
  return {
    background: applicationDetail.value?.custom_theme?.theme_color,
    color: applicationDetail.value?.custom_theme?.header_font_color
  }
})

const classObj = computed(() => {
  return {
    mobile: common.isMobile(),
    hideLeft: !isCollapse.value,
    openLeft: isCollapse.value
  }
})

const newObj = {
  id: 'new',
  abstract: t('chat.createChat')
}
const props = defineProps<{
  application_profile: any
  applicationAvailable: boolean
  initial_chat_id?: string
  initial_form_id?: string
}>()
const AiChatRef = ref()
const loading = ref(false)
const left_loading = ref(false)

const applicationDetail = computed({
  get: () => {
    return props.application_profile
  },
  set: (v) => {}
})

const chatLogData = ref<any[]>([])

const paginationConfig = ref({
  current_page: 1,
  page_size: 20,
  total: 0
})

const currentRecordList = ref<any>([])
const currentChatId = ref('new') // 当前历史记录Id 默认为'new'
const currentChatName = ref(t('chat.createChat'))
const mouseId = ref('')

function mouseenter(row: any) {
  mouseId.value = row.id
}

function editLogTitle(row: any) {
  EditTitleDialogRef.value.open(row, applicationDetail.value.id)
}
function refreshFieldTitle(chatId: string, abstract: string) {
  const find = chatLogData.value.find((item: any) => item.id == chatId)
  if (find) {
    find.abstract = abstract
  }
}
function deleteLog(row: any) {
  log.asyncDelChatClientLog(applicationDetail.value.id, row.id, left_loading).then(() => {
    if (currentChatId.value === row.id) {
      currentChatId.value = 'new'
      currentChatName.value = t('chat.createChat')
      paginationConfig.value.current_page = 1
      paginationConfig.value.total = 0
      currentRecordList.value = []
    }
    getChatLog(applicationDetail.value.id)
  })
}

function handleScroll(event: any) {
  if (
    currentChatId.value !== 'new' &&
    event.scrollTop === 0 &&
    paginationConfig.value.total > currentRecordList.value.length
  ) {
    const history_height = event.dialogScrollbar.offsetHeight
    paginationConfig.value.current_page += 1
    getChatRecord().then(() => {
      event.scrollDiv.setScrollTop(event.dialogScrollbar.offsetHeight - history_height)
    })
  }
}

function newChat() {
  // 統一處理狀態重置，移除重複邏輯
  paginationConfig.value.current_page = 1
  paginationConfig.value.total = 0
  currentRecordList.value = []
  
  // 確保新對話項目存在於歷史記錄中
  const hasNewItem = chatLogData.value.some((v) => v.id === 'new')
  if (!hasNewItem) {
    chatLogData.value.unshift(newObj)
  }
  
  // 強制更新狀態
  currentChatId.value = 'new'
  currentChatName.value = t('chat.createChat')
  
  // 新對話時從 URL 移除 chat_id 參數
  updateChatIdInUrl('new')
  
  if (common.isMobile()) {
    isCollapse.value = false
  }
}

function getChatLog(id: string, refresh?: boolean) {
  const page = {
    current_page: 1,
    page_size: 20
  }

  return log.asyncGetChatLogClient(id, page, left_loading).then((res: any) => {
    chatLogData.value = res.data.records
    
    if (refresh) {
      currentChatName.value = chatLogData.value?.[0]?.abstract
    } else {
      paginationConfig.value.current_page = 1
      paginationConfig.value.total = 0
      currentRecordList.value = []
    }
  })
}

function getChatRecord() {
  return log
    .asyncChatRecordLog(
      applicationDetail.value.id,
      currentChatId.value,
      paginationConfig.value,
      loading,
      false
    )
    .then((res: any) => {
      paginationConfig.value.total = res.data.total
      const list = res.data.records
      list.map((v: any) => {
        v['write_ed'] = true
        v['record_id'] = v.id
      })
      currentRecordList.value = [...list, ...currentRecordList.value].sort((a, b) => {
        const timeA = a.create_time || ''
        const timeB = b.create_time || ''
        return timeA.localeCompare(timeB)
      })
      
      if (paginationConfig.value.current_page === 1) {
        nextTick(() => {
          AiChatRef.value?.setScrollBottom()
        })
      }
    })
    .catch((error) => {
      throw error // 重新拋出錯誤以供調用者處理
    })
}

const clickListHandle = (item: any) => {
  // 強制更新狀態，移除條件判斷避免點擊兩次的問題
  paginationConfig.value.current_page = 1
  paginationConfig.value.total = 0
  currentRecordList.value = []
  
  currentChatId.value = item.id
  currentChatName.value = item.abstract
  
  // 同步更新 URL 中的 chat_id 參數
  updateChatIdInUrl(item.id)
  
  if (currentChatId.value !== 'new') {
    getChatRecord()

    // 切换对话后，取消暂停的浏览器播放
    if (window.speechSynthesis.paused && window.speechSynthesis.speaking) {
      window.speechSynthesis.resume()
      nextTick(() => {
        window.speechSynthesis.cancel()
      })
    }
  }
  
  if (common.isMobile()) {
    isCollapse.value = false
  }
}

function refresh(id: string) {
  getChatLog(applicationDetail.value.id, true)
  currentChatId.value = id
  // 更新 URL 中的 chat_id 參數
  updateChatIdInUrl(id)
}

async function exportMarkdown(): Promise<void> {
  const suggestedName: string = `${currentChatId.value}.md`
  const markdownContent: string = currentRecordList.value
    .map((record: any) => `# ${record.problem_text}\n\n${record.answer_text}\n\n`)
    .join('\n')

  const blob: Blob = new Blob([markdownContent], { type: 'text/markdown;charset=utf-8' })
  saveAs(blob, suggestedName)
}

async function exportHTML(): Promise<void> {
  const suggestedName: string = `${currentChatId.value}.html`
  const markdownContent: string = currentRecordList.value
    .map((record: any) => `# ${record.problem_text}\n\n${record.answer_text}\n\n`)
    .join('\n')
  const htmlContent: any = marked(markdownContent)

  const blob: Blob = new Blob([htmlContent], { type: 'text/html;charset=utf-8' })
  saveAs(blob, suggestedName)
}

/**
 * 處理初始 URL 參數
 */
const handleInitialParams = () => {
  // 處理 chat_id 參數
  if (props.initial_chat_id && props.initial_chat_id !== 'new') {
    const targetChat = chatLogData.value.find((item: any) => item.id === props.initial_chat_id)
    
    if (targetChat) {
      clickListHandle(targetChat)
      
      // 等待歷史對話載入完成後再處理 form_id
      nextTick(() => {
        handleFormIdAfterChatLoad()
      })
    } else {
      // 直接設置 chat_id 並嘗試載入對話記錄
      currentChatId.value = props.initial_chat_id
      updateChatIdInUrl(props.initial_chat_id)
      
      // 嘗試獲取對話記錄，改善錯誤處理和重試機制
      const loadChatRecord = async (retryCount = 0) => {
        try {
          await getChatRecord()
          
          // 歷史對話載入完成後處理 form_id
          nextTick(() => {
            handleFormIdAfterChatLoad()
          })
        } catch (error) {
          // 檢查是否為 404 錯誤（對話不存在）
          if (error?.response?.status === 404 || error?.message?.includes('404')) {
            newChat()
            // 新對話也需要處理 form_id
            nextTick(() => {
              handleFormIdAfterChatLoad()
            })
            return
          }
          
          // 網路錯誤且重試次數小於 2 次，則重試
          if (retryCount < 2 && (error?.code === 'NETWORK_ERROR' || !error?.response)) {
            setTimeout(() => loadChatRecord(retryCount + 1), 1000 * (retryCount + 1))
            return
          }
          
          // 其他錯誤或重試次數用盡，保留 chat_id 但顯示錯誤狀態
          currentRecordList.value = []
          paginationConfig.value.total = 0
          
          // 即使載入失敗也處理 form_id
          nextTick(() => {
            handleFormIdAfterChatLoad()
          })
        }
      }
      
      loadChatRecord()
    }
  } else {
    // 如果當前還沒有設定 currentChatId 或者被自動設定為歷史記錄中的對話
    if (currentChatId.value === 'new' || !currentChatId.value || chatLogData.value.some(item => item.id === currentChatId.value)) {
      newChat()
    }
    
    // 新對話狀態下也要處理 form_id
    nextTick(() => {
      handleFormIdAfterChatLoad()
    })
  }
}

/**
 * 在歷史對話載入完成後處理 form_id 參數
 */
const handleFormIdAfterChatLoad = () => {
  if (props.initial_form_id) {
    // 檢查是否已經處理過這個 form_id
    if (!window.processedFormIds) {
      window.processedFormIds = new Set()
    }
    
    if (!window.processedFormIds.has(props.initial_form_id)) {
      window.processedFormIds.add(props.initial_form_id)
      
      // 給一個短暫的延遲確保歷史對話已完全載入並渲染
      setTimeout(() => {
        sendFormMessage(props.initial_form_id!)
        // 立即移除 form_id，避免 URL 閃爍
        removeFormIdFromUrl()
      }, 500) // 500ms 延遲確保渲染完成
    }
  }
}

/**
 * 發送表單訊息
 */
const sendFormMessage = (formId: string) => {
  const message = `我已填寫表單 @${formId}`
  
  const trySendMessage = () => {
    if (AiChatRef.value && AiChatRef.value.sendMessage) {
      AiChatRef.value.sendMessage(message)
      return true
    } else {
      return false
    }
  }
  
  // 嘗試立即發送
  if (!trySendMessage()) {
    let attempts = 0
    const maxAttempts = 20
    
    const pollInterval = setInterval(() => {
      attempts++
      
      if (trySendMessage()) {
        clearInterval(pollInterval)
      } else if (attempts >= maxAttempts) {
        clearInterval(pollInterval)
      }
    }, 100)
  }
}


/**
 *初始化历史对话记录
 */
const init = () => {
  if (
    (applicationDetail.value.show_history || !user.isEnterprise()) &&
    props.applicationAvailable
  ) {
    getChatLog(applicationDetail.value.id).then(() => {
      // 歷史記錄載入完成後處理初始參數
      handleInitialParams()
    })
  } else {
    // 即使不載入歷史記錄，也要處理 form_id 參數
    handleInitialParams()
  }
}

onMounted(() => {
  init()
})
</script>
<style lang="scss">
.chat-pc {
  overflow: hidden;

  &__header {
    background: var(--app-header-bg-color);
    position: fixed;
    width: 100%;
    left: 0;
    top: 0;
    z-index: 100;
    height: var(--app-header-height);
    line-height: var(--app-header-height);
    box-sizing: border-box;
    border-bottom: 1px solid var(--el-border-color);
  }

  &__left {
    padding-top: calc(var(--app-header-height) - 8px);
    background: #ffffff;
    width: 280px;

    .add-button {
      border: 1px solid var(--el-color-primary);
    }

    .left-height {
      height: calc(100vh - var(--app-header-height) - 135px);
    }
  }

  &__right {
    width: calc(100% - 280px);
    padding-top: calc(var(--app-header-height));
    overflow: hidden;
    position: relative;
    box-sizing: border-box;

    .right-header {
      background: #ffffff;
      box-sizing: border-box;
    }

    .right-height {
      height: calc(100vh - var(--app-header-height) * 2 - 24px);
    }
  }

  .gradient-divider {
    position: relative;
    text-align: center;
    color: var(--el-color-info);

    ::before {
      content: '';
      width: 17%;
      height: 1px;
      background: linear-gradient(90deg, rgba(222, 224, 227, 0) 0%, #dee0e3 100%);
      position: absolute;
      left: 16px;
      top: 50%;
    }

    ::after {
      content: '';
      width: 17%;
      height: 1px;
      background: linear-gradient(90deg, #dee0e3 0%, rgba(222, 224, 227, 0) 100%);
      position: absolute;
      right: 16px;
      top: 50%;
    }
  }

  .collapse {
    display: none;
  }
}
// 适配移动端
.mobile {
  .chat-pc {
    &__right {
      width: 100%;
    }
    &__left {
      display: none;
      width: 0;
    }
  }
  .collapse {
    display: block;
    position: fixed;
    bottom: 90px;
    z-index: 99;
  }
  &.openLeft {
    .chat-pc {
      &__left {
        display: block;
        position: fixed;
        width: 100%;
        z-index: 99;
        height: calc(100vh - var(--app-header-height) + 6px);
      }
    }
    .collapse {
      display: block;
      position: absolute;
      bottom: 90px;
      right: 0;
      z-index: 99;
    }
  }
}

.chat-width {
  max-width: 80%;
  margin: 0 auto;
}
@media only screen and (max-width: 1000px) {
  .chat-width {
    max-width: 100% !important;
    margin: 0 auto;
  }
}
</style>
