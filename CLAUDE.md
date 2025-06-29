# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

MaxKB 是一個強大易用的企業級 AI 助手，支援 RAG 檢索增強生成、工作流編排、MCP 工具調用能力。這是一個全端應用，包含前端 Vue.js 和後端 Python/Django。

## 核心技術棧

- 前端：Vue.js 3 + Element Plus + TypeScript + Vite
- 後端：Python 3.11 / Django 4.2.20
- LLM 框架：LangChain 0.3.23
- 向量數據庫：PostgreSQL + pgvector
- 任務隊列：Celery with Redis/SQLAlchemy backend
- 依賴管理：Poetry (pyproject.toml)

## 常用命令

### 後端開發
```bash
# 進入 apps 目錄運行 Django 命令
cd apps

# 啟動開發服務器
python manage.py runserver

# 數據庫遷移
python manage.py makemigrations
python manage.py migrate

# 創建超級用戶
python manage.py createsuperuser

# 啟動 Celery worker
python manage.py celery celery
python manage.py celery model

# 運行測試
python manage.py test

# 使用 Poetry 管理依賴
poetry install
poetry add <package>
poetry update
```

### 前端開發
```bash
# 進入 ui 目錄
cd ui

# 安裝依賴
npm install

# 啟動開發服務器
npm run dev

# 構建生產版本
npm run build

# 類型檢查
npm run type-check

# 代碼格式化和檢查
npm run lint
npm run format

# 運行測試
npm run test:unit
```

## 核心架構

### Django Apps 結構
- `application/` - 應用管理，包含聊天流水線和工作流引擎
- `dataset/` - 知識庫和文檔管理
- `embedding/` - 向量嵌入和搜索
- `setting/` - 模型提供者和系統設置
- `function_lib/` - 函數庫管理
- `users/` - 用戶管理
- `common/` - 共享工具和中間件

### 工作流引擎
核心位於 `apps/application/flow/`：
- `workflow_manage.py` - 工作流執行引擎
- `step_node/` - 各種工作流節點實現
- `i_step_node.py` - 節點接口定義

### 模型提供者系統
位於 `apps/setting/models_provider/impl/`，支援多種 LLM 提供者：
- OpenAI、Claude、Gemini 等公共模型
- 阿里云、騰訊、百度等國內模型
- Ollama、本地模型等私有部署

### 向量搜索
- 使用 PostgreSQL + pgvector 進行向量存儲
- 支援混合搜索（向量 + 關鍵詞）
- 核心邏輯在 `apps/embedding/`

## 前端架構

### 主要目錄結構
- `src/views/` - 頁面組件
- `src/components/` - 共享組件
- `src/workflow/` - 工作流可視化編輯器
- `src/api/` - API 接口定義
- `src/stores/` - Pinia 狀態管理

### 工作流編輯器
基於 LogicFlow 實現的可視化工作流編輯器，支援拖拽式節點編排。

## 數據庫配置

默認使用 PostgreSQL，配置在 `apps/smartdoc/settings/base.py`。支援：
- PostgreSQL（推薦，支援 pgvector）
- MySQL（通過 pymysql）

## 部署相關

### 本地開發部署（Windows）
使用提供的 bat 腳本進行快速部署：
```bash
# 首次部署（從本地代碼構建）
./deploy-local.bat

# 修改代碼後重新部署
./redeploy.bat

# 容器管理
./manage-container.bat
```

### Docker 部署
- `installer/` 目錄包含 Docker 相關文件
- 支援單容器部署和分離式部署
- 預設端口：8080
- 容器名稱：maxkb-mindup
- 數據持久化目錄：`C:\maxkb` 和 `C:\python-packages`

### 環境配置
- 配置文件：`config_example.yml`
- 環境變量通過 `apps/smartdoc/const.py` 中的 CONFIG 對象管理
- 預設帳號：admin / MaxKB@123..

## 開發注意事項

### 國際化
- 支援多語言：英文、簡體中文、繁體中文
- 翻譯文件位於 `apps/locales/`
- 前端 i18n 配置在 `ui/src/locales/`

### 安全考量
- API 使用 Token 認證
- 支援跨域配置
- 文件上傳有安全檢查

