# Redmine HTML Attachment Preview 完整說明文件

## 項目概述

本插件讓 `.html`/`.htm` 附件及票單中的 `htmlview` 程式碼區塊以網頁方式顯示，適用於含文字、CSS 與靜態 SVG 的自包含報告。
提供隔離 iframe、頁內目錄跳轉與原始碼展開，保留 Redmine 的附件查看與下載流程。這次功能延伸原有的獨立 plugin，不需另外安裝插件。

- 插件 ID：`redmine_html_attachment_preview`
- 版本：1.2.0
- 作者：Jeffrey Chen
- 授權：MIT（沿用 redmine-plugins 儲存庫原有授權，見 LICENSE）。
- 核對日期：2026/10/16
- 核對環境：Redmine 5.1.1.stable，文字格式為 CommonMark。

---

## 主要功能

### 1. HTML 附件網頁預覽

- 支援 `.html` 與 `.htm` 副檔名，大小寫皆可。
- 顯示 HTML 內容、CSS 排版、內嵌 SVG、圖片與字型。
- 預覽寬度配合附件頁面，長篇內容可在預覽區內捲動。
- 保留頁內目錄連結，例如點選章節後跳至對應內容。

### 2. 原始碼與下載

- 預覽下方提供「檢視 HTML 原始碼」，點選即可展開原本的程式碼檢視。
- 保留 Redmine 附件頁面的「下載」按鈕。
- 預覽用的處理只作用於顯示內容，儲存的附件檔案與下載內容維持原樣。

### 3. 隔離預覽

- HTML 顯示於獨立的 sandbox iframe，附件的 CSS 不會套用到 Redmine 主頁。
- 預覽停用 JavaScript、表單提交、嵌入子頁面與瀏覽器外掛內容。
- 預覽無法讀取 Redmine 主頁的 DOM、Cookie 或儲存空間。

### 4. 沿用原生附件權限與大小限制

- 使用者仍須通過 Redmine 原本的附件查看權限檢查。
- 沿用 Redmine 的附件內容顯示大小上限。
- 其他類型的附件繼續使用 Redmine 原有的預覽方式。

### 5. 票單內的 HTML 渲染

- 在票單描述、留言、Wiki 等 Wiki 格式內容中，使用 Markdown/CommonMark 的 `htmlview` fenced code block。
- 三個反引號或三個波浪號的程式碼圍欄皆可使用；`html` 區塊仍維持原本的原始碼顯示。
- 支援初次載入、Redmine AJAX 預覽與視覺化編輯器的預覽分頁。
- 每個區塊各有隔離 iframe，並可展開原始碼；原始文字仍保存在票單欄位中。
- 視覺化編輯器切換時保留 `htmlview` 語言與 HTML 原始碼，渲染只發生於顯示／預覽區。
- 票內預覽寬度 100%、高度 60vh、最低 240px；超出內容在框內捲動。

### 6. 另開分頁單獨閱讀

- 票內 `htmlview` 和 HTML 附件的預覽右上角均提供「另開分頁 ↗」小標籤。
- 點擊後以整頁高度閱讀目前的 HTML，保留 CSS、SVG 及頁內目錄跳轉。
- 開新分頁或新視窗由瀏覽器設定決定；原票單及其原始碼展開狀態保留。
- 新頁面仍使用 sandbox iframe 與相同 CSP，JavaScript 停用，且沒有回到原頁的 opener 存取能力。
- 使用瀏覽器本機的暫時 Blob URL，不新增附件或伺服器路由。這是開啟當下的內容副本，原票單更新後須重新開啟；分享或書籤請使用原票單／附件網址。

---

## 檔案結構 (Tree Structure)

