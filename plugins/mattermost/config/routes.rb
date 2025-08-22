# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# get 'tasks', to: 'tasks#index', as: 'tasks'
# point /tasks GET request to plugins/mattermost/app/controllers/tasks_controller.rb
scope :mattermost do
  get 'tasks', to: 'tasks#index', as: 'mattermost_tasks'
  post 'start', to: 'tasks#start', as: 'mattermost_start'
  post 'review', to: 'tasks#review', as: 'mattermost_review'
  post 'resolve', to: 'tasks#resolve', as: 'mattermost_resolve'
  post 'finish', to: 'tasks#finish', as: 'mattermost_finish'
  post 'spent', to: 'tasks#spent', as: 'mattermost_spent'
end



# get 'review', to: 'tasks#review'
# get 'resolve', to: 'tasks#resolve'
# get 'finish', to: 'tasks#finish'
# post 'spent', to: 'tasks#spent'

# resources :tasks, only: [:index] do
#   member do
#     post :review
#     post :resolve
#     post :finish
#     post :spent
#   end
# end