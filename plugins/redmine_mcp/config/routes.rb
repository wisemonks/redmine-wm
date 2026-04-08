# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'mcp', to: 'mcp#handle'
get 'mcp', to: 'mcp#handle'
delete 'mcp', to: 'mcp#handle'
get 'mcp/health', to: 'mcp#health'