```text
redmine_html_attachment_preview/
├── init.rb                            # 登記 1.2.0、掛載 Helper Patch 與載入 Hook
├── app/views/html_attachment_preview/
│   └── _preview.html.erb               # 附件 iframe 與原始碼展開
├── assets/
│   ├── javascripts/htmlview.js          # 票內 htmlview 與動態預覽
│   └── stylesheets/html_attachment_preview.css
├── lib/redmine_html_attachment_preview/
│   ├── attachments_helper_patch.rb     # HTML/HTM 附件辨識
│   ├── html_document.rb                # 附件文件處理與共用 CSP
│   └── view_hook.rb                    # CSS、JavaScript、語系與政策資料
├── config/locales/
│   ├── en.yml
│   ├── zh-TW.yml
│   └── zh.yml
└── test/
    ├── preview_test.rb                 # Ruby 回歸測試
    ├── htmlview_fixture.rb             # 產生實際格式器測試資料
    └── htmlview_test.cjs                # Playwright 瀏覽器測試
```

---

## 檔案詳細說明

- `init.rb`：登記版本 1.2.0、最低 Redmine 5.0.0，直接且防重複地 prepend AttachmentsHelper Patch，載入 ViewHook；沒有設定頁或 Migration。
- `app/views/html_attachment_preview/_preview.html.erb`：跳脫 srcdoc，建立空 sandbox iframe，以 details 顯示 Redmine common/file 原始碼。
- `assets/javascripts/htmlview.js`：辨識 `.wiki pre > code` 中的 `data-language="htmlview"` 或 `language-htmlview`；以 textContent 取得原始碼，建立隔離文件。MutationObserver 處理動態預覽，略過已建立的預覽內的原始碼以避免重複渲染。為票內／附件 iframe 建立另開分頁連結；新頁面僅含隔離 iframe，預覽移除後延遲釋放暫時 Blob URL。
- `assets/stylesheets/html_attachment_preview.css`：附件高度 75vh、最低 480px；票內高度 60vh、最低 240px；兩者寬度皆為 100%，並設定邊框、原始碼區間距及右上角小標籤。
- `lib/redmine_html_attachment_preview/attachments_helper_patch.rb`：辨識 HTML/HTM 副檔名，委派 HtmlDocument 處理文件，再使用附件模板。
- `lib/redmine_html_attachment_preview/html_document.rb`：定義兩種預覽共用的 CSP；附件經編碼轉換後以 Nokogiri 整理，加入 CSP/no-referrer/about:srcdoc，移除原有 base 與 meta refresh。
- `lib/redmine_html_attachment_preview/view_hook.rb`：透過頁首 Hook 載入 CSS 與 defer JavaScript，將共用 CSP 及預覽／原始碼／另開分頁語系標籤作為已跳脫的 data 屬性傳入腳本。
- `config/locales/en.yml`：英文預覽與原始碼標籤。
- `config/locales/zh-TW.yml`：繁體中文預覽與原始碼標籤。
- `config/locales/zh.yml`：簡體中文預覽與原始碼標籤。
- `test/preview_test.rb`：9 個 Minitest 案例，涵蓋附件副檔名、中文/SVG、一般文字、HTML 跳脫、CSP/錨點、頁首 Hook、CommonMark htmlview 與一般 html 區塊。
- `test/htmlview_fixture.rb`：以實際 Redmine CommonMark/Markdown 格式器與附件 Helper 產生瀏覽器測試資料，不儲存票單或附件。
- `test/htmlview_test.cjs`：使用 Playwright 驗證 HTML/CSS/SVG、隔離、錨點、原始碼、動態預覽、重複掃描、手機寬度與附件相容性。

---

## 安裝與設定

### 安裝

1. 將 `redmine_html_attachment_preview` 目錄複製到 Redmine 的 `plugins/` 目錄。
2. 重載或重新啟動 Redmine 應用程式。
3. 以管理員登入，進入「管理 → 插件」，確認列表中顯示「Redmine HTML Attachment Preview」及版本 `1.2.0`。
4. 開啟一個 HTML 附件，或在票單描述加入下方的 `htmlview` 範例，確認出現網頁預覽和原始碼展開區。

