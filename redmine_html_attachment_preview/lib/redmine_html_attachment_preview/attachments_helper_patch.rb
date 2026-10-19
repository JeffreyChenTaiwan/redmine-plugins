module RedmineHtmlAttachmentPreview
  module AttachmentsHelperPatch
    def render_file_content(attachment, content)
      return super unless /\.html?\z/i.match?(attachment.filename.to_s)

      render :partial => 'html_attachment_preview/preview', :locals => {
        :attachment => attachment,
        :content => content,
        :preview_document => html_attachment_preview_document(content)
      }
    end

    private

    def html_attachment_preview_document(content)
      HtmlDocument.prepare(content)
    end
  end
end
