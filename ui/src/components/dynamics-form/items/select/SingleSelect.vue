<template>
  <el-select
    ref="selectRef"
    :filterable="!isMobile"
    :readonly="isMobile"
    :teleported="true"
    :popper-class="popperClass"
    :popper-options="popperOptions"
    :input-style="inputStyle"
    clearable
    v-bind="$attrs"
    v-model="_modelValue"
    @visible-change="handleVisibleChange"
    @focus="handleFocus"
    @touchstart="handleTouchStart"
    @touchend="handleTouchEnd"
  >
    <el-option
      v-for="(item, index) in option_list"
      :key="index"
      teleported
      :label="label(item)"
      :value="item[valueField]"
    >
    </el-option>
  </el-select>
</template>
<script setup lang="ts">
import type { FormField } from '@/components/dynamics-form/type'
import { computed, ref, nextTick } from 'vue'
import useStore from '@/stores'

const { common } = useStore()
const selectRef = ref()
const touchStartTime = ref(0)

const props = defineProps<{
  modelValue?: string
  formValue?: any
  formfieldList?: Array<FormField>
  field: string
  otherParams: any
  formField: FormField
  view?: boolean
}>()

const emit = defineEmits(['update:modelValue', 'change'])

const _modelValue = computed({
  get() {
    return props.modelValue
  },
  set(value) {
    emit('update:modelValue', value)
    emit('change', props.formField)
  }
})
const textField = computed(() => {
  return props.formField.text_field ? props.formField.text_field : 'key'
})

const valueField = computed(() => {
  return props.formField.value_field ? props.formField.value_field : 'value'
})

const option_list = computed(() => {
  return props.formField.option_list ? props.formField.option_list : []
})

// 移動設備檢測
const isMobile = computed(() => common.isMobile())

// 移動端樣式和配置
const inputStyle = computed(() => 
  isMobile.value ? { cursor: 'pointer', caretColor: 'transparent' } : {}
)

const popperClass = computed(() => 
  isMobile.value ? 'dynamics-single-select mobile-optimized' : 'dynamics-single-select'
)

const popperOptions = computed(() => {
  if (!isMobile.value) return {}
  
  return {
    strategy: 'fixed',
    placement: 'top', // 改為 top 避免初始的 bottom 定位
    modifiers: [
      {
        name: 'flip',
        enabled: false
      },
      {
        name: 'preventOverflow', 
        enabled: false
      },
      {
        name: 'offset',
        enabled: false // 完全禁用 offset
      },
      {
        name: 'computeStyles',
        enabled: false // 完全禁用計算樣式
      },
      {
        name: 'applyStyles',
        enabled: false // 禁用應用樣式，避免初始定位
      },
      {
        name: 'centerPosition',
        enabled: true,
        phase: 'beforeWrite',
        fn: ({ state }: { state: any }) => {
          // 直接設置為螢幕中央，跳過所有 Popper 計算
          state.styles.popper = {
            position: 'fixed',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            zIndex: '9999'
          }
        }
      }
    ]
  }
})

// 移動端事件處理
const handleTouchStart = () => {
  if (isMobile.value) {
    touchStartTime.value = Date.now()
  }
}

const handleTouchEnd = (event: TouchEvent) => {
  if (!isMobile.value) return
  
  const touchDuration = Date.now() - touchStartTime.value
  
  // 短觸控視為點擊
  if (touchDuration < 200) {
    event.preventDefault()
    
    nextTick(() => {
      if (selectRef.value && !selectRef.value.visible) {
        selectRef.value.toggleMenu()
      }
    })
  }
}

const handleFocus = (event: FocusEvent) => {
  if (isMobile.value) {
    // 阻止輸入框獲得焦點，避免鍵盤彈出
    ;(event.target as HTMLInputElement).blur()
  }
}

