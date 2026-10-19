# 整理與驗證紀錄

整理日期：2026/10/19。來源環境：Redmine 5.1.1.stable、CommonMark。

## 發佈內容比對

- 七個插件的功能程式、資產、設定模板與測試檔案，與部署目錄逐檔比對；公開發佈另將作者／專案網址改為個人專案資訊。
- 更新各插件 README、.gitignore、上游來源說明及既有 MIT 授權副本；插件功能沒有變更。
- 保留儲存庫原有的根目錄 LICENSE；Mermaid 的 MIT、WYSIWYG 的 GPL-2.0 及元件授權逐位元組保留。
- 本集合以乾淨快照建立，保留兩個上游基準與其原始 Git 歷史；驗證兩個上游基準均為目前提交的祖先。
- 排除 init 歷史備份、.backup/.bak、node_modules、執行資料與憑證；檢查追蹤內容中的 access token／私鑰特徵。
- 檢查總覽、上游來源與各插件說明中的本地相對連結。

## 2026/10/19 實際測試

- HTML 預覽 Ruby 回歸：9 項測試、56 個斷言通過。
- HTML 預覽 Playwright：使用實際 Redmine CommonMark/Markdown 輸出測試 HTML/CSS/SVG、中文、原始碼、隔離、錨點、動態預覽、手機寬度、附件及另開分頁，全部通過。執行的是本集合內的瀏覽器測試程式。
- WYSIWYG 瀏覽器 Mocha：74 項通過，包含 Mermaid/htmlview 語言與原始碼往返；另外確認 Mermaid 編輯器往返。

上述測試沒有建立票單、附件或修改 Redmine 設定。其餘四個管理／表單插件沒有在這次整理新增或執行完整功能測試，既有缺口與較早核對紀錄仍保留於各 README。

## 重現方式

在已安裝插件的 Redmine 根目錄載入環境執行 Ruby 測試：

```bash
RAILS_ENV=production bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_html_attachment_preview/test/preview_test.rb
RAILS_ENV=production bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_html_attachment_preview/test/htmlview_fixture.rb
```

將產生的 /tmp/redmine-htmlview-fixture.json 複製到開發主機。在能載入 Playwright 且已有 Chromium 的 Node.js 環境中，從本集合根目錄執行：

```bash
node redmine_html_attachment_preview/test/htmlview_test.cjs /tmp/redmine-htmlview-fixture.json
```

WYSIWYG 的 test/test.html 是瀏覽器測試入口；Node 開發依賴依該插件 README 安裝。測試入口使用 CDN 測試函式庫，需能連線取得。
