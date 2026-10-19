require 'minitest/autorun'

# Run with Redmine's environment already loaded (see README).
class HtmlAttachmentPreviewTest < Minitest::Test
  def setup
    @view = AttachmentsController.new.view_context
  end

  def preview(content, filename = 'report.html')
    attachment = Attachment.new(:filename => filename)
    Nokogiri::HTML.fragment(@view.render_file_content(attachment, content).to_s)
  end

  def test_html_extensions_render_as_pages
    %w[report.html REPORT.HTML report.htm REPORT.HTM].each do |filename|
      fragment = preview('<h1>Report</h1>', filename)
      assert_equal 1, fragment.css('iframe').size
      document = Nokogiri::HTML(fragment.at_css('iframe')['srcdoc'])
      assert_equal 'Report', document.at_css('h1').text
    end
  end

  def test_binary_utf8_and_svg_are_preserved
    fragment = preview('<h1>中文報告</h1><svg viewBox="0 0 100 100"><text>圖表</text></svg>'.b)
    document = Nokogiri::HTML(fragment.at_css('iframe')['srcdoc'])
    assert_equal '中文報告', document.at_css('h1').text
    assert_equal '圖表', document.at_css('svg text').text
  end

  def test_plain_text_keeps_redmine_source_preview
    fragment = preview('ordinary text', 'report.txt')
    assert_empty fragment.css('iframe')
    assert fragment.at_css('table.filecontent')
    assert_includes fragment.text, 'ordinary text'
  end

  def test_attachment_markup_cannot_escape_into_parent_page
    fragment = preview('<style>body { color: red; }</style><script>parent.previewEscaped = true;</script><p>literal &lt;/iframe&gt;</p>')
    assert_equal 1, fragment.css('iframe').size
    assert_empty fragment.css('script, style')
    assert_equal '', fragment.at_css('iframe')['sandbox']
    assert fragment.at_css('iframe').key?('sandbox')
    assert_equal 'no-referrer', fragment.at_css('iframe')['referrerpolicy']
    assert fragment.at_css('details table.filecontent')
  end

  def test_active_content_is_blocked_before_attachment_styles
    document = Nokogiri::HTML(preview('<style>body { color: red; }</style>').at_css('iframe')['srcdoc'])
    policy = document.at_css('meta[http-equiv="Content-Security-Policy"]')
    assert policy
    children = document.at_css('head').element_children.to_a
    assert_operator children.index(policy), :<, children.index(document.at_css('style'))
    %w[script-src connect-src frame-src object-src form-action].each do |directive|
      assert_includes policy['content'], "#{directive} 'none'"
    end
  end

  def test_fragment_links_stay_in_preview_and_refresh_redirects_are_removed
    fragment = preview('<base href="https://example.invalid/"><meta http-equiv="REFRESH" content="0;url=https://example.invalid/"><a href="#chapter">Chapter</a><h2 id="chapter">Chapter</h2>')
    document = Nokogiri::HTML(fragment.at_css('iframe')['srcdoc'])
    assert_equal 1, document.css('base').size
    assert_equal 'about:srcdoc', document.at_css('base')['href']
    assert_equal '#chapter', document.at_css('a')['href']
    assert document.css('meta[http-equiv]').none? { |node| node['http-equiv'].casecmp('refresh').zero? }
  end

  def test_layout_hook_loads_shared_policy_and_localized_assets
    fragment = Nokogiri::HTML.fragment(RedmineHtmlAttachmentPreview::ViewHook.instance.view_layouts_base_html_head.to_s)
    assert_includes fragment.at_css('link')['href'], '/redmine_html_attachment_preview/stylesheets/html_attachment_preview.css'
    script = fragment.at_css('script')
    assert_includes script['src'], '/redmine_html_attachment_preview/javascripts/htmlview.js'
    assert script.key?('defer')
    assert_equal RedmineHtmlAttachmentPreview::HtmlDocument::CONTENT_SECURITY_POLICY, script['data-htmlview-policy']
    assert_equal I18n.t(:label_html_attachment_preview), script['data-htmlview-title']
    assert_equal I18n.t(:label_html_attachment_source), script['data-htmlview-source']
    assert_equal I18n.t(:label_html_attachment_open), script['data-htmlview-open']
  end

  def test_commonmark_htmlview_keeps_editable_source_for_browser_rendering
    source = '<style>body { color: red; }</style><h1>中文 &amp; SVG</h1><script>parent.escaped = true;</script>'
    %w[``` ~~~].each do |fence|
      html = Redmine::WikiFormatting.to_html('common_mark', "#{fence}htmlview\n#{source}\n#{fence}")
      fragment = Nokogiri::HTML.fragment(html)
      assert_equal source + "\n", fragment.at_css('pre > code[data-language="htmlview"]').text
      assert_empty fragment.css('iframe, script, style, h1')
    end
  end

  def test_commonmark_html_keeps_code_language
    html = Redmine::WikiFormatting.to_html('common_mark', "```html\n<h1>Source</h1>\n```")
    fragment = Nokogiri::HTML.fragment(html)
    assert_equal "<h1>Source</h1>\n", fragment.at_css('pre > code[data-language="html"]').text
    assert_empty fragment.css('iframe, h1')
  end
end
