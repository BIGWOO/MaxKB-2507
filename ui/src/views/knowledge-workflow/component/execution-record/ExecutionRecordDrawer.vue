<template>
  <el-drawer
    v-model="drawer"
    :title="$t('workflow.ExecutionRecord')"
    direction="rtl"
    size="800px"
    :before-close="close"
  >
    <div class="flex mb-16">
      <div class="flex-between complex-search">
        <el-select
          v-model="filter_type"
          class="complex-search__left"
          @change="changeFilterHandle"
          style="width: 120px"
        >
          <el-option :label="$t('workflow.initiator')" value="user_name" />
        </el-select>
        <!-- <el-select
          v-if="filter_type === 'status'"
          v-model="filter_status"
          @change="changeStatusHandle"
          style="width: 220px"
          clearable
        >
          <el-option
            v-for="item in statusOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select> -->
        <el-input
          v-model="query.user_name"
          @change="getList"
          :placeholder="$t('common.search')"
          prefix-icon="Search"
          style="width: 220px"
          clearable
        />
      </div>
    </div>

    <app-table-infinite-scroll
      :data="data"
      class="w-full"
      v-loading="loading"
      @changePage="changePage"
      :maxTableHeight="150"
      :paginationConfig="paginationConfig"
    >
      <el-table-column prop="user_name" :label="$t('workflow.initiator')">
        <template #default="{ row }">
          {{ row.meta.user_name }}
        </template>
      </el-table-column>
      <el-table-column prop="state" :label="$t('common.status.label')" width="180">
        <template #default="{ row }">
          <el-text class="color-text-primary" v-if="row.state === 'SUCCESS'">
            <el-icon class="color-success"><SuccessFilled /></el-icon>
            {{ $t('common.status.success') }}
          </el-text>
          <el-text class="color-text-primary" v-else-if="row.state === 'FAILURE'">
            <el-icon class="color-danger"><CircleCloseFilled /></el-icon>
            {{ $t('common.status.fail') }}
          </el-text>
          <el-text class="color-text-primary" v-else>
            <el-icon class="is-loading color-primary"><Loading /></el-icon>
            {{ $t('common.status.padding') }}
          </el-text>
        </template>
      </el-table-column>
      <el-table-column prop="run_time" :label="$t('chat.KnowledgeSource.consumeTime')">
        <template #default="{ row }">
          {{ row.run_time != undefined ? row.run_time + 's' : '-' }}
        </template>
      </el-table-column>
      <el-table-column :label="$t('common.operation')" width="80">
        <template #default="{ row }">
          <el-tooltip effect="dark" :content="$t('chat.executionDetails.title')" placement="top">
            <el-button type="primary" text @click.stop="toDetails(row)">
              <AppIcon iconName="app-operate-log"></AppIcon>
            </el-button>
          </el-tooltip>
        </template>
      </el-table-column>
    </app-table-infinite-scroll>
  </el-drawer>
</template>
<script setup lang="ts">
import { loadSharedApi } from '@/utils/dynamics-api/shared-api'
import AppTableInfiniteScroll from '@/components/app-table-infinite-scroll/index.vue'
import { computed, ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
const drawer = ref<boolean>(false)
const route = useRoute()
const toDetails = (row: any) => {}

const apiType = computed(() => {
  if (route.path.includes('shared')) {
    return 'systemShare'
  } else if (route.path.includes('resource-management')) {
    return 'systemManage'
  } else {
    return 'workspace'
  }
})
const paginationConfig = reactive({
  current_page: 1,
  page_size: 50,
  total: 0,
})
const query = ref<any>({
  user_name: '',
})
const loading = ref(false)
const filter_type = ref<string>('user_name')
const active_knowledge_id = ref<string>('')
const data = ref<Array<any>>([])
const changeFilterHandle = () => {
  query.value = { user_name: '' }
}
const changePage = () => {
  paginationConfig.current_page += 1
  console.log(paginationConfig.current_page)
  getList()
}

const getList = () => {
  loadSharedApi({ type: 'knowledge', systemType: apiType.value })
    .getWorkflowActionPage(active_knowledge_id.value, paginationConfig, query.value, loading)
    .then((ok: any) => {
      paginationConfig.total = ok.data?.total
      data.value = data.value.concat(ok.data.records)
    })
}
const open = (knowledge_id: string) => {
  active_knowledge_id.value = knowledge_id
  getList()
  drawer.value = true
}
const close = () => {
  paginationConfig.current_page = 1
  paginationConfig.total = 0
  data.value = []
  drawer.value = false
}
defineExpose({ open, close })
</script>
<style lang="scss" scoped></style>