本插件不需要資料庫 Migration，也沒有獨立的插件設定頁。載入後會自動處理符合條件的附件與 `htmlview` 區塊。

### 目前 Docker 環境的重載方式

本環境使用 `redmine-app` 容器與 Passenger，可使用以下指令重載 Redmine 應用程式：

```bash
docker exec -w /path/to/redmine redmine-app bundle exec passenger-config restart-app /path/to/redmine
```

其他部署環境請依其應用程式服務的方式重載。

### 附件大小限制

附件預覽沿用「管理 → 設定 → 附件」中的「檔案內容顯示大小之最大值」，對應設定名稱為 `file_max_size_displayed`，單位為 KB。

例如將預覽上限設為 512 KB，超過系統設定上限的附件會沿用 Redmine 的下載介面，不會顯示 HTML 預覽。此附件設定不適用於票單中的 `htmlview` 區塊；票內內容仍受 Redmine 原本的欄位／請求限制。

### 移除插件

將整個 `redmine_html_attachment_preview` 目錄移到 `plugins/` 以外的備份位置，再重載 Redmine，即可恢復原本的 HTML 原始碼顯示方式。原有附件仍由 Redmine 管理。

2026/10/16 production 新進程載入及回歸測試確認 AttachmentsHelper Patch 與頁首 Hook 可正常使用。

---

## 使用技術與實作邏輯

### 附件

1. Redmine 的 `AttachmentsController` 先執行附件讀取與查看權限檢查。
2. 符合原生文字預覽條件及檔案大小限制時，Redmine 呼叫 `render_file_content`。
3. 插件的 Helper Patch 檢查副檔名；HTML 附件使用新模板，其他附件交回原本的方法。
4. 透過 `Redmine::CodesetUtil.to_utf8_by_setting` 轉換編碼，再以 Nokogiri 整理 HTML 文件。
5. 預覽文件加入 Content Security Policy、`no-referrer` 設定與 `about:srcdoc` 基底網址，並移除原有的 `<base>` 和 meta refresh 自動跳轉設定。
6. 文件經過屬性跳脫後放入 iframe 的 `srcdoc`，由瀏覽器顯示網頁內容。

### 票內 htmlview

1. Redmine 格式器先將 fenced block 轉為含語言標記的程式碼 HTML；原始 HTML 仍被跳脫。
2. 頁首 Hook 載入的腳本掃描 `.wiki` 內符合 `htmlview` 的程式碼區塊。
3. 從 `textContent` 取得 HTML，由 DOMParser 建立獨立文件，移除 base/meta refresh，再加入共用 CSP 與預覽基底網址。
4. 透過 `iframe.srcdoc` 屬性設定內容，空 sandbox 隔離主頁；沒有將使用者 HTML 插入 Redmine 主文件。
5. 原本的 pre/code 移入可展開的 details。動態新增的預覽同樣處理，既有預覽及其原始碼不再重複轉換。
6. 為預覽建立另開分頁標籤：以 DOM API 產生僅含 sandbox iframe 的外層文件，srcdoc 維持同一份預覽內容，透過 Blob URL 及 `target="_blank" rel="noopener noreferrer"` 開啟。原始使用者 HTML 不直接放入頂層文件。

### 支援範圍與限制

| 項目 | 支援情況 |
| --- | --- |
| HTML 文字、表格及排版 | 支援 |
| 內嵌 CSS | 支援 |
| 內嵌 SVG 圖表 | 支援靜態顯示 |
| 頁內目錄與錨點連結 | 支援，在預覽內跳轉 |
| 絕對 HTTP(S) 網址的 CSS、圖片與字型 | 允許載入，實際顯示仍受網路與外部伺服器限制 |
| data URL 的圖片與字型 | 允許載入 |
| `style.css`、`images/chart.png` 等相對路徑資源 | 不會自動對應到其他 Redmine 附件 |
| JavaScript、事件處理與互動式程式 | 停用 |
| 表單提交、子 iframe、object/embed | 停用 |
| meta refresh 自動跳轉 | 從預覽文件移除 |

