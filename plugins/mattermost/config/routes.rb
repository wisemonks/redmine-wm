# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tasks', to: 'mattermost/tasks#index'
get 'review', to: 'mattermost/tasks#review'
get 'resolve', to: 'mattermost/tasks#resolve'
get 'finish', to: 'mattermost/tasks#finish'
post 'spent', to: 'mattermost/tasks#spent'