# Redmine WYSIWYG Editor plugin 完整說明文件

## 項目概述

本插件為 Redmine 的文字欄位提供視覺化編輯、文字格式與預覽模式。
它使用 TinyMCE 編輯 HTML，透過 Redmine 的預覽回應轉入視覺內容，再轉回 Textile/Markdown 保存。
目前本地登記版本仍是 0.32.0，包含 2026/09/30 加入的 Mermaid 語言標記保留修正。

- 插件 ID：`redmine_wysiwyg_editor`
- 版本：0.32.0
- 作者：Takeshi Nakamura
- 授權：GPL-2.0（依目錄 LICENSE）。
- 核對日期：2026/10/01
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

- 切換文字格式、視覺化與預覽模式；可選擇分頁式切換。
- 支援 Textile、Markdown 及 CommonMark；依格式和允許 HTML 的情況調整工具列及轉換。
- TinyMCE 提供文字格式、清單、連結、圖片、表格、程式碼區塊、復原與全螢幕等操作。
- 可插入已有附件、圖片與 Wiki 連結，支援問題/使用者自動完成。
- 使用 Redmine 附件流程上傳貼上的圖片或拖放檔案；部分評論/日誌編輯位置停用上傳入口。
- AJAX 更新後重新尋找編輯區，處理引用及附件新增/刪除資訊。
- 本地 RedmineFormatPlugin 讀取 data-language="mermaid"，避免視覺化轉回 Markdown 時丟失語言。
- Mermaid 編輯區保留程式碼來源，渲染交給 Mermaid 插件的預覽流程。

---

## 檔案結構 (Tree Structure)

```text
redmine_wysiwyg_editor/
├── init.rb  # 登記版本、visual_editor 專案模組、use_visual_edi…
├── lib/
│   └── redmine_wysiwyg_editor.rb  # 以 view_layouts_base_html_head 載入編輯器初始化…
├── app/
│   ├── controllers/
│   │   └── editor_controller.rb  # 提供使用者自動完成、可見專案與 Wiki 頁面 JSON
│   └── views/
│       └── redmine_wysiwyg_editor/
│           ├── _redmine_wysiwyg_editor_partial.html.erb  # 依 jstoolbar、專案權限與格式載入資產
│           └── _setting.html.erb  # 以 hidden 0/checkbox 1 保存 visual_editor…
├── assets/
│   ├── javascripts/
│   │   ├── redmine_wysiwyg_editor.js  # 三種模式、TinyMCE 工具列、格式轉換、表格、圖片/附件、貼上/拖放、W…
│   │   ├── RedmineFormatPlugin.js  # 正規化 code block/換行
│   │   ├── turndown.js  # HTML 轉 Markdown 的套件資產
│   │   ├── turndown-plugin-gfm.js  # 表格與 GFM 格式轉換支援
│   │   ├── to-textile.min.js  # HTML 轉 Textile 的套件資產
│   │   └── tinymce/  # 目錄內附帶的 TinyMCE、插件、語言、主題與介面資產
│   └── stylesheets/
│       └── redmine_wysiwyg_editor.css  # 編輯器、切換模式與預覽區外觀
├── config/
│   ├── routes.rb  # 定義 /editor/users、/editor/projects 與 /e…
│   └── locales/  # 目前目錄提供 en、ja、de、fr、cs 五個語系檔
├── package.json  # 開發用 JavaScript 依賴、lint 與 Mocha 測試指令
├── package-lock.json  # JavaScript 開發依賴的鎖定檔
├── Gemfile.local  # development 群組的 RuboCop/rubocop-rails
├── test/
│   ├── test.html  # 瀏覽器 Mocha 測試入口
│   ├── test.js  # 文字與視覺格式轉換、編輯器行為測試
│   ├── redmineFormatPlugin.js  # TinyMCE 格式插件測試
│   ├── hooks/
│   │   ├── globals.js  # 提供測試 assert 的 browser/Node 共用環境
│   │   └── headless.js  # 為 Node 測試建立 jsdom、TinyMCE 與編輯器環境
│   └── test_helper.rb  # Redmine Ruby 測試環境載入骨架
└── LICENSE  # GNU General Public License version 2
```

---

## 檔案詳細說明

- `init.rb`：登記版本、visual_editor 專案模組、use_visual_editor 權限、模式切換設定與 Hook。

- `lib/redmine_wysiwyg_editor.rb`：以 view_layouts_base_html_head 載入編輯器初始化 Partial。

