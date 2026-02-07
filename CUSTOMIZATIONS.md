# MaxKB-2507 客製化記錄

> 原 fork 基於 v1.10.4，以下為 21 個自訂 commit 的完整記錄
> 備份位置：`/Users/bigwoo/repos/MaxKB-2507.zip`

---

## 分類一：開發工具設定（升級後可直接重建，不急）

| # | Commit | 說明 | 檔案 |
|---|--------|------|------|
| 1 | `6eb9655` | CLAUDE.md — 專案開發指導文件 | `CLAUDE.md` |
| 2 | `33569c9` | Claude Code settings — Bash 指令權限 | `.claude/settings.json` |
| 3 | `af14d18` | Claude Code settings — 新增 grep/rg 權限 | `.claude/settings.json` |
| 4 | `1a9484f` | Claude Code settings — 新增 npx eslint 權限 | `.claude/settings.local.json` |
| 5 | `9791d6e` | .gitattributes — 換行符與二進位檔設定 | `.gitattributes` |
| 6 | `353b938` | .gitignore — 新增忽略規則 | `.gitignore` |

**結論：** 升級後重新建立即可，不影響功能。

---

## 分類二：部署腳本（可能需要更新適配 v2）

| # | Commit | 說明 | 檔案 |
|---|--------|------|------|
| 7 | `9fd495f` | 本地開發部署腳本 + 容器管理工具 | `deploy-local.bat`, `docker-compose-local.yml` 等 |
| 8 | `a02ca87` | deploy-local.bat 改用 `npm run build-only` | `deploy-local.bat` |
| 9 | `887bcc8` | MaxKB VM 部署腳本 (PowerShell) | `deploy-to-vm.ps1` |
| 10 | `d66cf8b` | Dockerfile Node.js 設定優化 | `installer/Dockerfile`, `ui/package.json` |
| 11 | `28bbcca` | Dockerfile max-old-space 從 8192 降為 4096 | `installer/Dockerfile`, `ui/package.json` |

**結論：** v2.6.0 的 Dockerfile 可能已不同，需要重新評估。部署腳本可參考舊版重寫。

---

## 分類三：品牌客製化 ⭐

| # | Commit | 說明 | 檔案 |
|---|--------|------|------|
| 12 | `dfc2dfc` | 將 `VITE_APP_TITLE` 從 "MaxKB" 改為 **"MindUP AI"** | `ui/env/.env` |

**結論：** 升級後需重新套用，只改一個 env 變數，30 秒搞定。

---

## 分類四：URL 參數同步功能 ⭐⭐（核心客製功能）

| # | Commit | 說明 | 主要檔案 |
|---|--------|------|----------|
| 13 | `1d0ec15` | 新增 `useChatUrlSync` composable | `ui/src/views/chat/composables/useChatUrlSync.ts` |
| 14 | `1876469` | AiChat 組件整合 URL sync、滾動條修正 | `ui/src/components/ai-chat/index.vue`, 多個 chat view 檔案 |
| 15 | `4bdc473` | URL sync 除錯日誌、chat_id/form_id 邏輯調整 | 同上 |
| 16 | `2bc4120` | URL sync 優化、錯誤處理、form_id 載入後處理 | `ui/src/views/chat/` 多個檔案 |

**功能描述：**
在嵌入式對話頁面的 URL 中同步 `chat_id` 和 `form_id` 參數，讓使用者可以透過 URL 直接跳到特定對話或表單。包含：
- `useChatUrlSync.ts` — URL ↔ State 雙向同步
- 錯誤處理與重試機制
- 表單載入後自動處理 form_id

**結論：** 這是核心客製功能。v2.6.0 的 chat 頁面已大改，需要評估 v2 是否已內建類似功能，若無則需重新實作。

---

## 分類五：UI 元件優化

| # | Commit | 說明 | 檔案 |
|---|--------|------|------|
| 17 | `9cc1e66` | MultiSelectConstructor 新增 collapse-tags | `ui/src/components/dynamics-form/constructor/items/MultiSelectConstructor.vue` |
| 18 | `afc9ff6` | MultiSelect 新增 collapse-tags-tooltip | `ui/src/components/dynamics-form/items/select/MultiSelect.vue` |
| 19 | `836f871` | TextInput 改為 textarea + autosize | `ui/src/components/dynamics-form/items/TextInput.vue` |

**結論：** 小改動，v2.6.0 可能已有類似優化。升級後檢查是否仍需要即可。

---

## 升級後待辦清單

- [ ] 檢查 v2.6.0 chat 頁面是否已支援 URL 參數同步（分類四）
- [ ] 重新套用 `VITE_APP_TITLE = "MindUP AI"`（分類三）
- [ ] 檢查 dynamics-form 元件是否已有 collapse-tags（分類五）
- [ ] 重建 CLAUDE.md 和 .claude/ 設定（分類一）
- [ ] 評估 Dockerfile 與部署腳本是否需要更新（分類二）
- [ ] 本地部署測試
