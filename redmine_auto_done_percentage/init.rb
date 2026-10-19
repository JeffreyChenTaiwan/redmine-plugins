require 'redmine'

Redmine::Plugin.register :redmine_auto_done_percentage do
  name 'Redmine Auto Done Percentage Plugin'
  author 'Jeffrey Chen'
  description 'Automatically set issue done percentage to 100% when specific statuses are selected.'
  version '1.0.0'
  url 'https://github.com/JeffreyChenTaiwan/redmine-plugins/tree/main/redmine_auto_done_percentage'
  author_url 'https://github.com/JeffreyChenTaiwan'

  settings default: {
    'auto_complete_statuses' => []
  }, partial: 'settings/auto_done_percentage_settings'
end

# Load hooks
require_dependency File.dirname(__FILE__) + '/lib/redmine_auto_done_percentage/hooks'
