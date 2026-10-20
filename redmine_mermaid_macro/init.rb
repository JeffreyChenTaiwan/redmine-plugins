require File.expand_path('lib/mermaid_macro_hook', __dir__)

Redmine::Plugin.register :redmine_mermaid_macro do
  name 'Redmine Mermaid Macro plugin'
  author 'Taiki IKEGAME'
  description 'Add mermaid graphs using wiki macros or fenced Markdown code blocks.'
  version '1.2.4'
  url 'https://github.com/taikii/redmine_mermaid_macro'
  author_url 'https://taikii.github.io'
  settings :default => {
    'mermaid_url' => 'https://cdn.jsdelivr.net/npm/mermaid@11.16.1/dist/mermaid.esm.min.mjs',
    'elk_url' => 'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.2/dist/mermaid-layout-elk.esm.min.mjs'
  },
           :partial => 'settings/redmine_mermaid_macro_settings'

  Redmine::WikiFormatting::Macros.register do
    desc "Add mermaid graphs to your wiki. Example:\n\n" +
         "{{mermaid\n" +
         "graph TD;\n" +
         "    A-->B;\n" +
         "    A-->C;\n" +
         "    B-->D;\n" +
         "    C-->D;\n" +
         "}}"

    macro :mermaid do |obj, args, text|
      divid = "mermaid_" + SecureRandom.urlsafe_base64(8)
      content_tag(:div, text, id: divid, class: 'mermaid')
    end
  end
end
