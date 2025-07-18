# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# routes for salaries for user scope
resources :users do
  resources :salaries
end

# routes for budgets for project scope
resources :projects do
  resources :budgets
end