適合使用自包含的 HTML 報告：CSS 放在 HTML 內，圖表採用內嵌 SVG，圖片可使用 data URL。預覽使用 Redmine 的文字編碼轉換設定，HTML 檔案建議以 UTF-8 儲存。

---

## 使用統計與效能

- 資料庫：插件本身不新增資料表，也不儲存額外設定。
- 伺服器處理：HTML 預覽會進行編碼轉換、文件解析與原始碼格式化；內容越大，處理量越高。
- 瀏覽器處理：附件 HTML 由 iframe 顯示；外部圖片或字型可能產生額外網路請求。
- 預覽大小：附件沿用 Redmine 原本的顯示大小上限。票內每個 htmlview 會建立一個 iframe，長篇或大量區塊會增加瀏覽器的解析與記憶體負擔。
- 相容性：已在 Redmine 5.1.1 驗證，其他版本仍需依部署環境確認。

---

## 最佳實踐建議

- 將 CSS 放入報告本身，以內嵌 SVG 或 data URL 圖片提供圖表，避免相對 companion files。
- 需要互動式 JavaScript 的內容，另行設計隔離顯示方式；本插件只提供靜態預覽。
- 留意 Redmine 的原生預覽大小上限，使用目錄跳轉閱讀較長報告。
- 更新顯示程式時保留 sandbox、CSP 及 srcdoc 的跳脫／屬性設定方式。
- `htmlview` 內若需要展示三個反引號，外層改用四個反引號或波浪號，避免提早結束區塊。

---

## 範例與常見設定

### 在票單中直接顯示 HTML

使用文字編輯模式，在描述或留言中輸入：

````markdown
```htmlview
<style>
  body { font-family: sans-serif; padding: 16px; }
  h2 { color: #1565c0; }
</style>
<h2>測試報告</h2>
<p>這段文字會直接排版顯示。</p>
<table border="1">
  <tr><th>項目</th><th>結果</th></tr>
  <tr><td>連線測試</td><td>通過</td></tr>
</table>
```
````

儲存或切換「預覽」後會看到 HTML 排版，下方可展開原始碼；點右上角「另開分頁 ↗」可單獨閱讀。也接受 `~~~htmlview` 圍欄。

若希望顯示 HTML 程式碼，繼續使用原有的 `html`：

````markdown
```html
<h2>這段顯示原始碼</h2>
```
````

此語法適用於 Markdown/CommonMark，Textile 不會把反引號圍欄解析成相同區塊。視覺化模式中保留為程式碼；請切換預覽查看渲染效果。需要同時編輯 HTML 與確認結果時，可在文字與預覽模式間切換。

### 開啟 HTML 附件

1. 將 HTML 報告上傳為 Redmine 附件。
2. 點選附件名稱，進入附件顯示頁，例如 `/attachments/123`。
3. 直接閱讀 iframe 內的網頁內容，或使用報告內的目錄跳轉章節。
4. 點右上角「另開分頁 ↗」，可在新頁面以整頁高度閱讀。
5. 要查看原始碼時，展開「檢視 HTML 原始碼」。
6. 要取得原始檔案時，使用附件頁面的「下載」按鈕。

可使用含中文、內嵌 CSS、SVG 與頁內目錄的自包含 HTML 報告測試預覽。

### 與 Mermaid 插件的用途差異

| 插件 | 輸入內容 | 顯示結果 |
| --- | --- | --- |
| `redmine_html_attachment_preview` | `.html`/`.htm` 附件或 `htmlview` 區塊 | HTML 網頁、CSS 排版與既有的 SVG 圖表 |
| `redmine_mermaid_macro` | Wiki 格式欄位中的 `{{mermaid …}}` 或 Markdown Mermaid 區塊 | 由 Mermaid 產生的圖表 |