- `app/controllers/editor_controller.rb`：提供使用者自動完成、可見專案與 Wiki 頁面 JSON；使用者/Wiki 查詢檢查專案查看權限。

- `app/views/redmine_wysiwyg_editor/_redmine_wysiwyg_editor_partial.html.erb`：依 jstoolbar、專案權限與格式載入資產，初始化/更新編輯器並處理 AJAX、引用與附件資訊。

- `app/views/redmine_wysiwyg_editor/_setting.html.erb`：以 hidden 0/checkbox 1 保存 visual_editor_mode_switch_tab，讀取時使用符號鍵。

- `assets/javascripts/redmine_wysiwyg_editor.js`：三種模式、TinyMCE 工具列、格式轉換、表格、圖片/附件、貼上/拖放、Wiki 連結、自動完成與預覽。

- `assets/javascripts/RedmineFormatPlugin.js`：正規化 code block/換行；讀取 data-language 或語言 class，維持轉回 Markdown 的語言資訊。

- `assets/javascripts/turndown.js`：HTML 轉 Markdown 的套件資產。

- `assets/javascripts/turndown-plugin-gfm.js`：表格與 GFM 格式轉換支援。

- `assets/javascripts/to-textile.min.js`：HTML 轉 Textile 的套件資產。

- `assets/javascripts/tinymce`：目錄內附帶的 TinyMCE、插件、語言、主題與介面資產。

- `assets/stylesheets/redmine_wysiwyg_editor.css`：編輯器、切換模式與預覽區外觀。

- `config/routes.rb`：定義 /editor/users、/editor/projects 與 /editor/projects/:project_id/wikis。

- `config/locales`：目前目錄提供 en、ja、de、fr、cs 五個語系檔；其他語言部分標籤來自 Redmine 本身。

- `package.json`：開發用 JavaScript 依賴、lint 與 Mocha 測試指令；此檔 version 0.0.0 不是 Redmine 插件版本。

- `package-lock.json`：JavaScript 開發依賴的鎖定檔。

- `Gemfile.local`：development 群組的 RuboCop/rubocop-rails；不是新增的 production 執行依賴。

- `test/test.html`：瀏覽器 Mocha 測試入口，載入本地資產及外部測試函式庫。

- `test/test.js`：文字與視覺格式轉換、編輯器行為測試。

- `test/redmineFormatPlugin.js`：TinyMCE 格式插件測試，含 Mermaid 語言標記轉換回歸測試。

- `test/hooks/globals.js`：提供測試 assert 的 browser/Node 共用環境。

- `test/hooks/headless.js`：為 Node 測試建立 jsdom、TinyMCE 與編輯器環境。

- `test/test_helper.rb`：Redmine Ruby 測試環境載入骨架。

- `LICENSE`：GNU General Public License version 2。

---

## 安裝與設定

1. 將目前 redmine_wysiwyg_editor 目錄放入 plugins/ 並重載 Redmine；沒有 Migration。
2. 在需要使用的專案啟用「Visual editor／視覺化編輯器」專案模組。
3. 檢查 use_visual_editor 權限及問題/Wiki 編輯權限，開啟帶 jstoolbar 的文字欄位確認切換介面。
4. 原生插件設定頁可選擇分頁式模式切換，提交鍵為 visual_editor_mode_switch_tab。

現行 init.rb 的預設鍵是 settings_visual_editor_mode_switch_tab，但實際讀取的是 visual_editor_mode_switch_tab。
2026/10/01 讀取檢查只有前者，分頁模式判斷為 false；儲存 UI 設定後應再次確認真正的鍵和值。
執行資產已隨目錄提供；npm 依賴用於開發/測試，不是每次使用編輯器都需安裝。
上游 README 說明長文字自訂欄位需啟用文字格式及全寬顯示；目前顯示也依 jstoolbar 與頁面權限判斷。

---

## 使用技術與實作邏輯

頁首 Hook 在有 jstoolbar 的頁面加入 TinyMCE 及格式轉換程式。
進入視覺模式時，送文字至 Redmine 預覽端點並取得 HTML；離開視覺模式或相關同步事件，將 HTML 轉回 textarea。
Markdown 使用 Turndown，CommonMark 增加 GFM 處理；Textile 使用 to-textile 與自訂規則。
程式處理 Redmine 問題、使用者、附件及 Wiki 等連結語意，格式轉換仍可能改變來源寫法。

本地 Mermaid 修正將 data-language 保留為 language-mermaid，再由程式碼區塊規則輸出帶 mermaid 的 fence；目前轉回文字採 `~~~ mermaid`，與三個反引號具有同類區塊語意。
WYSIWYG_EDITOR_SETTING 可提供 TinyMCE 自訂參數；target/setup 等必要參數最後由插件指定。

