require 'nokogiri'

module RedmineHtmlAttachmentPreview
  module HtmlDocument
    CONTENT_SECURITY_POLICY = "default-src 'none'; style-src 'unsafe-inline' https: http:; " \
                              "img-src data: https: http:; font-src data: https: http:; " \
                              "script-src 'none'; connect-src 'none'; frame-src 'none'; " \
                              "object-src 'none'; form-action 'none'; base-uri about:".freeze

    def self.prepare(content)
      html = Redmine::CodesetUtil.to_utf8_by_setting(content)
      document = Nokogiri::HTML::Document.parse(html, nil, 'UTF-8')
      document.add_child(Nokogiri::XML::Node.new('html', document)) unless document.root
      head = document.at_css('head')
      unless head
        head = Nokogiri::XML::Node.new('head', document)
        document.root.prepend_child(head)
      end

      # Keep fragment links inside srcdoc rather than loading Redmine in the frame.
      document.css('base').remove
      document.css('meta[http-equiv]').each do |node|
        node.remove if node['http-equiv'].to_s.casecmp('refresh').zero?
      end

      base = Nokogiri::XML::Node.new('base', document)
      base['href'] = 'about:srcdoc'
      head.prepend_child(base)

      referrer = Nokogiri::XML::Node.new('meta', document)
      referrer['name'] = 'referrer'
      referrer['content'] = 'no-referrer'
      head.prepend_child(referrer)

      policy = Nokogiri::XML::Node.new('meta', document)
      policy['http-equiv'] = 'Content-Security-Policy'
      policy['content'] = CONTENT_SECURITY_POLICY
      head.prepend_child(policy)

      document.internal_subset&.remove
      "<!DOCTYPE html>\n" + document.to_html
    end
  end
end
