require 'json'

# Run with Redmine's environment already loaded. This never saves issues or attachments.
source = <<~HTML
  <!DOCTYPE html>
  <html><head>
  <base href="https://example.invalid/">
  <meta http-equiv="REFRESH" content="0;url=https://example.invalid/">
  <style>body { background: rgb(234, 245, 255); } h1 { color: rgb(12, 34, 56); }</style>
  </head><body>
  <h1>中文 HTML &amp; SVG</h1>
  <a href="#chapter">目錄</a>
  <p>literal &lt;/iframe&gt; &lt;script&gt; and &amp; entities</p>
  <svg viewBox="0 0 100 100"><text x="10" y="20">圖表</text></svg>
  <script>parent.htmlviewEscaped = true; document.body.dataset.scriptRan = 'yes';</script>
  <img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" onload="parent.htmlviewEscaped = true">
  <form action="/blocked-form" method="post"><input name="example" value="test"><button>Submit</button></form>
  <div style="height: 1400px"></div><h2 id="chapter">章節</h2>
  </body></html>
HTML

markdown = "```htmlview\n#{source}```\n\n```html\n<h1>Plain HTML source</h1>\n```\n\n" \
           "~~~htmlview\n<h2>第二個區塊</h2>\n~~~\n\n" \
           "````text\n```htmlview\n<h1>Literal example</h1>\n```\n````"

head = RedmineHtmlAttachmentPreview::ViewHook.instance.view_layouts_base_html_head.to_s
bodies = %w[common_mark markdown].to_h do |format|
  [format, Redmine::WikiFormatting.to_html(format, markdown)]
end
view = AttachmentsController.new.view_context
attachment = view.render_file_content(Attachment.new(:filename => 'report.html'), source).to_s
fixture = { :head => head, :bodies => bodies, :source => source, :attachment => attachment }
File.write(ENV.fetch('HTMLVIEW_FIXTURE', '/tmp/redmine-htmlview-fixture.json'), JSON.pretty_generate(fixture))
puts 'PASS: generated actual Redmine formatter, hook and attachment fixtures without saving data'
