# plugins/redmine_default_watchers/config/routes.rb
RedmineApp::Application.routes.draw do
  match 'default_watchers', :to => 'redmine_default_watchers#index', :via => [:get]
  match 'default_watchers/save', :to => 'redmine_default_watchers#save', :via => [:post]
  match 'default_watchers/project/:project_id', :to => 'redmine_default_watchers#project', :via => [:get]
  match 'default_watchers/project/:project_id/save', :to => 'redmine_default_watchers#project_save', :via => [:post]
  match 'default_watchers/add_project_watcher', :to => 'redmine_default_watchers#add_project_watcher', :via => [:get]
end
