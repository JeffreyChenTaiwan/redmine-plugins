# plugins/redmine_default_watchers/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_default_watchers do
  name 'Redmine Default Watchers Plugin'
  author 'Jeffrey Chen'
  description 'Automatically add default watchers (users and groups) to new issues based on project settings.'
  version '1.1.0'  # 更新版本號
  url 'https://github.com/JeffreyChenTaiwan/redmine-plugins/tree/main/redmine_default_watchers'
  author_url 'https://github.com/JeffreyChenTaiwan'

  # 專案層級設定
  settings :default => {
    'project_watchers' => {},
    'global_watchers' => []
  }, :partial => 'settings/redmine_default_watchers_settings'

  # 添加權限
  permission :manage_default_watchers, {:redmine_default_watchers => [:index, :save]}, :require => :admin

  # 添加管理菜單
  menu :admin_menu, :default_watchers_settings,
       {:controller => 'redmine_default_watchers', :action => 'index'},
       :caption => :label_default_watchers_settings,
       :html => {:class => 'icon icon-user'}

  # 添加專案菜單
  menu :project_menu, :default_watchers,
       {:controller => 'redmine_default_watchers', :action => 'project'},
       :caption => :label_default_watchers,
       :param => :project_id,
       :if => Proc.new { |p| User.current.allowed_to?(:manage_default_watchers, p) }
end

# 添加 Hook 來載入 JavaScript 和處理新問題創建
module RedmineDefaultWatchers
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, :partial => 'hooks/redmine_default_watchers/issues_form_details_bottom'
    
    # 在問題創建後自動添加觀察者
    def controller_issues_new_after_save(context={})
      issue = context[:issue]
      return unless issue && issue.persisted?
      add_default_watchers_to_issue(issue)
    end

    private

    def add_default_watchers_to_issue(issue)
      begin
        settings = Setting.plugin_redmine_default_watchers || {}
        
        # 獲取全域觀察者
        global_watchers = settings['global_watchers'] || []
        
        # 獲取專案特定觀察者
        project_watchers = settings['project_watchers'] || {}
        project_specific_watchers = project_watchers[issue.project_id.to_s] || []
        
        # 合併所有觀察者
        all_watchers = (global_watchers + project_specific_watchers).uniq.compact
        
        # 處理每個觀察者（可能是使用者或群組）
        all_watchers.each do |watcher_id|
          next unless watcher_id.present?
          
          if watcher_id.start_with?('user:')
            # 處理個別使用者
            user_id = watcher_id.split(':')[1]
            add_user_watcher(issue, user_id)
          elsif watcher_id.start_with?('group:')
            # 處理群組 - 添加群組中的所有成員
            group_id = watcher_id.split(':')[1]
            add_group_watchers(issue, group_id)
          end
        end
        
      rescue => e
        # 記錄錯誤但不中斷問題創建流程
        Rails.logger.error "RedmineDefaultWatchers: Error adding watchers to issue #{issue.id}: #{e.message}"
      end
    end
    
    def add_user_watcher(issue, user_id)
      user = User.find_by_id(user_id.to_i)
      if user && user.active? && user.allowed_to?(:view_issues, issue.project)
        unless issue.watched_by?(user)
          Watcher.create(:watchable => issue, :user => user)
        end
      end
    end
    
    def add_group_watchers(issue, group_id)
      group = Group.find_by_id(group_id.to_i)
      return unless group
      
      # 獲取群組中有權限查看問題的活躍成員
      group.users.active.each do |user|
        if user.allowed_to?(:view_issues, issue.project)
          unless issue.watched_by?(user)
            Watcher.create(:watchable => issue, :user => user)
          end
        end
      end
    end
  end
end