HTML 預覽處理靜態 HTML，Mermaid 插件將圖表語法轉為圖形。HTML 預覽內若包含需要 JavaScript 執行的 Mermaid 程式，這個預覽不會執行它；可先將圖表匯出成 SVG，再嵌入 HTML 報告。

---

## 安全性與權限

- 原生權限：附件保留 `AttachmentsController` 的權限流程；票內區塊沿用票單、留言或 Wiki 的原生查看權限。
- iframe 隔離：原頁與另開分頁均使用空的 `sandbox` 屬性，維持瀏覽器的隔離限制。
- 新分頁隔離：連結使用 noopener/noreferrer；頂層只含插件產生的外框，使用者 HTML 保留於隔離 iframe。
- 內容政策：Content Security Policy 停用腳本、連線 API、子頁面、object 與表單提交。
- HTML 跳脫：附件內容放入 srcdoc 屬性時經模板跳脫；票內使用 textContent 讀取及 iframe.srcdoc 屬性設定，避免 HTML 逸出到主頁。
- 樣式隔離：附件或票內 HTML 的 CSS 僅作用於各自的預覽文件。
- 額外權限與選單：本插件沒有新增權限項目、專案選單或自訂附件存取路由。

維護時應保留 sandbox 與內容政策設定。需要執行 JavaScript 的 HTML 應另行設計隔離方案。

---

## 故障排除

### htmlview 仍顯示程式碼

確認使用 Markdown/CommonMark，區塊開頭為三個反引號接 `htmlview`，結尾另起一行三個反引號。視覺化編輯模式保留程式碼是預期行為，請在預覽或儲存後查看。若預覽仍未渲染，確認插件版本為 1.2.0、已重載 Redmine，並重新整理頁面載入新腳本：

```text
/plugin_assets/redmine_html_attachment_preview/javascripts/htmlview.js
```

瀏覽器必須啟用 JavaScript；腳本只處理 `.wiki` 顯示區，單純 `html` 區塊維持原始碼。停用 JavaScript 時仍可閱讀原始程式碼。

### 另開分頁標籤沒有出現或無法開啟

確認插件版本為 1.2.0，重載後重新整理頁面以載入新 JavaScript 與 CSS。標籤需要瀏覽器啟用 JavaScript。若瀏覽器或擴充套件封鎖新頁面，檢查其提示。暫時的 Blob URL 僅供當次瀏覽使用，請從原票單／附件頁重新開啟。

### 仍然只顯示 HTML 原始碼

確認插件已列於「管理 → 插件」、Redmine 已完成重載，以及附件副檔名為 `.html` 或 `.htm`。重新整理附件頁面後再確認。

### 只看到下載介面

檢查附件大小是否超過「檔案內容顯示大小之最大值」，並確認使用者具有附件查看權限。

### 圖片、樣式或字型未顯示

檢查是否使用相對路徑，或外部網址是否可存取。瀏覽器開發者工具的 Network 與 Console 可協助確認載入失敗原因；HTTPS 頁面載入 HTTP 資源也可能受到瀏覽器限制。

### 圖表或按鈕沒有反應

確認內容是否依賴 JavaScript。此預覽顯示靜態 HTML、CSS 與 SVG，互動式腳本不會執行。

### 中文出現亂碼

先確認原始 HTML 的文字編碼，並檢查 Redmine 的 `repositories_encodings` 設定。優先使用 UTF-8 儲存報告。

### 預覽框樣式未載入

檢查下列網址是否能取得 CSS，並確認應用程式具有更新插件公開資產目錄的權限：

```text
/plugin_assets/redmine_html_attachment_preview/stylesheets/html_attachment_preview.css
```

目前環境的日誌可透過以下指令查看：

```bash
docker exec redmine-app tail -n 100 /path/to/redmine/log/production.log
```

---

## 系統要求

