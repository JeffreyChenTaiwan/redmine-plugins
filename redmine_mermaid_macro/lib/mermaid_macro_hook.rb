class MermaidMacroHook < Redmine::Hook::ViewListener
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  def view_layouts_base_html_head(context={})
    html = ''.html_safe
    html << stylesheet_link_tag('redmine_mermaid_macro.css', :plugin => 'redmine_mermaid_macro', :media => 'all')
    # Redmine 7 already supplies an import map. Some browsers ignore a second one.
    # Import the configured URL directly instead of adding a bare-specifier map.
    html << javascript_include_tag('redmine_mermaid_macro', :plugin => 'redmine_mermaid_macro', :type => 'module',
                                  :'data-redmine-mermaid-url' => Setting.plugin_redmine_mermaid_macro['mermaid_url'],
                                  :'data-redmine-mermaid-elk-url' => Setting.plugin_redmine_mermaid_macro['elk_url'].presence ||
                                    'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.2/dist/mermaid-layout-elk.esm.min.mjs')
    html
  end
end
