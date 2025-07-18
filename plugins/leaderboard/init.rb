Redmine::Plugin.register :leaderboard do
  name 'Leaderboard plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  project_module :budgets do
    permission :view_budgets, { budgets: [:index] }, require: :admin
    permission :add_budget, { budgets: [:new, :create] }, require: :admin
    permission :edit_budget, { budgets: [:edit, :update] }, require: :admin
    permission :delete_budget, { budgets: [:destroy] }, require: :admin
  end


  menu :project_menu, :budgets, { controller: 'budgets', action: 'index' },
       caption: 'Budgets',
       after: :settings,
       param: :project_id,
       if: proc { |_project| 
        User.current.admin? && User.current.mail.in?(['arturas@wisemonks.com', 'rytis@wisemonks.com'])
      }
end

Proc.new do
  Redmine::Helpers::Calendar.send(:include, CalendarPatch)
end.call