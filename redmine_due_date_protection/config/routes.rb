RedmineApp::Application.routes.draw do
  get 'due_date_protection', :to => 'redmine_due_date_protection#index'
  post 'due_date_protection/save', :to => 'redmine_due_date_protection#save'
  get 'due_date_protection/project/:project_id', :to => 'redmine_due_date_protection#project'
  post 'due_date_protection/project/:project_id/save', :to => 'redmine_due_date_protection#project_save'
end
