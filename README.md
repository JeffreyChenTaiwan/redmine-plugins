# Redmine Plugins

Jeffrey Chen 的 Redmine 插件集合，包含 **5 個自行開發的插件**及 **2 個保留上游歷史的本地改版**。每個插件都是一個獨立目錄，可依需求選用。

整理日期：2026/10/19。來源環境：Redmine 5.1.1.stable，文字格式 CommonMark。這次整理保留目前的程式行為，個別限制請見下方及各插件 README。

| 目錄與使用說明 | 版本 | 用途 | 來源／授權 |
| --- | --- | --- | --- |
| [redmine_autoassign_configurable](redmine_autoassign_configurable/README.md) | 1.2.0 | 依狀態在問題表單選取指派對象 | 自製，Jeffrey Chen／MIT |
| [redmine_auto_done_percentage](redmine_auto_done_percentage/README.md) | 1.0.0 | 指定狀態設定完成度 100%，同表單恢復暫存值 | 自製，Jeffrey Chen／MIT |
| [redmine_default_watchers](redmine_default_watchers/README.md) | 1.1.0 | 合併全域與專案的預設觀察者 | 自製，Jeffrey Chen／MIT |
| [redmine_due_date_protection](redmine_due_date_protection/README.md) | 1.0.3 | 到期日欄位限制與授權設定；目前有覆蓋限制 | 自製，Jeffrey Chen／MIT |
| [redmine_html_attachment_preview](redmine_html_attachment_preview/README.md) | 1.2.0 | HTML 附件及票內 htmlview 渲染，支援另開分頁 | 自製，Jeffrey Chen／MIT |
| [redmine_mermaid_macro](redmine_mermaid_macro/README.md) | 1.2.0 | Mermaid 巨集與 fenced block、動態預覽 | 本地改版，Taiki IKEGAME／MIT |
| [redmine_wysiwyg_editor](redmine_wysiwyg_editor/README.md) | 0.32.0 | 視覺化編輯器，保留 Mermaid/htmlview 來源標記 | 本地改版，Takeshi Nakamura／GPL-2.0 |

版本來自各目錄的 init.rb；本地改版版本不代表上游發佈了相同功能。上游來源、原始文件與授權見 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 安裝

先取得集合，再將需要的**插件目錄**複製到 Redmine 的 plugins/：

```bash
git clone https://github.com/JeffreyChenTaiwan/redmine-plugins.git
cp -a redmine-plugins/redmine_html_attachment_preview /path/to/redmine/plugins/
```

其他插件以相同方式複製。請保留目錄名稱，例如 redmine_html_attachment_preview；整個集合目錄不直接作為單一插件安裝。

依各插件 README 設定後，重載 Redmine 應用程式。在「管理 → 插件」確認載入，再測試票單／Wiki 及編輯預覽。這七個插件目前沒有資料庫 Migration。視覺化編輯器需在專案啟用 visual_editor 模組；npm 套件用於開發及測試，執行資產已隨目錄附上。

HTML 預覽會停用預覽文件的 JavaScript，並保留隔離 iframe。票內用法：

````markdown
```htmlview
<style>h2 { color: #1565c0; }</style>
<h2>測試報告</h2>
<p>直接顯示 HTML 排版，右上角可另開分頁。</p>
```
````

一般 html fenced block 仍顯示原始碼。Mermaid 巨集與 mermaid fenced block 可並用，詳見該插件說明。

## 目前已知限制

- 自動指派及自動完成度主要作用於瀏覽器表單，不涵蓋所有 API／背景更新；manager 依賴來源環境沒有提供的 Project.manager。
- 到期日保護 1.0.3 的後端 Patch 在來源環境的新 production 進程未掛載，前後端授權判斷也有差異；目前不能作為完整的後端到期日保護。詳見插件 README。
- 自動指派的自訂 index、到期日保護的 project 模板缺少；請使用文件所述的原生／全域設定入口。
- 預設觀察者與到期日保護的管理權限及專案動作映射有既有缺口；請以各插件的實作限制為準。
- Mermaid 需瀏覽器能載入所設定的外部 ESM 與 ELK 模組。HTML 預覽只顯示靜態 HTML/CSS/SVG；相對路徑資源不自動對應其他附件。
- 編輯器的格式轉換並非完全可逆，修改巨集或特殊 HTML 後請核對文字與預覽。

## 測試與維護

[VALIDATION.md](VALIDATION.md) 記錄本次來源比對與測試方式。各插件 README 包含設定、功能及實際核對日期；較早的測試紀錄保留原日期，不代表每次整理都重跑全部功能。

備份檔、節點依賴、執行資料、附件實體及憑證不包含在本集合。兩個上游的原始 Git 歷史保留，每個插件目錄內仍保留原作者及授權。

## 授權

自製插件沿用本儲存庫原有的 [MIT LICENSE](LICENSE)，各自附有相同授權檔。Mermaid 保留原作者的 MIT 授權；WYSIWYG 保留 GPL-2.0 與內附第三方元件的授權。根目錄 MIT 不取代第三方插件或元件的原有授權。