### 模型集成
添加新的模型提供者時：
1. 在 `apps/setting/models_provider/impl/` 創建新目錄
2. 實現 credential 和 model 類
3. 繼承相應的基類（LLM、Embedding、TTS 等）

### 工作流節點開發
添加新節點類型：
1. 在 `apps/application/flow/step_node/` 創建新節點
2. 實現 `INode` 接口
3. 在前端 `ui/src/workflow/nodes/` 添加對應組件

## 測試
- 後端測試文件以 `tests.py` 命名
- 前端使用 Vitest 進行單元測試
- 集成測試通過 Django 測試框架

## API 文檔
使用 drf-yasg 生成 Swagger 文檔，可通過 `/api/docs/` 訪問。


# 一律使用繁體中文回覆我

# 每次都用批判性思考，仔細找出我輸入的潛在問題

你要指出我的問題，並給出明顯在我思考框架外的建議
如果你覺得我說得太離譜，你就要嚴厲罵我、批判我、吐槽我！
越兇狠越難聽越能幫助我瞬間清醒

# 使用 Gemini CLI 進行大型程式碼庫分析

當你需要分析大型程式碼庫或多個檔案，且可能超出上下文限制時，請使用擁有超大上下文視窗的 Gemini CLI。使用 `gemini -p` 可以充分利用 Google Gemini 的大型上下文容量。

## 檔案與目錄包含語法

在 Gemini 提示中使用 `@` 語法來包含檔案和目錄。路徑應該相對於執行 gemini 命令時所在的目錄。

### 範例：

**單一檔案分析：**

```bash
gemini -p "@src/main.py 解釋這個檔案的用途與結構"
```

多個檔案：

```bash
gemini -p "@package.json @src/index.js 分析程式中使用的相依套件"
```

整個目錄：

```bash
gemini -p "@src/ 摘要說明這個程式碼庫的架構"
```

多個目錄：

```bash
gemini -p "@src/ @tests/ 分析原始碼的測試覆蓋率"
```

目前目錄與子目錄：

```bash
gemini -p "@./ 給我這個整個專案的概觀"
```

# 或使用 --all\_files 旗標：

```bash
gemini --all_files -p "分析專案結構與相依套件"
```

## 實作驗證範例

檢查功能是否已實作：

```bash
gemini -p "@src/ @lib/ 這個程式碼庫是否已經實作暗黑模式？請顯示相關檔案與函式"
```

驗證認證實作：

```bash
gemini -p "@src/ @middleware/ 是否有實作 JWT 認證？列出所有與認證相關的端點與中介軟體"
```

檢查特定模式：

```bash
gemini -p "@src/ 是否有處理 WebSocket 連線的 React hooks？請列出並附上檔案路徑"
```

驗證錯誤處理：

```bash
gemini -p "@src/ @api/ 是否對所有 API 端點實作了正確的錯誤處理？請顯示 try-catch 區塊範例"
```

檢查是否有限流：

```bash
gemini -p "@backend/ @middleware/ API 是否有實作限流？請顯示實作細節"
```

驗證快取策略：

```bash
gemini -p "@src/ @lib/ @services/ 是否有實作 Redis 快取？列出所有與快取相關的函式及其用法"
```

檢查特定安全措施：

```bash
gemini -p "@src/ @api/ 是否有實作 SQL injection 防護？請展示如何清理使用者輸入"
```

驗證功能的測試覆蓋率：

```bash
gemini -p "@src/payment/ @tests/ 是否完整測試付款處理模組？列出所有測試案例"
```

## 何時使用 Gemini CLI

當你需要以下情境時，使用 `gemini -p`：

* 分析整個程式碼庫或大型目錄
* 比較多個大型檔案
* 需要了解專案整體模式或架構
* 當前上下文視窗不足以應付任務
* 處理總大小超過 100KB 的檔案
* 驗證是否實作了特定功能、模式或安全措施
* 檢查整個程式碼庫是否存在特定的程式模式

## 重要注意事項

* @ 語法中的路徑是相對於執行 gemini 時的工作目錄
* CLI 會將檔案內容直接包含進上下文中
* 若只要進行唯讀分析，不需要使用 --yolo 旗標
* Gemini 的上下文視窗能處理整個程式碼庫，而不會像 Claude 那樣溢出
* 在檢查實作時，請具體描述你要查找的內容，才能獲得精確的結果