const handleVisibleChange = (visible: boolean) => {
  if (visible && isMobile.value) {
    // 立即設置中央定位，避免跳動
    const setImmediatePosition = () => {
      const dropdown = document.querySelector('.mobile-optimized .el-select-dropdown') as HTMLElement
      if (dropdown) {
        // 根據螢幕尺寸設置最大高度，讓內容自適應
        const screenHeight = window.innerHeight
        let maxHeight = '75vh'
        
        if (screenHeight <= 667) {
          maxHeight = '55vh' // 小螢幕適當減少
        } else if (screenHeight >= 900) {
          maxHeight = '70vh' // 超大螢幕
        } else if (screenHeight >= 800) {
          maxHeight = '65vh' // 較大螢幕
        } else {
          maxHeight = '60vh' // 一般螢幕
        }
        
        // 立即強制中央定位，覆蓋 Popper 的初始計算
        dropdown.style.cssText = `
          position: fixed !important;
          top: 50% !important;
          left: 50% !important;
          right: auto !important;
          bottom: auto !important;
          transform: translate(-50%, -50%) !important;
          z-index: 9999 !important;
          max-height: ${maxHeight} !important;
          height: auto !important;
          opacity: 0;
        `
        
        // 同時設置內層容器的高度
        const wrap = dropdown.querySelector('.el-select-dropdown__wrap') as HTMLElement
        if (wrap) {
          wrap.style.setProperty('max-height', 'inherit', 'important')
          wrap.style.setProperty('height', 'auto', 'important')
        }
        
        const scrollbar = dropdown.querySelector('.el-scrollbar') as HTMLElement
        if (scrollbar) {
          scrollbar.style.setProperty('max-height', 'inherit', 'important')
          scrollbar.style.setProperty('height', 'auto', 'important')
          
          const scrollWrap = scrollbar.querySelector('.el-scrollbar__wrap') as HTMLElement
          if (scrollWrap) {
            scrollWrap.style.setProperty('max-height', 'inherit', 'important')
          }
        }
        
        // 短暫延遲後顯示，確保位置已正確設置
        setTimeout(() => {
          dropdown.style.opacity = '1'
        }, 10)
      }
    }
    
    // 同時在多個時機執行，確保覆蓋 Popper 的定位
    setImmediatePosition()
    setTimeout(setImmediatePosition, 0)
    nextTick(setImmediatePosition)
  }
}

