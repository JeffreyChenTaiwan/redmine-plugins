require 'redmine'
require_relative 'lib/redmine_due_date_protection/issues_controller_patch'

Redmine::Plugin.register :redmine_due_date_protection do
  name 'Redmine Due Date Protection Plugin'
  author 'Jeffrey Chen'
  description 'Restrict due date modification to authorized users and groups only.'
  version '1.0.3'
  url 'https://github.com/JeffreyChenTaiwan/redmine-plugins/tree/main/redmine_due_date_protection'
  author_url 'https://github.com/JeffreyChenTaiwan'

  settings :default => {
    'protection_enabled' => '1',
    'global_authorized_users' => [],
    'global_authorized_groups' => [],
    'project_settings' => {}
  }, :partial => 'settings/redmine_due_date_protection_settings'

  permission :manage_due_date_protection, {:redmine_due_date_protection => [:index, :save]}, :require => :admin
  permission :modify_due_date, {}, :public => false

  menu :admin_menu, :due_date_protection_settings,
       {:controller => 'redmine_due_date_protection', :action => 'index'},
       :caption => :label_due_date_protection_settings,
       :html => {:class => 'icon icon-lock'}

  menu :project_menu, :due_date_protection,
       {:controller => 'redmine_due_date_protection', :action => 'project'},
       :caption => :label_due_date_protection,
       :param => :project_id,
       :if => Proc.new { |p| User.current.allowed_to?(:manage_due_date_protection, p) }
end

Rails.configuration.to_prepare do
  unless IssuesController.included_modules.include?(RedmineDueDateProtection::IssuesControllerPatch)
    IssuesController.send(:include, RedmineDueDateProtection::IssuesControllerPatch)
  end
end

module RedmineDueDateProtection
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, :partial => 'hooks/redmine_due_date_protection/issues_form_details_bottom'
    render_on :view_issues_show_details_bottom, :partial => 'hooks/redmine_due_date_protection/issues_show_details_bottom'
  end
end
