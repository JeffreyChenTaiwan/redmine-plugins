# 來源與本地修改

- 上游：[https://github.com/taikii/redmine_mermaid_macro](https://github.com/taikii/redmine_mermaid_macro)
- 原作者：依 init.rb 與 LICENSE 原樣保留。
- 匯入的上游基準：`ec1be0b217c2396605323f3d23d55f927059b35b`。
- 上游原始使用說明：[README.upstream.md](README.upstream.md)。
- 本地版本與功能說明：[README.md](README.md)。
- 原有 Git 提交歷史與授權檔保留；本地修改不代表上游官方發佈。

本地新增 Markdown/CommonMark Mermaid fenced block，保留既有巨集；共用初始化、ELK loader、依序繪圖及 AJAX 預覽。

2026/10/21 的本地 1.2.4 改為直接匯入可設定的 Mermaid/ELK URL，移除額外 importmap；修正自動啟動時序與只有 data-processed 標記就被略過的情況，並加入頁面診斷及合成回歸測試。公開預設使用 CDN，沒有包含個別部署環境設定。此版本號為本地登記版本，不代表上游發佈。
