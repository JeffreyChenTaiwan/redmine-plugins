# encoding: utf-8
require 'json'

# Load with Redmine's environment. Settings are overridden only in this process.
head = MermaidMacroHook.instance.view_layouts_base_html_head
fragment = Nokogiri::HTML.fragment(head)
script = fragment.at_css('script[type="module"]')
raise 'Mermaid module URL missing' unless script && script['data-redmine-mermaid-url'].present?
raise 'ELK module URL missing' unless script['data-redmine-mermaid-elk-url'].present?
raise 'Plugin must not add an import map' unless fragment.css('script[type="importmap"]').empty?

source = <<~MARKDOWN
  {{mermaid
  %%{init: {"layout": "elk"}}%%
  flowchart LR
    MacroA["巨集"] --> MacroB["ELK"]
  }}

  ```mermaid
  flowchart TD
    FenceA["A & B <br/> 中文"] --> FenceB
  ```

  ```ruby
  puts 'ordinary code'
  ```

  ````text
  ```mermaid
  flowchart TD
    LiteralA --> LiteralB
  ```
  ````
MARKDOWN

view = ApplicationController.new.view_context
original_format = Setting.method(:text_formatting)
bodies = {}
begin
  %w[common_mark markdown textile].each do |format|
    next unless Redmine::WikiFormatting.format_names.include?(format)
    Setting.singleton_class.define_method(:text_formatting) { format }
    html = view.textilizable(source).to_s
    body = Nokogiri::HTML.fragment(html)
    raise "Macro missing: #{format}" unless body.css('div.mermaid').size == 1
    if format != 'textile'
      raise "Fence missing: #{format}" unless body.css('code[data-language="mermaid"]').size == 1
      raise "Ordinary code changed: #{format}" unless body.at_css('code[data-language="ruby"]')
      raise "Literal example changed: #{format}" unless body.at_css('code[data-language="text"]').text.include?('LiteralA --> LiteralB')
    end
    bodies[format] = html
  end
ensure
  Setting.singleton_class.define_method(:text_formatting, original_format)
end

fixture = { version: Redmine::VERSION.to_s, ruby: RUBY_VERSION, rails: Rails.version, head: head.to_s, bodies: bodies }
path = ENV.fetch('MERMAID_FIXTURE', '/tmp/redmine-mermaid-fixture.json')
File.write(path, JSON.pretty_generate(fixture))
puts "PASS: generated #{bodies.keys.join(', ')} fixtures without changing database settings"
