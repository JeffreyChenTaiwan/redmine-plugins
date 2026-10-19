# Redmine Default Watchers Plugin 完整說明文件

## 項目概述

本插件提供全域與專案的預設觀察者清單。建立問題時，合併兩層清單，將符合資格的使用者加入觀察者。
可指定使用者或群組；群組在建立問題時展開為活躍成員。問題表單也會顯示預覽及預先勾選可找到的觀察者選項。

- 插件 ID：`redmine_default_watchers`
- 版本：1.1.0
- 作者：Jeffrey Chen
- 授權：MIT（沿用 redmine-plugins 儲存庫原有授權，見 LICENSE）。
- 核對日期：2026/10/01
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

- 合併全域清單與該專案清單；專案清單是追加，不會取代全域清單。
- 設定項目採 user:ID 或 group:ID；合併後去除重複設定項目。
- 新增使用者時要求 active? 與 allowed_to?(:view_issues, project)。
- 群組只加入目前活躍且有查看問題權限的成員。
- 已是該問題觀察者的人不會再建立一筆相同的 Watcher。
- 新問題表單顯示預覽、群組來源與可找到的核取方塊預選。
- 管理入口提供全域及逐專案編輯；程式也有專案設定入口，實際授權限制見下文。

---

## 檔案結構 (Tree Structure)

```text
redmine_default_watchers/
├── init.rb  # 登記 1.1.0、global_watchers/project_watch…
├── app/
│   ├── controllers/
│   │   └── redmine_default_watchers_controller.rb  # 提供 index/save/project/project_save/add…
│   └── views/
│       ├── hooks/
│       │   └── redmine_default_watchers/
│       │       └── _issues_form_details_bottom.html.erb  # 僅新問題顯示預設觀察者清單與群組來源
│       ├── settings/
│       │   ├── _redmine_default_watchers_settings.html.erb  # 管理員可設定全域與各專案清單
│       │   └── _project_watcher_row.html.erb  # 單一專案觀察者列
│       └── redmine_default_watchers/
│           ├── index.html.erb  # 自訂管理入口
│           ├── project.html.erb  # 單一專案設定表單
│           └── add_project_watcher.js.erb  # 將新取得的專案觀察者選項列加到對應專案容器
└── config/
    ├── routes.rb  # 定義 /default_watchers、/save、/project/:p…
    └── locales/
        ├── en.yml  # 英文設定、選項、來源與操作標籤
        ├── zh-TW.yml  # 繁體中文設定、預設觀察者預覽與群組來源提示
        ├── zh-CN.yml  # 簡體中文設定與觀察者文字
        └── ja.yml  # 日文設定與觀察者文字
```

---

## 檔案詳細說明

- `init.rb`：登記 1.1.0、global_watchers/project_watchers、管理權限與兩個選單；定義表單 Hook 和新問題保存後加入觀察者的 Hook。

- `app/controllers/redmine_default_watchers_controller.rb`：提供 index/save/project/project_save/add_project_watcher，檢查使用者/群組存在，保存全域或專案設定。

- `app/views/hooks/redmine_default_watchers/_issues_form_details_bottom.html.erb`：僅新問題顯示預設觀察者清單與群組來源；透過 jQuery 預先勾選已存在的觀察者核取方塊。

- `app/views/settings/_redmine_default_watchers_settings.html.erb`：管理員可設定全域與各專案清單；全域列在前端新增，專案列以 AJAX 取得。

- `app/views/settings/_project_watcher_row.html.erb`：單一專案觀察者列，選項包含專案活躍成員與可用群組。

- `app/views/redmine_default_watchers/index.html.erb`：自訂管理入口，載入設定 Partial 並提交至 save。

- `app/views/redmine_default_watchers/project.html.erb`：單一專案設定表單，以 project_watchers[] 提交清單。

- `app/views/redmine_default_watchers/add_project_watcher.js.erb`：將新取得的專案觀察者選項列加到對應專案容器。

- `config/routes.rb`：定義 /default_watchers、/save、/project/:project_id、專案 /save 及 /add_project_watcher。

- `config/locales/en.yml`：英文設定、選項、來源與操作標籤。

- `config/locales/zh-TW.yml`：繁體中文設定、預設觀察者預覽與群組來源提示。

- `config/locales/zh-CN.yml`：簡體中文設定與觀察者文字。

- `config/locales/ja.yml`：日文設定與觀察者文字。

