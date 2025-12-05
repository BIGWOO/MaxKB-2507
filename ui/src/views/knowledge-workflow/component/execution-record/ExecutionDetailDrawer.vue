<template>
  <el-drawer
    v-model="visible"
    size="800px"
    :modal="false"
    destroy-on-close
    :before-close="closeHandle"
    :close-on-click-modal="false"
    :close-on-press-escape="false"
    :show-close="false"
  >
    <template #header>
      <div class="flex align-center" style="margin-left: -8px">
        <el-button class="cursor mr-4" link @click.prevent="visible = false">
          <el-icon :size="20">
            <Back />
          </el-icon>
        </el-button>
        <h4>{{ $t('chat.executionDetails.title') }}</h4>
      </div>
    </template>
    <div>
      <el-scrollbar>
        <h4 class="title-decoration-1 mb-16 mt-4">
          {{ $t('workflow.ExecutionRecord') }}
        </h4>
        <el-card class="mb-24" shadow="never" style="--el-card-padding: 12px 16px">
          <el-row :gutter="16" class="lighter">
            <el-col :span="6">
              <p class="color-secondary mb-4">{{ $t('workflow.initiator') }}</p>
              <p>{{ detail?.meta.user_name || '-' }}</p>
            </el-col>
            <el-col :span="6">
              <p class="color-secondary mb-4">{{ $t('common.status.label') }}</p>
              <p>
                <el-text class="color-text-primary" v-if="detail?.state === 'SUCCESS'">
                  <el-icon class="color-success"><SuccessFilled /></el-icon>
                  {{ $t('common.status.success') }}
                </el-text>
                <el-text class="color-text-primary" v-else-if="detail?.state === 'FAILURE'">
                  <el-icon class="color-danger"><CircleCloseFilled /></el-icon>
                  {{ $t('common.status.fail') }}
                </el-text>
                <el-text class="color-text-primary" v-else>
                  <el-icon class="is-loading color-primary"><Loading /></el-icon>
                  {{ $t('common.status.padding') }}
                </el-text>
              </p>
            </el-col>
            <el-col :span="6">
              <p class="color-secondary mb-4">{{ $t('chat.KnowledgeSource.consumeTime') }}</p>
              <p>{{ detail?.run_time != undefined ? detail?.run_time + 's' : '-' }}</p>
            </el-col>
            <el-col :span="6">
              <p class="color-secondary mb-4">{{ $t('chat.executionDetails.createTime') }}</p>
              <p>{{ datetimeFormat(detail?.create_time) }}</p>
            </el-col>
          </el-row>
        </el-card>
        <Result :knowledge_id="knowledge_id" :id="action_id" is-record />
      </el-scrollbar>
    </div>
    <template #footer>
      <div>
        <el-button @click="pre" :disabled="pre_disable || loading">{{
          $t('common.pages.prev')
        }}</el-button>
        <el-button @click="next" :disabled="next_disable || loading">{{
          $t('common.pages.next')
        }}</el-button>
      </div>
    </template>
  </el-drawer>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import Result from '@/views/knowledge-workflow/component/action/Result.vue'
import { datetimeFormat } from '@/utils/time'
import { t } from '@/locales'
const props = withDefaults(
  defineProps<{
    /**
     * 当前的id
     */
    currentId: string
    currentContent: string
    /**
     * 下一条
     */
    next: () => void
    /**
     * 上一条
     */
    pre: () => void

    pre_disable: boolean

    next_disable: boolean
  }>(),
  {},
)

const emit = defineEmits(['update:currentId', 'update:currentContent', 'refresh'])

const route = useRoute()

const apiType = computed(() => {
  if (route.path.includes('shared')) {
    return 'systemShare'
  } else if (route.path.includes('resource-management')) {
    return 'systemManage'
  } else {
    return 'workspace'
  }
})

const loading = ref(false)
const visible = ref(false)
const action_id = ref<string>('')
const knowledge_id = ref<string>('')
const detail = ref<any>(null)

function closeHandle() {
  action_id.value = ''
  knowledge_id.value = ''
  detail.value = null
}

function getRecord() {
  if (props.currentId && visible.value) {
  }
}

watch(
  () => props.currentId,
  () => {
    action_id.value = ''
    knowledge_id.value = ''
    detail.value = null
  },
)

watch(visible, (bool) => {
  if (!bool) {
    emit('update:currentId', '')
    emit('update:currentContent', '')
    emit('refresh')
  }
})

const open = (row: any) => {
  action_id.value = row.id
  knowledge_id.value = row.knowledge_id
  detail.value = row
  visible.value = true
}

defineExpose({
  open,
})
</script>
<style lang="scss"></style>
