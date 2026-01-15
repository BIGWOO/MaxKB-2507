<template>
  <el-drawer
    :title="isCreate ? $t('common.create') : $t('common.setting') + ' API Key'"
    v-model="dialogVisible"
    :close-on-click-modal="false"
    :close-on-press-escape="false"
    :append-to-body="true"
    size="60%"
  >
    <el-form label-position="top" ref="settingFormRef" :model="form">
      <el-form-item label="API KEY">
        <div class="complex-search flex align-center w-full">
          <el-input v-model="form.name"> </el-input>
          <el-tooltip :content="$t('common.copy')" placement="top">
            <el-button text>
              <AppIcon iconName="app-copy" class="color-secondary"></AppIcon>
            </el-button>
          </el-tooltip>
        </div>
      </el-form-item>
      <el-form-item
        :label="$t('layout.about.expiredTime')"
        prop="expiredTimeType"
        :rules="{
          required: true,
          message: $t('common.selectPlaceholder'),
          trigger: 'change',
        }"
      >
        <el-select
          :teleported="false"
          v-model="form.expiredTimeType"
          @change="changeExpiredTimeHandle"
        >
          <el-option
            v-for="(option, value) of expiredTimeList"
            :key="value"
            :label="option"
            :value="value"
          />
        </el-select>
      </el-form-item>
      <el-form-item v-if="form.expiredTimeType === 'custom'">
        <el-date-picker
          v-model="form.expired_time"
          type="datetime"
          format="YYYY-MM-DD hh:mm:ss"
          value-format="x"
          style="width: 100%"
          :placeholder="$t('common.selectPlaceholder')"
        />
      </el-form-item>
      <el-form-item :label="$t('layout.crossSettings')" @click.prevent>
        <el-switch size="small" v-model="form.allow_cross_domain"></el-switch>
      </el-form-item>
      <el-form-item v-if="form.allow_cross_domain">
        <el-input
          v-model="form.cross_domain_list"
          :placeholder="
            $t('views.applicationOverview.appInfo.SettingAPIKeyDialog.crossDomainPlaceholder')
          "
          :rows="10"
          type="textarea"
        />
      </el-form-item>
      <el-form-item :label="$t('views.document.enableStatus.label')" @click.prevent>
        <el-switch size="small" v-model="form.allow_cross_domain"></el-switch>
      </el-form-item>
    </el-form>
    <template #footer>
      <span class="dialog-footer">
        <el-button @click.prevent="dialogVisible = false">{{ $t('common.cancel') }}</el-button>
        <el-button type="primary" @click="submit(settingFormRef)" :loading="loading">
          {{ isCreate ? $t('common.create') : $t('common.save') }}
        </el-button>
      </span>
    </template>
  </el-drawer>
</template>
<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import overviewSystemApi from '@/api/system/api-key'
import { MsgSuccess } from '@/utils/message'
import { t } from '@/locales'
import { loadSharedApi } from '@/utils/dynamics-api/shared-api'
import { expiredTimeList, AfterTimestamp } from '@/utils/time'

const route = useRoute()
const {
  params: { id },
} = route

const apiType = computed(() => {
  if (route.path.includes('resource-management')) {
    return 'systemManage'
  } else {
    return 'workspace'
  }
})

const emit = defineEmits(['refresh'])

const settingFormRef = ref()
const form = ref<any>({
  name: '',
  allow_cross_domain: false,
  cross_domain_list: '',
  expired_time: '',
  expiredTimeType: 'never',
})

const dialogVisible = ref<boolean>(false)
const loading = ref(false)

const APIKeyId = ref('')
const APIType = ref('APPLICATION')
const isCreate = ref(false)

watch(dialogVisible, (bool) => {
  if (!bool) {
    form.value = {
      allow_cross_domain: false,
      cross_domain_list: '',
    }
  }
})

const open = (data: any, type: string) => {
  if (data) {
    isCreate.value = false
    APIKeyId.value = data.id
    form.value.allow_cross_domain = data.allow_cross_domain
    form.value.cross_domain_list = data.cross_domain_list?.length
      ? data.cross_domain_list?.join('\n')
      : ''
  } else {
    isCreate.value = true
  }
  APIType.value = type
  dialogVisible.value = true
}

const submit = async (formEl: FormInstance | undefined) => {
  if (!formEl) return
  await formEl.validate((valid, fields) => {
    if (valid) {
      const obj = {
        allow_cross_domain: form.value.allow_cross_domain,
        cross_domain_list: form.value.cross_domain_list
          ? form.value.cross_domain_list.split('\n').filter(function (item: string) {
              return item !== ''
            })
          : [],
      }

      const apiCall =
        APIType.value === 'APPLICATION'
          ? loadSharedApi({ type: 'applicationKey', systemType: apiType.value }).putAPIKey(
              id as string,
              APIKeyId.value,
              obj,
              loading,
            )
          : overviewSystemApi.putAPIKey(APIKeyId.value, obj, loading)

      apiCall.then(() => {
        emit('refresh')

        MsgSuccess(t('common.settingSuccess'))
        dialogVisible.value = false
      })
    }
  })
}

function changeExpiredTimeHandle(value: string) {
  if (value === 'custom') {
    form.value.expired_time = ''
  } else if (value === 'never') {
    form.value.expired_time = null
  } else {
    form.value.expired_time = AfterTimestamp(value)
  }
}

defineExpose({ open })
</script>
<style lang="scss" scoped></style>