---

## 安裝與設定

1. 複製插件目錄到 plugins/ 並重載 Redmine；沒有 Migration。
2. 管理員從「管理 → 預設觀察者設定」或原生插件設定頁進入。
3. 設定全域使用者/群組及各專案清單，儲存後建立新問題確認觀察者。
4. 更改清單只影響之後建立的問題，不會回填既有問題。

資料存於 `Setting.plugin_redmine_default_watchers`，鍵為 global_watchers、project_watchers。
project_watchers 以字串形式的專案 ID 作為鍵，值為 user:/group: 清單。

---

## 使用技術與實作邏輯

`controller_issues_new_after_save` 取得已保存的 issue 後，合併清單並呼叫 Watcher.create。
`view_issues_form_details_bottom` 在新問題畫面預覽清單及勾選核取方塊。

保存後的 Hook 會重新加入設定的觀察者；因此取消表單中的預選，不會把該人永久排除於預設清單。
群組身分只用於設定，實際建立的是個別使用者的 Watcher。
全域 save 檢查對象存在；project_save 對個別使用者額外驗證 active? 與查看問題權限；加入觀察者時再次驗證。

---

## 使用統計與效能

- 資料庫：設定使用原生 settings；觀察者新增至 Redmine 既有 watchers 表，沒有新表格。
- 處理量：每個清單與群組成員涉及查詢及權限檢查，較大群組會增加建立問題與表單預覽成本。
- 執行範圍：經 Redmine IssuesController 新問題保存 Hook 的流程會處理；另行使用 model/console 建立而未觸發 Hook 的流程不保證套用。
- 捕捉新增觀察者的例外並寫入日誌，不中斷已建立的問題；發生例外可能只有部分觀察者加入。

---

## 最佳實踐建議

- 以小範圍清單測試合併與去重，再按實際需求擴大群組。
- 檢查群組成員是否活躍且具有專案查看問題權限。
- 從全域清單移除某人或群組後再測試新問題；修改專案清單無法抵銷全域預設。
- 專案設定由目前管理權限處理，不要以此文件推定一般 PM 已可自行管理。

---

## 範例與常見設定

- 全域設 user:10，專案設 user:20 → 新問題可加入兩位符合資格的使用者。
- 全域與專案均有 user:10 → 保存時透過 watched_by? 避免新增重複 Watcher。
- 專案設 group:7 → 僅符合活躍與查看問題權限的成員會加入。
- 編輯既有問題 → 不會自動重新套用建立時的預設清單。

---

## 安全性與權限

- `manage_default_watchers` 在 init.rb 使用 require: :admin，並只對應 index/save。
- 控制器 index/save/add_project_watcher 要求 require_admin；project/project_save 使用 find_project 和 authorize。
- 專案動作沒有對應到 manage_default_watchers 的 action map；目前設定也不是一般角色可授予的專案管理權限。因此舊文件「專案管理員可自行設定」沒有完整實作依據。
- 管理選單：default_watchers_settings；專案選單：default_watchers，顯示條件為 allowed_to?(:manage_default_watchers, project)。
- 加入觀察者時逐人檢查查看問題權限。

---

## 故障排除

- 沒有加入：檢查 user:/group: 格式、對象存在、使用者活躍狀態及查看問題權限。
- 不想加入的人仍被加入：檢查全域清單；取消預選核取方塊不會取消後端預設。
- 群組異動後既有問題不跟著變：群組只在建立問題當下展開。
- 一般 PM 無法使用專案入口：需核對目前 require: :admin 與 project 動作的權限映射，不是僅顯示選單就完成授權。

```bash
rg -n 'RedmineDefaultWatchers' log/production.log
```

---

## 系統要求

- 目前核對環境為 Redmine 5.1.1；init.rb 沒有最低版本檢查，舊文件的「5.11+」並非此程式的版本要求。
- 設定與表單互動使用 jQuery、模板字串及 Redmine 的觀察者功能。
- 設定由管理員操作，觀察者須通過專案查看問題權限檢查。

---

## 版本異動記錄

### v1.1.0（現行登記版本）

現行程式支援使用者/群組、全域加專案清單、保存後加入觀察者與表單預覽。
2026/10/01 文件補充追加語意、取消預選後的行為、現行管理權限及非 Hook 建立流程的限制。

---

**版本**：1.1.0  
**作者**：Jeffrey Chen  
**最後更新**：2026/10/01
