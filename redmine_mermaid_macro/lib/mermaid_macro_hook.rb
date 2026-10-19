class MermaidMacroHook < Redmine::Hook::ViewListener
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  def view_layouts_base_html_head(context={})
    imports = { 'imports' => { 'mermaid' => Setting.plugin_redmine_mermaid_macro['mermaid_url'] } }

    html = ''.html_safe
    html << stylesheet_link_tag('redmine_mermaid_macro.css', :plugin => 'redmine_mermaid_macro', :media => 'all')
    # Import maps contain JSON, so do not wrap them in javascript_tag's CDATA comments.
    html << content_tag(:script, ERB::Util.json_escape(imports.to_json).html_safe, :type => 'importmap')
    html << javascript_include_tag('redmine_mermaid_macro', :plugin => 'redmine_mermaid_macro', :type => 'module')
    html
  end
end
