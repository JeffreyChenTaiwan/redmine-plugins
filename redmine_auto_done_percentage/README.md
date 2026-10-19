# Redmine Auto Done Percentage Plugin 完整說明文件

## 項目概述

本插件在問題表單中，將指定狀態的完成度欄位設定為 100%，並在同一份表單離開這些狀態時，恢復暫存的完成度。
實作為瀏覽器端 JavaScript；暫存保存在表單 dataset，沒有讀取歷史紀錄或跨頁面的還原資料。

- 插件 ID：`redmine_auto_done_percentage`
- 版本：1.0.0
- 作者：Jeffrey Chen
- 授權：MIT（沿用 redmine-plugins 儲存庫原有授權，見 LICENSE）。
- 核對日期：2026/10/01
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

- 管理員可選取多個觸發 100% 的問題狀態；使用狀態 ID 比對，狀態改名不會因名稱比對而失效。
- 表單第一次進入選定狀態時，儲存目前完成度並設為 100%。
- 同一份表單離開選定狀態時，恢復暫存值並刪除暫存。
- 更新完成度後，派送會冒泡的 change 事件供其他表單處理使用。
- 表單重繪後腳本可重新綁定，暫存放在 `#issue-form`，表單本身保留時才可延續暫存。
- 2026/10/01 設定讀取檢查目前選取 2 個狀態。

---

## 檔案結構 (Tree Structure)

```text
redmine_auto_done_percentage/
├── init.rb  # 登記 1.0.0、auto_complete_statuses 預設空陣列與…
├── lib/
│   └── redmine_auto_done_percentage/
│       └── hooks.rb  # 輸出狀態 ID 清單
├── app/
│   └── views/
│       └── settings/
│           └── _auto_done_percentage_settings.html.erb  # 以 IssueStatus.sorted 提供多選設定
└── config/
    └── locales/
        ├── en.yml  # 英文的設定頁標籤與說明
        ├── zh-TW.yml  # 繁體中文的完成度設定標籤與說明
        └── zh.yml  # 簡體中文的完成度設定標籤與說明
```

---

## 檔案詳細說明

- `init.rb`：登記 1.0.0、auto_complete_statuses 預設空陣列與設定 Partial，載入 Hook。

- `lib/redmine_auto_done_percentage/hooks.rb`：輸出狀態 ID 清單，監聽狀態 change，設定完成度、儲存/刪除表單 dataset，並觸發完成度 change。

- `app/views/settings/_auto_done_percentage_settings.html.erb`：以 IssueStatus.sorted 提供多選設定，選項儲存為狀態 ID。

- `config/locales/en.yml`：英文的設定頁標籤與說明。

- `config/locales/zh-TW.yml`：繁體中文的完成度設定標籤與說明。

- `config/locales/zh.yml`：簡體中文的完成度設定標籤與說明。

---

## 安裝與設定

1. 複製 `redmine_auto_done_percentage` 至 plugins/ 並重載 Redmine；沒有 Migration。
2. 管理員開啟「管理 → 插件 → Redmine Auto Done Percentage Plugin → 設定」。
3. 多選要觸發 100% 的狀態，儲存設定。
4. 確認問題表單有完成度欄位，再測試狀態切換與儲存。

設定為 `Setting.plugin_redmine_auto_done_percentage['auto_complete_statuses']`。空清單時不綁定。
若 Redmine 使用依狀態計算完成度、工作流程隱藏完成度，或沒有 `#issue_done_ratio`，此腳本不會作用。

---

## 使用技術與實作邏輯

Hook 為 `view_issues_form_details_bottom`，腳本直接執行 attachAutoDoneListener，要求 form/status/ratio 三個 DOM 元素均存在。

| 切換情境 | 實際動作 |
| --- | --- |
| 進入選定狀態，尚無暫存 | 將目前完成度存入 form.dataset.autoDoneSavedRatio，設為 100 |
| 從選定狀態移至另一個選定狀態，已有暫存 | 保留原暫存，這次事件不重新設定完成度 |
| 離開選定狀態，已有暫存 | 恢復暫存並刪除 dataset 欄位 |
| 載入表單時原本已是選定狀態 | 僅綁定事件，沒有立即強制設定 100 |
| 頁面重新載入後離開選定狀態 | 原暫存已消失，不會還原到前一頁的數值 |

腳本以 window.autoDoneLastHandler 記錄前次 handler，對目前的狀態元素移除後再綁定。
原始碼內「Script v5」是腳本註解，不是 Redmine 插件版本。

---

## 使用統計與效能

- 資料庫：使用原生 settings 保存狀態清單，沒有額外資料表。
- 前端：以清單逐一比較 ID，暫存一個 dataset 值；沒有額外 API 呼叫。
- 相容性：本環境可載入。AJAX 替換整張表單或其他插件覆寫完成度的行為，需要按實際流程驗證。
- API/批次/console 不會執行此 JavaScript，完成度仍依 Redmine 本身的規則保存。

---

## 最佳實踐建議

- 依目前表單的狀態切換流程使用，避免把暫存還原當成跨次編輯的歷史還原。
- 測試完成度欄位是否可編輯，以及切換狀態後 Redmine 的 AJAX 回應是否會再次覆寫欄位。
- 需要所有 API 或背景更新均強制設為 100% 時，必須另外提供後端規則。

---

## 範例與常見設定

完成度 60% → 選取已設定的「已解決」→ 暫存 60 並改成 100% → 同一份表單改回「處理中」→ 還原 60%。

儲存並重新開啟已解決問題後，暫存資料已消失；此時改回處理中，插件不會自動找出之前的 60%。
若使用者在選定狀態內手動改變完成度，已存在的暫存仍是第一次進入時的數值。

---

## 安全性與權限

- 設定由 Redmine 的管理員插件設定頁處理。
- 沒有自訂權限、選單或後端驗證 Callback。
- 最終問題保存仍受 Redmine 的問題編輯權限與工作流程限制。

---

## 故障排除

- 沒有變成 100%：確認有選取狀態、完成度元素存在，且真的觸發了狀態 change。
- 重新開啟後無法還原：dataset 只存在於當前表單，這是目前實作範圍。
- 切換兩個選定狀態後不是 100%：已有暫存時不重新寫入，需確認是否有手動修改或其他腳本覆寫。

```javascript
console.log(window.autoCompleteStatusIds);
console.log(document.getElementById('issue-form')?.dataset.autoDoneSavedRatio);
```

---

## 系統要求

- 目前核對環境為 Redmine 5.1.1；init.rb 沒有最低版本檢查。
- 瀏覽器須支援 dataset、addEventListener 與 Event 建構子。
- 表單須含 issue-form、issue_status_id、issue_done_ratio 元素。

---

## 版本異動記錄

### v1.0.0（現行登記版本）

現行 Hook 注入前端完成度處理、表單 dataset 暫存、事件重綁與 change 通知。
2026/10/01 文件明確區分同表單還原與跨次編輯，並補充初次載入及選定狀態間切換的行為。

---

**版本**：1.0.0  
**作者**：Jeffrey Chen  
**最後更新**：2026/10/01
