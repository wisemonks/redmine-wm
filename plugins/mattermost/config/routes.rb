# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# get 'tasks', to: 'tasks#index', as: 'tasks'
# point /tasks GET request to plugins/mattermost/app/controllers/tasks_controller.rb
scope :mattermost do
  get 'tasks', to: 'tasks#index', as: 'mattermost_tasks'
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