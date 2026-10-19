module RedmineHtmlAttachmentPreview
  class ViewHook < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('html_attachment_preview', :plugin => 'redmine_html_attachment_preview', :media => 'all') +
        javascript_include_tag('htmlview', :plugin => 'redmine_html_attachment_preview', :defer => true,
                               :data => {
                                 :htmlview_policy => HtmlDocument::CONTENT_SECURITY_POLICY,
                                 :htmlview_title => l(:label_html_attachment_preview),
                                 :htmlview_source => l(:label_html_attachment_source),
                                 :htmlview_open => l(:label_html_attachment_open)
                               })
    end
  end
end
