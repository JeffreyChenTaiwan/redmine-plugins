# plugins/redmine_autoassign_configurable/app/controllers/redmine_autoassign_controller.rb
class RedmineAutoassignController < ApplicationController
  layout 'admin'
  before_action :require_admin

  def index
    @settings = Setting.plugin_redmine_autoassign_configurable
    # 獲取所有可用的問題狀態
    @available_statuses = IssueStatus.all.sorted.to_a
  end

  def save
    setting = params[:settings] || {}

    # 處理規則
    rules = []
    if setting[:rules].present?
      setting[:rules].each do |rule|
        if rule[:status].present? && rule[:assign_to].present?
          rules << rule
        end
      end
    end
    setting[:rules] = rules

    # 處理通知訊息
    notifications = {}
    if setting[:notifications].present?
      setting[:notifications].each do |lang, message|
        if message.present?
          notifications[lang] = message
        end
      end
    end
    setting[:notifications] = notifications

    Setting.plugin_redmine_autoassign_configurable = setting
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'index'
  end

  def new_rule
    @index = params[:index].to_i
    @rule = {
      'status' => params[:status] || '',
      'assign_to' => params[:assign_to] || ''
    }

    @active_users = User.active.sorted.to_a
    @user_options = [[l(:label_author), 'author'],
                    [l(:label_manager), 'manager'],
                    [l(:label_last_updater), 'last_updater']]

    # 添加所有活躍用戶到選項列表
    @active_users.each do |user|
      @user_options << ["#{user.name} (#{user.login})", "user:#{user.id}"]
    end
    
    # 獲取所有可用的問題狀態
    @available_statuses = IssueStatus.all.sorted.to_a

    respond_to do |format|
      format.js { render 'new_rule', layout: false }
    end
  end
end