- Redmine 5.0.0 以上；目前實測為 5.1.1。
- 與 Redmine 版本相容的 Ruby 環境。
- Redmine 環境中的 Nokogiri 與文字編碼轉換功能。
- 支援 iframe `srcdoc`、`sandbox`、Content Security Policy、DOMParser 與 MutationObserver 的現代瀏覽器；票內渲染須啟用 JavaScript。

---

## 版本異動記錄

### v1.2.0（2026/10/16）

- 票內及附件 HTML 預覽新增「另開分頁 ↗」小標籤。
- 新頁面以整頁高度顯示同一份 HTML，保留 CSS/SVG、錨點與 sandbox/CSP 隔離。
- 使用本機暫時 Blob URL、noopener/noreferrer，預覽移除後釋放 URL。
- Ruby 測試 9 項、56 個斷言通過；瀏覽器實際開啟已儲存內容、動態預覽及附件的新分頁，驗證內容、隔離、整頁高度、目錄與原頁保留。

### v1.1.0（2026/10/16）

- 新增 Markdown/CommonMark `htmlview` 區塊，直接在票單、留言與 Wiki 顯示 HTML。
- 支援 AJAX 及視覺化編輯器預覽，保留原始碼展開與編輯器往返。
- 附件與票內預覽共用 CSP；HTML 的 CSS、腳本與主頁隔離。
- 新增格式器、頁首 Hook 及瀏覽器回歸測試。

### v1.0.0（2026/09/30）

- 初始版本，加入 HTML 附件網頁預覽。
- 提供原始碼展開檢視，保留原生下載功能。
- 支援中文、CSS、靜態 SVG 與頁內目錄跳轉。
- 加入 iframe 隔離、內容政策與回歸測試。


### 測試與核對紀錄

#### 回歸測試

從 Redmine 應用程式目錄載入環境後執行測試。測試使用未儲存的附件物件：

```bash
RAILS_ENV=production bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_html_attachment_preview/test/preview_test.rb
```

目前 Docker 環境也可執行：

```bash
docker exec -w /path/to/redmine -e RAILS_ENV=production redmine-app bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_html_attachment_preview/test/preview_test.rb
```

2026/09/30 v1.0.0 驗證結果：6 項測試、38 項斷言通過，沒有失敗或錯誤。

#### 瀏覽器驗證

已使用範例 HTML 附件 驗證中文、CSS、6 張 SVG 圖表、目錄跳轉、原始碼展開及手機寬度顯示；另以測試文件確認腳本無法執行，預覽無法讀取主頁 DOM 或 Cookie，meta refresh 不會跳轉。

2026/10/16 v1.1.0 驗證結果：

- Ruby 回歸測試：9 項測試、55 項斷言通過。
- Playwright：實際 CommonMark/Markdown 輸出、HTML/CSS/中文/SVG、HTML 跳脫、一般 html 區塊、sandbox/CSP、禁止腳本與表單、錨點、原始碼、動態預覽、重複掃描、手機寬度及附件回歸均通過。
- 視覺化編輯器瀏覽器測試：74 項通過，包含 htmlview 與 Mermaid 的語言及原始碼保留。

瀏覽器測試先用實際 Redmine 環境產生 fixture，再於有 Playwright 的 Node.js 環境執行：

```bash
docker exec -w /path/to/redmine -e RAILS_ENV=production redmine-app bundle exec ruby -E UTF-8 -r ./config/environment plugins/redmine_html_attachment_preview/test/htmlview_fixture.rb
docker cp redmine-app:/tmp/redmine-htmlview-fixture.json /tmp/redmine-htmlview-fixture.json
node redmine_html_attachment_preview/test/htmlview_test.cjs /tmp/redmine-htmlview-fixture.json
```

Node.js 須能載入 `playwright`，並已安裝其 Chromium；可按本機套件位置設定 NODE_PATH。測試不建立或修改票單與附件。

---

**版本**：1.2.0  
**作者**：Jeffrey Chen  
**最後更新**：2026/10/16
