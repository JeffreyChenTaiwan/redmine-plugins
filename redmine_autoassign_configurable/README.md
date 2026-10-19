# Redmine Configurable Autoassign Plugin 完整說明文件

## 項目概述

本插件依問題狀態名稱，在瀏覽器中的問題表單自動選取「指派給」，並顯示通知。
規則由管理員設定，真正的問題儲存仍由 Redmine 原本的表單流程完成。
實作包含頁面載入時的套用與狀態選單 change 事件，沒有後端自動指派 Callback。

- 插件 ID：`redmine_autoassign_configurable`
- 版本：1.2.0
- 作者：Jeffrey Chen
- 授權：MIT（沿用 redmine-plugins 儲存庫原有授權，見 LICENSE）。
- 核對日期：2026/10/01
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

- 可設定多條規則，依畫面順序取第一條符合狀態名稱的規則。
- 狀態名稱去除前後空白並忽略大小寫；執行程式可讀取逗號分隔的舊規則，設定介面使用單一狀態下拉選單。
- 支援原始建立者 `author`、專案管理員 `manager`、目前操作者 `last_updater`、指定使用者 `user:ID`。
- 設定頁提供活躍使用者選項；通知支援 en、zh-TW、zh-CN、ja，以 `{name}` 代入姓名。無對應語言時回退英文。
- 初次載入問題表單時也會套用規則；這可能改變表單原先的指派值。
- 狀態變更時顯示中央通知；若有 Select2，額外觸發 `change.select2`。
- 設定使用 HashWithIndifferentAccess，符號與字串鍵均可存取。

---

## 檔案結構 (Tree Structure)

```text
redmine_autoassign_configurable/
├── init.rb  # 登記版本 1.2.0、預設規則與通知
├── app/
│   ├── controllers/
│   │   └── redmine_autoassign_controller.rb  # require_admin 保護 index/save/new_rule
│   └── views/
│       ├── hooks/
│       │   └── redmine_autoassign_configurable/
│       │       └── _issues_form_details_bottom.html.erb  # 讀取設定、建立活躍使用者快取、匹配狀態並更新指派選單與中央通知
│       ├── settings/
│       │   ├── _redmine_autoassign_settings.html.erb  # 管理員設定規則與四種語言通知
│       │   └── _rule.html.erb  # 單一規則的狀態名稱與指派目標下拉選單
│       └── redmine_autoassign/
│           └── new_rule.js.erb  # 將新的規則 Partial 加到 #autoassign-rules
└── config/
    ├── routes.rb  # 定義 GET /redmine_autoassign、POST /redmi…
    └── locales/
        ├── en.yml  # 英文設定標籤與規則提示
        ├── zh-TW.yml  # 繁體中文的狀態、目標、通知與新增/刪除規則標籤
        ├── zh-CN.yml  # 簡體中文設定文字
        └── ja.yml  # 日文設定文字與目標標籤
```

---

## 檔案詳細說明

- `init.rb`：登記版本 1.2.0、預設規則與通知；註冊問題表單 View Hook。管理選單及額外管理權限的程式目前為註解。

- `app/controllers/redmine_autoassign_controller.rb`：require_admin 保護 index/save/new_rule；整理規則和通知後寫入 Setting；提供新增規則的 AJAX 資料。

- `app/views/hooks/redmine_autoassign_configurable/_issues_form_details_bottom.html.erb`：讀取設定、建立活躍使用者快取、匹配狀態並更新指派選單與中央通知。

- `app/views/settings/_redmine_autoassign_settings.html.erb`：管理員設定規則與四種語言通知；新增規則採 AJAX，刪除採事件委派；保留舊多狀態拆分處理。

- `app/views/settings/_rule.html.erb`：單一規則的狀態名稱與指派目標下拉選單。

- `app/views/redmine_autoassign/new_rule.js.erb`：將新的規則 Partial 加到 #autoassign-rules。

- `config/routes.rb`：定義 GET /redmine_autoassign、POST /redmine_autoassign/save、GET /redmine_autoassign/new_rule。

- `config/locales/en.yml`：英文設定標籤與規則提示。

- `config/locales/zh-TW.yml`：繁體中文的狀態、目標、通知與新增/刪除規則標籤。

- `config/locales/zh-CN.yml`：簡體中文設定文字；通知欄位鍵為 zh-CN。

- `config/locales/ja.yml`：日文設定文字與目標標籤。

---

## 安裝與設定

