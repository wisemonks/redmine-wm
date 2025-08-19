# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

namespace :mattermost do  
  get 'tasks', to: 'tasks#index'
  get 'review', to: 'tasks#review'
  get 'resolve', to: 'tasks#resolve'
  get 'finish', to: 'tasks#finish'
  post 'spent', to: 'tasks#spent'
end