Redmine::Plugin.register :leaderboard do
  name 'Leaderboard plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

Proc.new do
  Redmine::Helpers::Calendar.send(:include, CalendarPatch)
end.call