1. 將 `redmine_autoassign_configurable` 放入 Redmine 的 `plugins/` 並重載應用程式；此目錄沒有 Migration。
2. 管理員進入「管理 → 插件 → Redmine Configurable Autoassign Plugin → 設定」。
3. 新增規則，選擇實際狀態名稱及指派目標，調整順序並填寫通知文字後儲存。
4. 開啟問題表單，檢查載入時及狀態變更時的指派值，再儲存問題。

登記的預設規則為 `feedback → author`、`resolved → author`；只有實際狀態名稱符合時才會套用。
設定鍵為 `rules` 與 `notifications`，儲存於 `Setting.plugin_redmine_autoassign_configurable`。
`/redmine_autoassign` 的 index 動作目前缺少對應 `index.html.erb`，使用原生插件設定頁作為入口。

---

## 使用技術與實作邏輯

Hook 為 `view_issues_form_details_bottom`。JavaScript 以選單文字比對規則，設定 `#issue_assigned_to_id`，再由 Redmine 儲存表單。

| 目標值 | 實際來源 |
| --- | --- |
| author | 問題的 author_id/name |
| manager | `@issue.project.try(:manager)`；未取得 manager 時回傳 null |
| last_updater | `User.current`，是目前操作者，不是查詢最後一筆歷史紀錄 |
| user:ID | 目標 ID 與頁面中的活躍使用者姓名快取 |

本次環境檢查 `Project.new.respond_to?(:manager)` 為 false。因此目前選擇 manager 不會產生指派目標；此程式沒有自行查找「管理員」角色成員。
第一條命中規則若無有效目標，程式直接回傳 null，不會繼續尋找後面的規則。

---

## 使用統計與效能

- 資料庫：使用原生 settings 儲存規則與通知，沒有額外資料表。
- 前端：每次表單輸出會將活躍使用者寫入 JavaScript 快取；使用者數量較多時會增加頁面大小。
- 相容性：本環境可載入插件，沒有完整驗證所有工作流程、AJAX 刷新或其他插件的指派邏輯。
- API、Rails console 或沒有執行此表單 JavaScript 的建立/更新流程，不會因此自動指派。

---

## 最佳實踐建議

- 使用實際狀態名稱，一條規則對應一個狀態，並注意第一條符合規則的優先順序。
- 目前可選擇 author、last_updater 或可指派的指定使用者；使用 manager 前須先提供專案 manager 來源。
- 確認目標使用者存在於目前問題的指派選單中；設定頁列出活躍使用者不代表每位都可被指派到該專案。
- 儲存前檢查指派值，尤其是只想修改描述而未改變狀態的情境。

---

## 範例與常見設定

- 狀態「回饋」→ author：選擇該狀態後，表單指派給問題建立者。
- 狀態「處理中」→ last_updater：選擇後，表單指派給目前操作使用者。
- 狀態「驗收」→ user:123：目標為 ID 123；仍須由 Redmine 驗證該使用者是否可被指派。
- 通知「已自動指派給 {name}」：通知會以目標姓名替換佔位符。

---

## 安全性與權限

- 設定控制器三個動作均使用 require_admin；原生插件設定頁由 Redmine 管理員權限保護。
- init.rb 的自訂管理權限與管理選單目前為註解，沒有啟用。
- 問題儲存、專案權限與可指派成員仍由 Redmine 驗證；本插件的前端選取不是後端強制規則。

---

## 故障排除

- 無自動指派：確認狀態名稱、規則順序、目標是否在指派選單中，以及瀏覽器 Console 是否有錯誤。
- manager 無效果：本次 Project 物件沒有 manager 方法；此選項不是以角色名稱尋找 PM。
- 指派給「最後更新者」與預期不同：其實是目前登入操作者。
- 設定 index 失敗：目錄缺少 `app/views/redmine_autoassign/index.html.erb`，請從原生插件設定頁操作。
- AJAX 刷新後失效或重複通知：程式使用 ready/change 綁定，沒有專用的重複初始化防護；需針對實際表單重繪流程查核。

```bash
rg -n 'autoassign|MissingTemplate' log/production.log
```

---

## 系統要求

- 目前核對環境為 Redmine 5.1.1；init.rb 沒有最低版本檢查，不代表其他版本均已驗證。
- 瀏覽器須支援使用中的 JavaScript 功能、jQuery 與 Redmine 問題表單。
- 使用者須能編輯問題；指定目標須符合 Redmine 的指派限制。

---

## 版本異動記錄

### v1.2.0（現行登記版本）

現行程式包含狀態名稱規則、角色/使用者目標、通知、管理設定及 AJAX 新增規則。
2026/10/01 文件核對補充 manager 的實際來源、last_updater 語意、載入時套用及缺少 index 模板等限制。

---

**版本**：1.2.0  
**作者**：Jeffrey Chen  
**最後更新**：2026/10/01
