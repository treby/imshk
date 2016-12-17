require 'octokit'

# Provide authentication credentials
Octokit.configure do |c|
  c.login = ENV['KONOMIN_USERNAME']
  c.password = ENV['KONOMIN_PASSWORD']
end

# Fetch the current user
p Octokit.user
