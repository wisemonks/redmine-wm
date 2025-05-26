# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# route to add spent time to the issue via mattermost /spent command
match 'issues/spent', :to => 'task_pools#spent', :via => :post