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
import { computed, ref, nextTick, useAttrs } from 'vue'
import useStore from '@/stores'

const { common } = useStore()
const attrs = useAttrs() as any
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
  },
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
    placement: 'top',
    modifiers: [
      { name: 'flip', enabled: false },
      { name: 'preventOverflow', enabled: false },
      { name: 'offset', enabled: false },
      { name: 'computeStyles', enabled: false },
      { name: 'applyStyles', enabled: false },
      {
        name: 'centerPosition',
        enabled: true,
        phase: 'beforeWrite',
        fn: ({ state }: any) => {
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
    ;(event.target as HTMLInputElement).blur()
  }
}

const handleVisibleChange = (visible: boolean) => {
  if (visible && isMobile.value) {
    const setImmediatePosition = () => {
      const dropdown = document.querySelector('.mobile-optimized .el-select-dropdown') as HTMLElement
      if (dropdown) {
        const screenHeight = window.innerHeight
        let maxHeight = '60vh'
        if (screenHeight <= 667) maxHeight = '55vh'
        else if (screenHeight >= 900) maxHeight = '70vh'
        else if (screenHeight >= 800) maxHeight = '65vh'
        
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
        
        setTimeout(() => { dropdown.style.opacity = '1' }, 10)
      }
    }
    
    setImmediatePosition()
    setTimeout(setImmediatePosition, 0)
    nextTick(setImmediatePosition)
  }
}

const label = (option: any) => {
  if (props.modelValue && option_list.value && !attrs['allow-create']) {
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
  
  &.mobile-optimized {
    .el-select-dropdown {
      position: fixed !important;
      top: 50% !important;
      left: 50% !important;
      right: auto !important;
      bottom: auto !important;
      transform: translate(-50%, -50%) !important;
      margin: 0 !important;
      
      width: 85vw !important;
      max-width: 400px !important;
      min-width: 280px !important;
      height: auto !important;
      max-height: 60vh !important;
      
      @media (max-height: 667px) { max-height: 55vh !important; }
      @media (min-height: 800px) { max-height: 65vh !important; }
      @media (min-height: 900px) { max-height: 70vh !important; }
      
      z-index: 9999 !important;
      background: #ffffff !important;
      border: none !important;
      border-radius: 16px !important;
      box-shadow: 
        0 25px 50px -12px rgba(0, 0, 0, 0.25),
        0 10px 25px -5px rgba(0, 0, 0, 0.1),
        0 0 0 1px rgba(255, 255, 255, 0.9) inset !important;
      
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      min-height: fit-content !important;
      
      animation: mobileCenterExpand 0.4s cubic-bezier(0.16, 1, 0.3, 1) !important;
      padding: 12px 0 !important;
      
      .el-select-dropdown__wrap {
        max-height: inherit !important;
        height: auto !important;
      }
      
      .el-scrollbar {
        height: auto !important;
        max-height: inherit !important;
        .el-scrollbar__wrap { max-height: inherit !important; }
        .el-scrollbar__view { height: auto !important; }
      }
      
      .el-select-dropdown__item {
        padding: 20px 24px !important;
        min-height: 60px !important;
        
        @media (max-height: 667px) { padding: 16px 20px !important; min-height: 52px !important; }
        @media (min-height: 800px) { padding: 24px 28px !important; min-height: 64px !important; }
        
        background-color: transparent !important;
        border-bottom: 1px solid rgba(0, 0, 0, 0.04);
        margin: 0 16px;
        color: #1f2937 !important;
        font-size: 17px;
        font-weight: 400;
        line-height: 1.4;
        transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        border-radius: 12px;
        
        &:hover, &:active {
          background-color: #f1f5f9 !important;
          color: #0f172a !important;
          transform: scale(1.02);
        }
        
        &.selected {
          background-color: #eff6ff !important;
          color: #2563eb !important;
          font-weight: 500;
          &::after { content: '✓'; float: right; color: #2563eb; font-weight: bold; font-size: 20px; }
        }
        
        &:first-child { margin-top: 8px; }
        &:last-child { margin-bottom: 8px; border-bottom: none; }
      }
      
      &::-webkit-scrollbar { width: 6px; }
      &::-webkit-scrollbar-track { background: rgba(0, 0, 0, 0.05); border-radius: 3px; }
      &::-webkit-scrollbar-thumb { background: linear-gradient(180deg, #cbd5e1, #94a3b8); border-radius: 3px; }
    }
  }
}

@media only screen and (max-width: 768px) {
  .dynamics-single-select {
    .el-input__wrapper { min-height: 44px; border-radius: 8px; }
    .el-input__inner { font-size: 16px; line-height: 1.5; }
  }
}

.dynamics-single-select.mobile-optimized .el-select-dropdown .el-select-dropdown__item {
  opacity: 0;
  animation: centerItemFadeIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  @for $i from 1 through 12 {
    &:nth-child(#{$i}) { animation-delay: #{0.1 + ($i - 1) * 0.03}s; }
  }
}

@keyframes mobileCenterExpand {
  from { transform: translate(-50%, -50%) scale(0.8); filter: blur(8px); }
  50% { transform: translate(-50%, -50%) scale(1.02); filter: blur(3px); }
  to { transform: translate(-50%, -50%) scale(1); filter: blur(0px); }
}

@keyframes centerItemFadeIn {
  from { opacity: 0; transform: translateY(15px) scale(0.95); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
</style>
