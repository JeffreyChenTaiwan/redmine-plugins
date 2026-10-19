require File.expand_path('lib/redmine_html_attachment_preview/attachments_helper_patch', __dir__)
require File.expand_path('lib/redmine_html_attachment_preview/view_hook', __dir__)

Redmine::Plugin.register :redmine_html_attachment_preview do
  name 'Redmine HTML Attachment Preview'
  author 'Jeffrey Chen'
  description 'Render HTML attachments and htmlview code blocks in isolated frames, with source available.'
  version '1.2.0'
  requires_redmine :version_or_higher => '5.0.0'
end

# Redmine already runs plugin initializers in its to_prepare callback.
unless AttachmentsHelper.ancestors.include?(RedmineHtmlAttachmentPreview::AttachmentsHelperPatch)
  AttachmentsHelper.prepend(RedmineHtmlAttachmentPreview::AttachmentsHelperPatch)
end
