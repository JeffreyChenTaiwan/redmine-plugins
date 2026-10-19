# plugins/redmine_default_watchers/app/controllers/redmine_default_watchers_controller.rb
class RedmineDefaultWatchersController < ApplicationController
  layout 'admin'
  before_action :require_admin, :except => [:project, :project_save]
  before_action :find_project_by_project_id, :only => [:project, :project_save]
  before_action :authorize, :only => [:project, :project_save]

  def index
    @settings = Setting.plugin_redmine_default_watchers
    @settings['global_watchers'] ||= []
    @settings['project_watchers'] ||= {}
    
    @active_users = User.active.sorted.to_a
    @active_groups = Group.givable.sorted.to_a
    @projects = Project.active.sorted.to_a
    
    # 建立包含使用者和群組的選項
    @user_group_options = build_user_group_options(@active_users, @active_groups)
  end

  def save
    setting = params[:settings] || {}
    
    # 處理全域觀察者
    global_watchers = []
    if setting[:global_watchers].present?
      setting[:global_watchers].each do |watcher_id|
        if watcher_id.present? && valid_watcher?(watcher_id)
          global_watchers << watcher_id
        end
      end
    end
    setting[:global_watchers] = global_watchers

    # 處理專案觀察者
    project_watchers = {}
    if setting[:project_watchers].present?
      setting[:project_watchers].each do |project_id, watchers|
        if watchers.present?
          valid_watchers = []
          watchers.each do |watcher_id|
            if watcher_id.present? && valid_watcher?(watcher_id)
              valid_watchers << watcher_id
            end
          end
          project_watchers[project_id] = valid_watchers if valid_watchers.any?
        end
      end
    end
    setting[:project_watchers] = project_watchers

    Setting.plugin_redmine_default_watchers = setting
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'index'
  end

  def project
    @settings = Setting.plugin_redmine_default_watchers
    @project_watchers = (@settings['project_watchers'] || {})[@project.id.to_s] || []
    
    # 獲取專案成員（使用者）和可用群組
    @project_users = User.active.joins(:members).where(members: { project_id: @project.id }).sorted.to_a
    @available_groups = Group.givable.sorted.to_a
    
    # 建立包含使用者和群組的選項
    @user_group_options = build_user_group_options(@project_users, @available_groups)
  end

  def project_save
    setting = Setting.plugin_redmine_default_watchers
    setting['project_watchers'] ||= {}
    
    watchers = []
    if params[:project_watchers].present?
      params[:project_watchers].each do |watcher_id|
        if watcher_id.present? && valid_watcher?(watcher_id)
          # 對於使用者，額外檢查專案權限
          if watcher_id.start_with?('user:')
            user_id = watcher_id.split(':')[1]
            user = User.find_by_id(user_id)
            if user && user.active? && user.allowed_to?(:view_issues, @project)
              watchers << watcher_id
            end
          else
            # 群組不需要額外檢查，因為群組成員的權限會在運行時檢查
            watchers << watcher_id
          end
        end
      end
    end
    
    if watchers.any?
      setting['project_watchers'][@project.id.to_s] = watchers
    else
      setting['project_watchers'].delete(@project.id.to_s)
    end

    Setting.plugin_redmine_default_watchers = setting
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'project', project_id: @project
  end

  def add_project_watcher
    @project_id = params[:project_id]
    @watcher_index = params[:index].to_i
    
    # 獲取專案成員和可用群組
    if @project_id.present?
      project = Project.find(@project_id)
      @project_users = User.active.joins(:members).where(members: { project_id: project.id }).sorted.to_a
      @available_groups = Group.givable.sorted.to_a
      @user_group_options = build_user_group_options(@project_users, @available_groups)
    else
      @user_group_options = []
    end

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  private

  def find_project_by_project_id
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def valid_watcher?(watcher_id)
    if watcher_id.start_with?('user:')
      user_id = watcher_id.split(':')[1]
      User.exists?(user_id)
    elsif watcher_id.start_with?('group:')
      group_id = watcher_id.split(':')[1]
      Group.exists?(group_id)
    else
      false
    end
  end

  def build_user_group_options(users, groups)
    options = []
    
    # 添加使用者選項
    if users.any?
      user_options = users.map { |user| ["#{user.name} (#{user.login})", "user:#{user.id}"] }
      options << [l(:label_users), user_options]
    end
    
    # 添加群組選項
    if groups.any?
      group_options = groups.map { |group| [group.name, "group:#{group.id}"] }
      options << [l(:label_groups), group_options]
    end
    
    options
  end
end