const label = (option: any) => {
  //置空
  if (props.modelValue && option_list.value) {
    const oldItem = option_list.value.find((item) => item[valueField.value] === props.modelValue)
    if (!oldItem) {
      emit('update:modelValue', undefined)
    }
  }

  return option[textField.value]
}
</script>
<style lang="scss">
.dynamics-single-select {
  .el-select-dropdown {
    max-width: 1px;
  }
  
  // 移動設備專用樣式 - 中央展開設計
  &.mobile-optimized {
    .el-select-dropdown {
      // 螢幕中央定位
      position: fixed !important;
      top: 50% !important;
      left: 50% !important;
      right: auto !important;
      bottom: auto !important;
      transform: translate(-50%, -50%) !important;
      margin: 0 !important;
      
      // 尺寸控制 - 響應式高度
      width: 85vw !important;
      max-width: 400px !important;
      min-width: 280px !important;
      
      // 動態高度：上下各留 10% 空間，方便點擊背景關閉
      height: auto !important;
      max-height: 60vh !important; // 80vh - 20vh(上下各10%) = 60vh
      
      // 特殊螢幕尺寸優化
      @media (max-height: 667px) { // iPhone SE/8 等較矮螢幕
        max-height: 55vh !important; // 較小螢幕適當減少
      }
      
      @media (min-height: 800px) { // 較高螢幕如 iPhone 14 Pro Max
        max-height: 65vh !important; // 較大螢幕可以稍微增加
      }
      
      @media (min-height: 900px) { // 超高螢幕
        max-height: 70vh !important; // 超大螢幕的上限
      }
      
      // 層級控制
      z-index: 9999 !important;
      
      // 背景和視覺效果
      background: #ffffff !important;
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      
      // 現代化設計
      border: none !important;
      border-radius: 16px !important;
      box-shadow: 
        0 25px 50px -12px rgba(0, 0, 0, 0.25),
        0 10px 25px -5px rgba(0, 0, 0, 0.1),
        0 0 0 1px rgba(255, 255, 255, 0.9) inset !important;
      
      // 滾動優化 - 確保內容過多時可滾動
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
      
      // 內容佈局：自適應高度，不強制最小高度
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      
      // 讓內容自然擴展，避免空白區域
      min-height: fit-content !important;
      
      // 覆蓋 Element Plus 內層容器的高度限制
      .el-select-dropdown__wrap {
        max-height: inherit !important; // 繼承外層的 max-height
        height: auto !important;
      }
      
      // 確保內層滾動容器也沒有高度限制
      .el-scrollbar {
        height: auto !important;
        max-height: inherit !important;
        
        .el-scrollbar__wrap {
          max-height: inherit !important;
        }
        
        .el-scrollbar__view {
          height: auto !important;
        }
      }
      
      // 中央展開動畫（移除初始的透明度動畫，改用 JavaScript 控制）
      animation: mobileCenterExpand 0.4s cubic-bezier(0.16, 1, 0.3, 1) !important;
      
      // 確保一開始就在中央，避免跳動
      top: 50% !important;
      left: 50% !important;
      transform: translate(-50%, -50%) !important;
      
      .el-select-dropdown__item {
        // 觸控區域優化 - 響應式觸控區域
        padding: 20px 24px !important;
        min-height: 60px !important;
        
        // 小螢幕優化
        @media (max-height: 667px) {
          padding: 16px 20px !important;
          min-height: 52px !important;
        }
        
        // 大螢幕增強體驗
        @media (min-height: 800px) {
          padding: 24px 28px !important;
          min-height: 64px !important;
        }
        
        @media (min-height: 900px) {
          padding: 28px 32px !important;
          min-height: 68px !important;
        }
        
        // 背景設置
        background-color: transparent !important;
        
        // 現代化分隔線
        border-bottom: 1px solid rgba(0, 0, 0, 0.04);
        margin: 0 16px;
        
        // 字體樣式
        color: #1f2937 !important;
        font-size: 17px;
        font-weight: 400;
        line-height: 1.4;
        
        // 觸控反饋動畫
        transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        border-radius: 12px;
        
        // 觸控狀態
        &:hover, &:active {
          background-color: #f1f5f9 !important;
          color: #0f172a !important;
          transform: scale(1.02);
        }
        
        // 選中狀態
        &.selected {
          background-color: #eff6ff !important;
          color: #2563eb !important;
          font-weight: 500;
          
          &::after {
            content: '✓';
            float: right;
            color: #2563eb;
            font-weight: bold;
            font-size: 20px;
          }
        }
        
        // 第一項和最後一項特殊樣式
        &:first-child {
          margin-top: 8px;
          border-top-left-radius: 12px;
          border-top-right-radius: 12px;
        }
        
        &:last-child {
          margin-bottom: 8px;
          border-bottom: none;
          border-bottom-left-radius: 12px;
          border-bottom-right-radius: 12px;
        }
      }
      
      // 滾動條美化
      &::-webkit-scrollbar {
        width: 6px;
      }
      
      &::-webkit-scrollbar-track {
        background: rgba(0, 0, 0, 0.05);
        border-radius: 3px;
      }
      
      &::-webkit-scrollbar-thumb {
        background: linear-gradient(180deg, #cbd5e1, #94a3b8);
        border-radius: 3px;
        
        &:hover {
          background: linear-gradient(180deg, #94a3b8, #64748b);
        }
      }
      
      // 移除箭頭指示器，改用中央展開設計
    }
  }
}

// 移動設備通用優化
@media only screen and (max-width: 768px) {
  .dynamics-single-select {
    // 確保輸入框本身也適合觸控
    .el-input__wrapper {
      min-height: 44px;
      border-radius: 8px;
      transition: all 0.2s ease;
      
      &:hover {
        box-shadow: 0 0 0 1px #e1e5e9;
      }
      
      &.is-focus {
        box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
        border-color: #3b82f6;
      }
    }
    
    .el-input__inner {
      font-size: 16px; // 防止 iOS 縮放
      line-height: 1.5;
      font-weight: 400;
    }
    
    // 下拉箭頭優化
    .el-input__suffix {
      .el-icon {
        transition: transform 0.3s ease;
      }
    }
    
    // 移動端不需要箭頭動畫，已經改用中央展開
  }
}

// 中央展開動畫效果
.dynamics-single-select.mobile-optimized {
  .el-select-dropdown {
    .el-select-dropdown__item {
      // 選項依序出現動畫
      opacity: 0;
      animation: centerItemFadeIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
      
      @for $i from 1 through 12 {
        &:nth-child(#{$i}) {
          animation-delay: #{0.1 + ($i - 1) * 0.03}s;
        }
      }
    }
  }
}

// 動畫關鍵幀
@keyframes mobileCenterExpand {
  from {
    transform: translate(-50%, -50%) scale(0.8);
    filter: blur(8px);
  }
  50% {
    transform: translate(-50%, -50%) scale(1.02);
    filter: blur(3px);
  }
  to {
    transform: translate(-50%, -50%) scale(1);
    filter: blur(0px);
  }
}

@keyframes centerItemFadeIn {
  from {
    opacity: 0;
    transform: translateY(15px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}
</style>
