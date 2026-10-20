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

## 2026/10/21 Mermaid 1.2.4 驗證

本次只更新 Mermaid 程式、文件及其回歸測試，其餘六個插件沒有變更。以下測試使用本集合內的 test/render_fixture.rb 與 test/browser.cjs，內容為合成圖表，不使用票單、專案或附件資料。

| Redmine | Ruby / Rails | 實際 formatter | 瀏覽器 |
| --- | --- | --- | --- |
| 5.1.1.stable | 3.0.6 / 6.1.7.6 | CommonMark、Markdown、Textile 巨集 | Edge 155.0.4283.62、Playwright Firefox 135 |
| 7.0.2.stable | 4.0.7 / 8.1.4 | CommonMark、Textile 巨集 | Edge 155.0.4283.62、Playwright Firefox 135 |

- 兩個版本均以實際 Redmine formatter 產生 HTML；5.1.1 在獨立 Ruby 進程載入新版 Hook／巨集，沒有替換既有部署檔案。測試資料庫連線設為 session read-only，設定覆寫僅作用於當前進程。
- 四組瀏覽器執行共 26 組檢查通過：巨集、可用的 fenced block、ELK、中文與特殊字元、一般程式碼與語法範例保留、動態預覽依序繪圖、錯誤後繼續繪圖、無圖表時不載入外部模組。
- 分別模擬掃描前與等待 ELK 載入時留下 data-processed 標記，兩者均恢復繪圖；已完成的圖表重新插入 DOM 時保留原有 SVG。
- 瀏覽器測試使用公開 CDN：Mermaid 11.16.1、layout-elk 0.2.2；另外確認舊設定缺少 elk_url 時的 CDN 回退。Hook 不再加入 importmap。
- 本次未部署至既有正式站，未重跑其他六個插件的完整功能測試；上述結果不代表驗證了所有 Redmine 或瀏覽器版本。

### Mermaid 重現方式

在已安裝本版插件的 Redmine 根目錄執行：

```bash
RAILS_ENV=production bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_mermaid_macro/test/render_fixture.rb
```

將 /tmp/redmine-mermaid-fixture.json 複製到開發主機，在已安裝 Playwright、Chromium 與 Firefox 的環境，從本集合根目錄執行：

```bash
node redmine_mermaid_macro/test/browser.cjs /tmp/redmine-mermaid-fixture.json
MERMAID_BROWSER=firefox node redmine_mermaid_macro/test/browser.cjs /tmp/redmine-mermaid-fixture.json
```

可設定 MERMAID_BROWSER_EXECUTABLE 使用特定瀏覽器執行檔。測試啟動僅綁定本機的臨時 HTTP 埠，依合成 fixture 的設定載入公開模組；不需帳密或 API key。產生器不會寫入 Redmine 設定；MERMAID_FIXTURE 可指定輸出 JSON 路徑。

## 2026/10/19 測試重現方式


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
