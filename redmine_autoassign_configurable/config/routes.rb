# plugins/redmine_autoassign_configurable/config/routes.rb
RedmineApp::Application.routes.draw do
  match 'redmine_autoassign', :to => 'redmine_autoassign#index', :via => [:get]
  match 'redmine_autoassign/save', :to => 'redmine_autoassign#save', :via => [:post]
  match 'redmine_autoassign/new_rule', :to => 'redmine_autoassign#new_rule', :via => [:get]
end
