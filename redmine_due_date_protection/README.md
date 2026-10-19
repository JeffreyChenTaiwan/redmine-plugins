# Redmine Due Date Protection Plugin 完整說明文件

## 項目概述

本插件提供到期日欄位的前端鎖定與全域/專案授權設定，另有針對 IssuesController update 的後端 Patch。
核對發現前端、顯示頁及後端的授權判斷不一致，且本次 production 新進程啟動檢查沒有掛載後端 Patch；不能以目前文件宣稱所有 API 更新已受保護。

- 插件 ID：`redmine_due_date_protection`
- 版本：1.0.3
- 作者：Jeffrey Chen
- 授權：MIT（沿用 redmine-plugins 儲存庫原有授權，見 LICENSE）。
- 核對日期：2026/10/01
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

- 系統單一保護開關 protection_enabled，值為字串 '1' 或 '0'。
- 全域授權使用者/群組，加上各專案授權使用者/群組；白名單採聯集。
- 新問題或原本沒有到期日的問題，前端允許首次設定。
- 既有且原本已有到期日的問題，前端依判斷停用輸入框、調整背景與游標、停用相鄰日期按鈕並加上鎖頭。
- 問題顯示頁另有鎖頭提示與 Console 除錯資訊。
- 後端 Patch 有定義 update 檢查，但目前啟動檢查沒有掛載，實際限制詳見後文。
- 沒有每個專案獨立的 ON/OFF 開關；專案設定是白名單。

---

## 檔案結構 (Tree Structure)

```text
redmine_due_date_protection/
├── init.rb  # 登記 1.0.3、保護開關/白名單、管理及專案選單
├── lib/
│   └── redmine_due_date_protection/
│       └── issues_controller_patch.rb  # 定義 update 前的到期日檢查
├── app/
│   ├── controllers/
│   │   └── redmine_due_date_protection_controller.rb  # 管理全域及專案設定
│   └── views/
│       ├── hooks/
│       │   └── redmine_due_date_protection/
│       │       ├── _issues_form_details_bottom.html.erb  # 計算表單編輯權限
│       │       └── _issues_show_details_bottom.html.erb  # 問題顯示頁依白名單判斷是否插入到期日鎖頭
│       ├── redmine_due_date_protection/
│       │   └── index.html.erb  # 管理入口
│       └── settings/
│           └── _redmine_due_date_protection_settings.html.erb  # 全域 ON/OFF、使用者與群組清單、各專案白名單
└── config/
    ├── routes.rb  # 定義全域 index/save 及專案 project/project_sa…
    └── locales/
        ├── en.yml  # 英文保護、設定、授權與錯誤文字
        ├── zh-TW.yml  # 繁體中文保護設定與 modify_due_date 權限標籤
        ├── zh-CN.yml  # 簡體中文保護、設定與授權文字
        └── ja.yml  # 日文保護、設定與授權文字
```

---

## 檔案詳細說明

- `init.rb`：登記 1.0.3、保護開關/白名單、管理及專案選單；以巢狀 to_prepare 註冊 IssuesController Patch，並載入兩個 View Hook。

- `lib/redmine_due_date_protection/issues_controller_patch.rb`：定義 update 前的到期日檢查，白名單允許變更；未授權時移除 params 中的 due_date 並顯示訊息。

- `app/controllers/redmine_due_date_protection_controller.rb`：管理全域及專案設定，檢查對象存在，將保護開關保存為字串 1/0，記錄保存錯誤。

- `app/views/hooks/redmine_due_date_protection/_issues_form_details_bottom.html.erb`：計算表單編輯權限；既有且已有到期日的問題才可能停用輸入框、日期圖示並插入鎖頭。

- `app/views/hooks/redmine_due_date_protection/_issues_show_details_bottom.html.erb`：問題顯示頁依白名單判斷是否插入到期日鎖頭，沒有使用 modify_due_date 權限作判斷。

- `app/views/redmine_due_date_protection/index.html.erb`：管理入口，載入設定 Partial 並提交 save。

- `app/views/settings/_redmine_due_date_protection_settings.html.erb`：全域 ON/OFF、使用者與群組清單、各專案白名單；前端動態新增/刪除列並跳脫選項名稱。

- `config/routes.rb`：定義全域 index/save 及專案 project/project_save 路由。

- `config/locales/en.yml`：英文保護、設定、授權與錯誤文字。

- `config/locales/zh-TW.yml`：繁體中文保護設定與 modify_due_date 權限標籤。

- `config/locales/zh-CN.yml`：簡體中文保護、設定與授權文字。

- `config/locales/ja.yml`：日文保護、設定與授權文字。

---

## 安裝與設定

1. 複製插件目錄至 plugins/ 並重載 Redmine；沒有 Migration。
2. 管理員進入「管理 → 到期日保護設定」或原生插件設定頁。
3. 選擇 ON/OFF，設定全域與各專案的使用者/群組白名單，儲存。
4. 以既有且已有到期日的問題檢查畫面鎖定，並另外確認後端 Patch 掛載狀態。