---

## 使用統計與效能

- 資料庫：只使用原生插件設定、專案模組及 Redmine 原本的附件/內容保存功能，沒有新增表格。
- 前端：每個編輯器使用 TinyMCE 與格式轉換資產；模式切換會向 Redmine 請求預覽。
- 附件：複製 File 後走 Redmine 原有 uploader，仍受檔案限制與上傳回應影響。
- 相容性：2026/10/16 瀏覽器測試 74 項通過，包含 Mermaid 與 htmlview 語言及原始碼的編輯器往返；htmlview 預覽由 HTML 預覽插件 1.1.0 以上提供。

---

## 最佳實踐建議

- 修改含巨集、複雜 HTML 或特殊 Markdown 的內容時，切回文字與預覽確認轉換結果，再保存。
- Mermaid 圖表可在文字/視覺模式編輯來源，到預覽確認圖形。
- 專案逐一啟用模組並確認使用者權限；不要把模組開啟當成問題/Wiki 編輯權限。
- 完整 plugin_assets 必須能被瀏覽器取得，不能只部署主要 JavaScript 而遺漏 TinyMCE 子資產。

---

## 範例與常見設定

- 問題描述：輸入文字 → 切視覺模式排版 → 切預覽 → 確認後儲存。
- Mermaid：輸入帶 mermaid 的 fenced block → 視覺模式仍為程式碼 → 返回文字保留 mermaid → 預覽顯示圖表。
- HTML 預覽：輸入帶 htmlview 的 fenced block → 視覺模式仍為程式碼 → 預覽由 redmine_html_attachment_preview 1.1.0 顯示隔離的 HTML，返回文字保留來源。使用方式見 [HTML 預覽說明](../redmine_html_attachment_preview/README.md)。
- 貼上圖片：在允許附件上傳的編輯位置貼上，成功上傳後插入附件圖片；日誌/部分評論位置不提供相同入口。
- Wiki 插入：透過專案與頁面選單插入連結，保存後由 Redmine 解析。

---

## 安全性與權限

- 專案模組為 visual_editor，use_visual_editor 登記為 public: true、require: :member。
- 頁首啟用依專案權限、工具列及頁面條件判斷；內容保存由 Redmine 原本的編輯權限控制。
- EditorController 的使用者與 Wiki 查詢先檢查專案查看權限；專案清單使用 Project.visible。
- public 專案且搜尋文字至少 2 字元時，使用者搜尋可擴大到 active/visible 的 User.all，而非只限專案成員。
- 視覺化模式是編輯介面，沒有給使用者額外的內容存取或保存權限。

---

## 故障排除

- 沒有切換介面：檢查專案 visual_editor 模組、use_visual_editor 權限、jstoolbar 與預覽 URL。
- plugin_assets 404：檢查公開資產映射和應用程式重載後的資產同步。
- 視覺模式丟失語言：確認部署的是目前讀取 data-language 的 RedmineFormatPlugin.js。
- 分頁模式未啟用：比對實際保存的 visual_editor_mode_switch_tab 與 init.rb 的不同預設鍵。
- 轉換後來源變動：格式轉換不是完全可逆；檢查文字與預覽並使用 Redmine 內容歷史核對。

```bash
npm ci
npm test
```

以上從插件目錄執行，需有 Node.js/npm 與依賴存取能力。test/test.html 也可作瀏覽器測試入口。

---

## 系統要求

- 上游 README 宣告 Redmine 3.3.0+；本地目前只核對 5.1.1，不能據此保證全部舊版本相容。
- 目前初始化程式使用 class fields、箭頭函式等語法；舊 README 的 IE 相容註解不是完整瀏覽器相容保證。
- 需要 jQuery、TinyMCE 資產、Redmine 預覽及對應格式轉換程式。

---

## 版本異動記錄

### v0.32.0（現行登記版本）

包含三種編輯模式、附件處理與格式轉換。
2026/09/30 本地修改 RedmineFormatPlugin，加入 data-language 讀取與 Mermaid round-trip 測試；插件登記版本維持 0.32.0。
2026/10/01 文件補充模式設定鍵差異、當前權限、測試紀錄及格式轉換限制。
2026/10/16 新增 htmlview 原始碼往返測試，瀏覽器測試 74 項通過；插件登記版本維持 0.32.0。

---

**版本**：0.32.0  
**作者**：Takeshi Nakamura  
**最後更新**：2026/10/16
