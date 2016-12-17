require 'octokit'
require 'git'

repo = 'git@github.com:treby/mlborder.git'
target_dir = 'mlborder'
git_name = 'konomin-bot'
git_email = 'mlborder@atelier-nodoka.net'

g = Git.clone(repo, '', path: target_dir)
g.config('user.name', git_name)
g.config('user.email', git_email)
branch_name = "update-seed-#{Time.now.strftime('%F-%H-%M')}"
g.branch(branch_name).checkout

`heroku run --app mlborder rails runner 'ActiveRecord::Base.logger = nil; puts Event.dump_seeds' | nkf -Lu > #{target_dir}/db/seeds.rb`
g.add
g.commit('Update db/seeds.rb')
g.push('origin', branch_name)

cli = Octokit::Client.new(login: ENV['KONOMIN_USERNAME'], password: ENV['KONOMIN_PASSWORD'])
cli.login
cli.create_pull_request 'treby/mlborder', 'master', branch_name, 'お疲れ様、プロデューサー', 'seedファイルを更新しておいたわよ'
