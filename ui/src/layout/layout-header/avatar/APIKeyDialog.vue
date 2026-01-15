<template>
  <el-dialog
    :title="$t('layout.apiKey')"
    v-model="dialogVisible"
    width="1080"
    :close-on-click-modal="false"
    :close-on-press-escape="false"
    align-center
  >
    <el-card shadow="never" class="layout-bg mb-16">
      <el-text type="info" class="color-secondary">{{ $t('layout.apiServiceAddress') }}</el-text>
      <p style="margin-top: 10px">
        <span class="vertical-middle lighter break-all">
          {{ apiUrl }}
        </span>
        <el-button type="primary" text @click="copyClick(apiUrl)">
          <AppIcon iconName="app-copy"></AppIcon>
        </el-button>
      </p>
    </el-card>

    <el-button type="primary" class="mb-16" @click="createApiKey">
      {{ $t('common.create') }}
    </el-button>
    <app-table
      :data="apiKey"
      :loading="loading"
      style="min-height: 300px"
      :max-height="420"
      :pagination-config="paginationConfig"
      @sizeChange="handleSizeChange"
      @changePage="getApiKeyList"
    >
      <el-table-column prop="secret_key" label="API Key">
        <template #default="{ row }">
          <span class="vertical-middle lighter break-all">
            {{ row.secret_key }}
          </span>
          <el-button type="primary" text @click="copyClick(row.secret_key)">
            <AppIcon iconName="app-copy"></AppIcon>
          </el-button>
        </template>
      </el-table-column>
      <el-table-column :label="$t('views.document.enableStatus.label')" width="100">
        <template #default="{ row }">
          <div v-if="row.is_active" class="flex align-center">
            <el-icon class="color-success mr-8" style="font-size: 16px">
              <SuccessFilled />
            </el-icon>
            <span class="color-text-primary">
              {{ $t('common.status.enabled') }}
            </span>
          </div>
          <div v-else class="flex align-center">
            <AppIcon iconName="app-disabled" class="color-secondary mr-8"></AppIcon>
            <span class="color-text-primary">
              {{ $t('common.status.disabled') }}
            </span>
          </div>
        </template>
      </el-table-column>
      <el-table-column :label="$t('layout.crossSettings')" width="100">
        <template #default="{ row }">
          <el-tag type="info" class="info-tag">
            {{ $t('views.system.authentication.scanTheQRCode.alreadyTurnedOn') }}
          </el-tag>
          <el-tag class="blue-tag">
            {{ $t('views.system.authentication.scanTheQRCode.notEnabled') }}
          </el-tag>
        </template>
      </el-table-column>

      <el-table-column :label="$t('layout.about.expiredTime')" width="170">
        <template #default="{ row }">
          <!-- {{ datetimeFormat(row.create_time) }} -->
        </template>
      </el-table-column>
      <el-table-column :label="$t('common.createDate')" width="170" prop="create_time" sortable>
        <template #default="{ row }">
          {{ datetimeFormat(row.create_time) }}
        </template>
      </el-table-column>
      <el-table-column :label="$t('common.operation')" align="left" width="130">
        <template #default="{ row }">
          <span @click.stop>
            <el-switch size="small" v-model="row.is_active" @change="changeState($event, row)" />
          </span>
          <el-divider direction="vertical" />
          <span class="mr-4">
            <el-tooltip effect="dark" :content="$t('common.setting')" placement="top">
              <el-button type="primary" text @click.stop="settingApiKey(row)">
                <AppIcon iconName="app-edit"></AppIcon>
              </el-button>
            </el-tooltip>
          </span>
          <el-tooltip effect="dark" :content="$t('common.delete')" placement="top">
            <el-button type="primary" text @click="deleteApiKey(row)">
              <AppIcon iconName="app-delete"></AppIcon>
            </el-button>
          </el-tooltip>
        </template>
      </el-table-column>
    </app-table>
    <SettingAPIKeyDialog ref="SettingAPIKeyDialogRef" @refresh="refresh" />
  </el-dialog>
</template>
<script setup lang="ts">
import { ref, watch, reactive } from 'vue'
import { useRoute } from 'vue-router'
import { copyClick } from '@/utils/clipboard'
import systemKeyApi from '@/api/system/api-key'
import { datetimeFormat } from '@/utils/time'
import { MsgSuccess, MsgConfirm } from '@/utils/message'
import { t } from '@/locales'
import SettingAPIKeyDialog from '@/views/application-overview/component/SettingAPIKeyDrawer.vue'

const route = useRoute()
const {
  params: { id },
} = route

const props = defineProps({
  userId: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['addData'])

const apiUrl = window.location.origin + `${window.MaxKB.prefix}/api-doc/`
const SettingAPIKeyDialogRef = ref()
const dialogVisible = ref<boolean>(false)
const loading = ref(false)
const apiKey = ref<any>(null)

const paginationConfig = reactive({
  current_page: 1,
  page_size: 20,
  total: 0,
})

watch(dialogVisible, (bool) => {
  if (!bool) {
    apiKey.value = null
  }
})

function handleSizeChange() {
  paginationConfig.current_page = 1
  getApiKeyList()
}

function settingApiKey(row: any) {
  SettingAPIKeyDialogRef.value.open(row, 'USER')
}

function deleteApiKey(row: any) {
  MsgConfirm(
    `${t('views.applicationOverview.appInfo.APIKeyDialog.msgConfirm1')}: ${row.secret_key}?`,
    t(t('views.applicationOverview.appInfo.APIKeyDialog.msgConfirm2')),
    {
      confirmButtonText: t('common.confirm'),
      cancelButtonText: t('common.cancel'),
      confirmButtonClass: 'danger',
    },
  )
    .then(() => {
      systemKeyApi.delAPIKey(row.id, loading).then(() => {
        MsgSuccess(t('common.deleteSuccess'))
        getApiKeyList()
      })
    })
    .catch(() => {})
}

function changeState(bool: boolean, row: any) {
  const obj = {
    is_active: bool,
  }
  const str = bool ? t('common.status.enabled') : t('common.status.disabled')
  systemKeyApi.putAPIKey(row.id, obj, loading).then((res) => {
    MsgSuccess(str)
    getApiKeyList()
  })
}

function createApiKey() {
  // systemKeyApi.postAPIKey(loading).then((res) => {
  //   getApiKeyList()
  // })
  SettingAPIKeyDialogRef.value.open(null, 'USER')
}

const open = () => {
  getApiKeyList()
  dialogVisible.value = true
}

function getApiKeyList() {
  systemKeyApi.getAPIKey().then((res) => {
    res.data.sort((x: any, y: any) => (x.name < y.name ? 1 : -1))
    apiKey.value = res.data
  })
}

function refresh() {
  getApiKeyList()
}

defineExpose({ open })
</script>
<style lang="scss" scope></style>
