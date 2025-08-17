<template>
  <!-- 移動端：使用 checkbox 列表 -->
  <div v-if="isMobile" class="mobile-multi-select">
    <!-- 已選擇的項目顯示 -->
    <div class="selected-display" @click="showOptions = !showOptions">
      <div class="selected-content">
        <div class="selected-tags" v-if="modelValue && modelValue.length > 0">
          <el-tag
            v-for="value in modelValue.slice(0, 3)"
            :key="value"
            size="small"
            closable
            @close="removeSelection(value)"
          >
            {{ getDisplayText(value) }}
          </el-tag>
          <el-tag v-if="modelValue.length > 3" size="small">
            +{{ modelValue.length - 3 }}
          </el-tag>
        </div>
        <div v-else class="placeholder">請選擇</div>
      </div>
      <el-icon class="dropdown-icon" :class="{ 'rotate': showOptions }">
        <ArrowDown />
      </el-icon>
    </div>
    
    <!-- 選項列表 -->
    <div v-show="showOptions" class="options-panel">
      <div class="options-header">
        <span>請選擇項目</span>
        <el-button text @click="showOptions = false">
          <el-icon><Close /></el-icon>
        </el-button>
      </div>
      
      <div class="options-list">
        <div
          v-for="(item, index) in option_list"
          :key="index"
          class="option-item"
          @click="toggleSelection(item[valueField])"
        >
          <div class="option-text">{{ label(item) }}</div>
          <el-checkbox 
            :model-value="isSelected(item[valueField])"
            @click.stop
          />
        </div>
      </div>
      
      <div class="options-footer">
        <el-button @click="clearAll">清除全部</el-button>
        <el-button type="primary" @click="confirmAndClose">
          確認選擇 ({{ (modelValue || []).length }})
        </el-button>
      </div>
    </div>
    
    <!-- 背景遮罩 -->
    <div v-show="showOptions" class="options-overlay" @click="showOptions = false"></div>
  </div>
  
  <!-- 桌面端：保持原有的下拉選單 -->
  <el-select
    v-else
    class="m-2"
    multiple
    collapse-tags
    collapse-tags-tooltip
    :max-collapse-tags="3"
    filterable
    clearable
    v-bind="$attrs"
    :model-value="modelValue"
    @update:model-value="handleUpdate"
  >
    <el-option
      v-for="(item, index) in option_list"
      :key="index"
      :label="label(item)"
      :value="item[valueField]"
    >
    </el-option>
  </el-select>
</template>

<script setup lang="ts">
import type { FormField } from '@/components/dynamics-form/type'
import { computed, ref } from 'vue'
import { ArrowDown, Close } from '@element-plus/icons-vue'
import useStore from '@/stores'

const { common } = useStore()

const props = defineProps<{
  modelValue?: Array<any>
  formValue?: any
  formfieldList?: Array<FormField>
  field: string
  otherParams: any
  formField: FormField
  view?: boolean
}>()

const emit = defineEmits(['update:modelValue', 'change'])

// 移動端顯示選項狀態
const showOptions = ref(false)

// 移動設備檢測
const isMobile = computed(() => common.isMobile())

const textField = computed(() => {
  return props.formField.text_field ? props.formField.text_field : 'key'
})

const valueField = computed(() => {
  return props.formField.value_field ? props.formField.value_field : 'value'
})

const option_list = computed(() => {
  return props.formField.option_list ? props.formField.option_list : []
})

const label = (option: any) => {
  return option[textField.value]
}

// 處理數值更新
const handleUpdate = (value: Array<any>) => {
  emit('update:modelValue', value)
  emit('change', props.formField)
}

// 獲取顯示文字
const getDisplayText = (value: any) => {
  const option = option_list.value.find(item => item[valueField.value] === value)
  return option ? option[textField.value] : value
}

// 檢查是否已選擇
const isSelected = (value: any) => {
  return (props.modelValue || []).includes(value)
}

// 切換選擇狀態
const toggleSelection = (value: any) => {
  const currentValues = [...(props.modelValue || [])]
  const index = currentValues.indexOf(value)
  
  if (index > -1) {
    currentValues.splice(index, 1)
  } else {
    currentValues.push(value)
  }
  
  handleUpdate(currentValues)
}

// 移除選擇
const removeSelection = (value: any) => {
  const currentValues = [...(props.modelValue || [])]
  const index = currentValues.indexOf(value)
  
  if (index > -1) {
    currentValues.splice(index, 1)
    handleUpdate(currentValues)
  }
}

// 清除全部
const clearAll = () => {
  handleUpdate([])
}

// 確認並關閉
const confirmAndClose = () => {
  showOptions.value = false
}
</script>

<style lang="scss">
.mobile-multi-select {
  position: relative;
  
  .selected-display {
    min-height: 44px;
    padding: 8px 12px;
    border: 1px solid #dcdfe6;
    border-radius: 8px;
    background: #fff;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    transition: all 0.2s ease;
    
    &:hover {
      border-color: #c0c4cc;
    }
    
    .selected-content {
      flex: 1;
      min-width: 0;
      
      .selected-tags {
        display: flex;
        flex-wrap: wrap;
        gap: 4px;
        
        .el-tag {
          border-radius: 4px;
          font-size: 12px;
          padding: 2px 6px;
        }
      }
      
      .placeholder {
        color: #c0c4cc;
        font-size: 14px;
      }
    }
    
    .dropdown-icon {
      margin-left: 8px;
      transition: transform 0.3s ease;
      color: #c0c4cc;
      
      &.rotate {
        transform: rotate(180deg);
      }
    }
  }
  
  .options-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 9998;
  }
  
  .options-panel {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 90vw;
    max-width: 400px;
    max-height: 70vh;
    background: #fff;
    border-radius: 12px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
    z-index: 9999;
    display: flex;
    flex-direction: column;
    
    .options-header {
      padding: 16px 20px;
      border-bottom: 1px solid #f0f0f0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      
      span {
        font-weight: 600;
        font-size: 16px;
        color: #333;
      }
    }
    
    .options-list {
      flex: 1;
      overflow-y: auto;
      padding: 8px 0;
      
      .option-item {
        padding: 16px 20px;
        border-bottom: 1px solid #f8f8f8;
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 12px;
        cursor: pointer;
        transition: background-color 0.2s ease;
        
        &:hover {
          background-color: #f5f7fa;
        }
        
        &:last-child {
          border-bottom: none;
        }
        
        .option-text {
          flex: 1;
          font-size: 15px;
          line-height: 1.4;
          color: #333;
          word-wrap: break-word;
          word-break: break-word;
        }
        
        .el-checkbox {
          flex-shrink: 0;
          margin-top: 2px;
        }
      }
    }
    
    .options-footer {
      padding: 16px 20px;
      border-top: 1px solid #f0f0f0;
      display: flex;
      gap: 12px;
      
      .el-button {
        flex: 1;
        height: 44px;
        border-radius: 8px;
        font-size: 15px;
        font-weight: 500;
      }
    }
  }
}

// 桌面端保持原有樣式
.dynamics-multi-select {
  .el-select-dropdown {
    max-width: 300px;
  }
}
</style>
