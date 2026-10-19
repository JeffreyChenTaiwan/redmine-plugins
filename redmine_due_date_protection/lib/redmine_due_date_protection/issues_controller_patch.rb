module RedmineDueDateProtection
  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do
        before_action :check_due_date_modification_permission, :only => [:update]
      end
    end

    private

    def check_due_date_modification_permission
      return unless params[:issue]

      begin
        @issue = Issue.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        return
      end

      new_due_date = params[:issue][:due_date]

      # 若日期未變更、為空、或原始日期為空，允許通過
      return if new_due_date.blank?
      return if @issue.due_date.blank?
      return if new_due_date == @issue.due_date.to_s

      unless can_modify_due_date?(User.current, @issue)
        Rails.logger.warn "[DueDateProtection] Blocked unauthorized change by #{User.current.login} on issue ##{@issue.id}"
        params[:issue].delete(:due_date)
        flash[:error] = l(:error_due_date_modification_not_permitted)
      end
    end

    def can_modify_due_date?(user, issue)
      return false if user.nil? || issue.nil?

      settings = Setting.plugin_redmine_due_date_protection || {}

      # 檢查開關 (必須是字串 '1')
      return true unless settings['protection_enabled'] == '1'

      # 如果問題還沒有到期日，允許任何人設定
      return true if issue.due_date.blank?

      global_users = Array(settings['global_authorized_users']).map(&:to_i).compact
      global_groups = Array(settings['global_authorized_groups']).map(&:to_i).compact

      project_settings = settings['project_settings'] || {}
      project_config = project_settings[issue.project_id.to_s] || {}
      project_users = Array(project_config['authorized_users']).map(&:to_i).compact
      project_groups = Array(project_config['authorized_groups']).map(&:to_i).compact

      authorized_user_ids = (global_users + project_users).uniq
      authorized_group_ids = (global_groups + project_groups).uniq
      user_group_ids = user.groups.pluck(:id)

      is_authorized = authorized_user_ids.include?(user.id) ||
                      (authorized_group_ids & user_group_ids).any?

      return is_authorized
    end
  end
end