儲存鍵為 protection_enabled、global_authorized_users、global_authorized_groups、project_settings；專案值包含 authorized_users/authorized_groups。
2026/10/01 目前保護開關讀取為 '1'。
控制器有專案 project/project_save 動作，但目錄缺少 project.html.erb；可從全域設定頁的各專案區塊設定白名單。

---

## 使用技術與實作邏輯

### 三處授權判斷不同

| 位置 | 實際允許來源 |
| --- | --- |
| 編輯表單 | 全域/專案使用者白名單、群組白名單，或 allowed_to?(:modify_due_date, project) |
| 問題顯示頁鎖頭 | 僅使用者或群組白名單 |
| 後端 Patch（若已掛載） | 僅使用者或群組白名單，沒有 modify_due_date 權限捷徑 |

Redmine 的管理員通常通過 allowed_to?，因此前端不能宣稱是「管理員也必須在白名單的嚴格模式」。顯示鎖頭與實際可編輯判斷可能不同。

### 後端實際覆蓋範圍

Patch 只註冊 update，沒有 create。新值空白、原本到期日空白或值未變更時直接 return。
即使成功掛載，清空已設定的到期日也會因 new_due_date.blank? 跳過檢查；它沒有完整禁止刪除到期日。
有效攔截時只移除 due_date 參數，其餘問題欄位仍可繼續更新。

### 本次啟動檢查

在 Redmine 5.1.1 的新 production 進程載入環境後，IssuesController.ancestors 未包含 IssuesControllerPatch，且 _process_action_callbacks 沒有 check_due_date_modification_permission。
init.rb 在 Redmine 已執行插件初始化的 to_prepare 中，再新增 to_prepare；此次初次啟動沒有執行新增的掛載回呼。
這是新進程的檢查結果，不是登入後對線上 worker 執行未授權更新的測試。

---

## 使用統計與效能

- 資料庫：使用原生 settings 保存白名單，沒有新資料表。
- 前端/後端授權涉及使用者群組查詢；設定頁載入活躍使用者、群組與專案。
- 相容性：本環境可載入設定和 Hook，但後端掛載狀態是目前已確認的限制。
- 本次工作更新文件，沒有改動插件或修補以上限制。

---

## 最佳實踐建議

- 分別檢查畫面提示、表單可編輯狀態與後端 Callback，避免把鎖頭當成 API 保護證據。
- 以「既有日期改成另一有效日期」「清空日期」「原本空白首次設定」三種情境驗證要求。
- 維護時應統一 modify_due_date 權限與白名單的前後端判斷，並處理掛載時機；這是待修正項目。
- 專案白名單目前從全域設定頁管理。

---

## 範例與常見設定

- ON，問題原本沒有日期 → 表單允許第一次設定。
- ON，已有日期，使用者既非白名單也沒有 modify_due_date → 表單停用日期欄位。
- 有 modify_due_date，但不在白名單 → 表單可能可編輯、顯示頁仍可能顯示鎖頭；若後端 Patch 有效掛載，另一次有效日期變更會被白名單檢查拒絕。
- OFF → 前端允許編輯；後端方法若掛載也直接放行。

---

## 安全性與權限

- 全域管理動作要求 require_admin。
- manage_due_date_protection 使用 require: :admin，且只映射 index/save；project/project_save 使用 authorize，但未映射到此管理權限。
- modify_due_date 已註冊並在編輯表單使用，後端與顯示頁沒有使用它。
- 有管理/專案選單登記；專案模板缺失，不能宣稱專案管理介面完整可用。
- 目前後端檢查未於本次 production 初次啟動掛載；不可宣稱前端停用欄位就能阻擋所有 API 請求。

---

## 故障排除

- 管理員沒有被鎖住：編輯表單包含 modify_due_date 的 allowed_to? 分支。
- 有鎖頭卻可編輯：顯示頁與表單的權限來源不同。
- 開啟專案設定出錯：目前缺少 app/views/redmine_due_date_protection/project.html.erb。
- API 可改日期：先檢查 Patch 是否掛載，再區分空白值與有效日期變更。

```bash
RAILS_ENV=production bundle exec ruby -E UTF-8 -r ./config/environment -e 'puts IssuesController.ancestors.include?(RedmineDueDateProtection::IssuesControllerPatch); puts IssuesController._process_action_callbacks.any? { |c| c.filter == :check_due_date_modification_permission }'
rg -n 'DueDateProtection|MissingTemplate' log/production.log
```

---

## 系統要求

- 本次核對 Redmine 5.1.1；init.rb 沒有 requires_redmine 最低版本檢查。
- 與 Redmine 相容的 Ruby、jQuery 及 IssuesController/View Hook。
- 需要後端強制保護時，須先完成掛載與權限/空白值處理的修正及驗證。

---

## 版本異動記錄

### v1.0.3（現行登記版本）

現行表單區分新問題與既有日期，包含全域/專案白名單、保護狀態下拉選單及鎖頭 Hook。
2026/10/01 文件補充後端初次啟動未掛載、前後端授權不一致、空白日期放行及專案模板缺失。

---

**版本**：1.0.3  
**作者**：Jeffrey Chen  
**最後更新**：2026/10/01
