# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# routes for salaries for user scope
resources :users do
  resources :salaries
end