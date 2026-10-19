# plugins/redmine_autoassign_configurable/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_autoassign_configurable do
  name 'Redmine Configurable Autoassign Plugin'
  author 'Jeffrey Chen'
  description 'Assign issues to specific users automatically when the status changes.'
  version '1.2.0'
  url 'https://github.com/JeffreyChenTaiwan/redmine-plugins/tree/main/redmine_autoassign_configurable'
  author_url 'https://github.com/JeffreyChenTaiwan'

  # 修改設定區塊
  settings :default => {
    'rules' => [
      {'status' => 'feedback', 'assign_to' => 'author'},
      {'status' => 'resolved', 'assign_to' => 'author'}
    ],
    'notifications' => {
      'en' => 'Automatically assigned to {name}',
      'zh-TW' => '已自動指派給 {name}',
      'zh-CN' => '已自动指派给 {name}',
      'ja' => '自動的に {name} に割り当てられました'
    }
  }, :partial => 'settings/redmine_autoassign_settings'

  # 添加權限
#  permission :manage_autoassign_settings, {:redmine_autoassign => [:index, :save]}, :require => :admin

  # 添加管理菜單
#  menu :admin_menu, :autoassign_settings,
#       {:controller => 'redmine_autoassign', :action => 'index'},
#       :caption => :label_autoassign_settings,
#       :html => {:class => 'icon icon-settings'}
end

# 添加 Hook 來載入 JavaScript
module RedmineAutoassignConfigurable
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, :partial => 'hooks/redmine_autoassign_configurable/issues_form_details_bottom'
  end
end
