class RedmineDueDateProtectionController < ApplicationController
  layout 'admin'
  before_action :require_admin, :except => [:project, :project_save]
  before_action :find_project_by_project_id, :only => [:project, :project_save]
  before_action :authorize, :only => [:project, :project_save]

  def index
    @settings = Setting.plugin_redmine_due_date_protection || {}
    if @settings['protection_enabled'].nil?
      @settings['protection_enabled'] = '1'
    end

    @settings['global_authorized_users'] ||= []
    @settings['global_authorized_groups'] ||= []
    @settings['project_settings'] ||= {}

    @active_users = User.active.sorted.to_a
    @active_groups = Group.givable.sorted.to_a
    @projects = Project.active.sorted.to_a
  end

  def save
    setting = params[:settings] || {}

    # 強制將下拉選單的值存為 '1' 或 '0'
    input_value = setting[:protection_enabled].to_s
    setting[:protection_enabled] = (input_value == '1' ? '1' : '0')

    # 處理全域授權使用者
    global_users = []
    if setting[:global_authorized_users].present?
      setting[:global_authorized_users].each do |user_id|
        next if user_id.blank?
        user_id_int = user_id.to_i
        if user_id_int > 0 && User.exists?(user_id_int)
          global_users << user_id_int
        end
      end
    end
    setting[:global_authorized_users] = global_users

    # 處理全域授權群組
    global_groups = []
    if setting[:global_authorized_groups].present?
      setting[:global_authorized_groups].each do |group_id|
        next if group_id.blank?
        group_id_int = group_id.to_i
        if group_id_int > 0 && Group.exists?(group_id_int)
          global_groups << group_id_int
        end
      end
    end
    setting[:global_authorized_groups] = global_groups

    # 處理專案設定
    project_settings = {}
    if setting[:project_settings].present?
      setting[:project_settings].each do |project_id, config|
        project_config = {}

        if config[:authorized_users].present?
          users = []
          config[:authorized_users].each do |user_id|
            next if user_id.blank?
            user_id_int = user_id.to_i
            if user_id_int > 0 && User.exists?(user_id_int)
              users << user_id_int
            end
          end
          project_config['authorized_users'] = users if users.any?
        end

        if config[:authorized_groups].present?
          groups = []
          config[:authorized_groups].each do |group_id|
            next if group_id.blank?
            group_id_int = group_id.to_i
            if group_id_int > 0 && Group.exists?(group_id_int)
              groups << group_id_int
            end
          end
          project_config['authorized_groups'] = groups if groups.any?
        end

        project_settings[project_id] = project_config if project_config.any?
      end
    end
    setting[:project_settings] = project_settings

    Setting.plugin_redmine_due_date_protection = setting
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'index'
  rescue => e
    Rails.logger.error "[DueDateProtection] Save error: #{e.message}"
    flash[:error] = "#{l(:notice_save_failed)}: #{e.message}"
    redirect_to action: 'index'
  end

  def project
    @settings = Setting.plugin_redmine_due_date_protection || {}
    project_settings = (@settings['project_settings'] || {})[@project.id.to_s] || {}
    @project_authorized_users = project_settings['authorized_users'] || []
    @project_authorized_groups = project_settings['authorized_groups'] || []

    @project_users = User.active.joins(:members).where(members: { project_id: @project.id }).sorted.to_a
    @available_groups = Group.givable.sorted.to_a
  end

  def project_save
    setting = Setting.plugin_redmine_due_date_protection || {}
    setting['project_settings'] ||= {}
    project_config = {}

    if params[:authorized_users].present?
      users = []
      params[:authorized_users].each do |user_id|
        next if user_id.blank?
        user_id_int = user_id.to_i
        if user_id_int > 0 && User.exists?(user_id_int)
          users << user_id_int
        end
      end
      project_config['authorized_users'] = users if users.any?
    end

    if params[:authorized_groups].present?
      groups = []
      params[:authorized_groups].each do |group_id|
        next if group_id.blank?
        group_id_int = group_id.to_i
        if group_id_int > 0 && Group.exists?(group_id_int)
          groups << group_id_int
        end
      end
      project_config['authorized_groups'] = groups if groups.any?
    end

    if project_config.any?
      setting['project_settings'][@project.id.to_s] = project_config
    else
      setting['project_settings'].delete(@project.id.to_s)
    end

    Setting.plugin_redmine_due_date_protection = setting
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'project', project_id: @project
  rescue => e
    Rails.logger.error "[DueDateProtection] Project save error: #{e.message}"
    flash[:error] = "#{l(:notice_save_failed)}: #{e.message}"
    redirect_to action: 'project', project_id: @project
  end

  private

  def find_project_by_project_id
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
