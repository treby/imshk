require 'octokit'
require 'git'

class KonominBotExecutor
  TARGET_REPOSITORY = 'mlborder/mlborder.com'
  TARGET_DIR = 'mlborder'
  GIT_USER_NAME = 'konomin-bot'
  GIT_USER_EMAIL = 'mlborder@atelier-nodoka.net'

  def execute
    git_agent = if Dir.exists?(TARGET_DIR)
                  Git.open(TARGET_DIR).tap do |g|
                    g.checkout('master')
                    g.pull
                  end
                else
                  Git.clone("git@github.com:#{TARGET_REPOSITORY}.git", '', path: TARGET_DIR)
                end

    git_agent.tap do |g|
      g.config('user.name', GIT_USER_NAME)
      g.config('user.email', GIT_USER_EMAIL)
      g.branch(branch_name).checkout
    end

    `heroku run --app mlborder rails runner 'ActiveRecord::Base.logger = nil; puts Event.dump_seeds' | nkf -Lu > #{TARGET_DIR}/db/seeds.rb`

    git_agent.tap do |g|
      g.add
      g.commit("Update db/seeds.rb #{time_stamp}")
      g.push('origin', branch_name)
    end

    github_agent.create_pull_request TARGET_REPOSITORY, 'master', branch_name, *message_from_konomin
  end

  def message_from_konomin
    ["Seed update #{time_stamp}",
     "お疲れ様、プロデューサー\n" + message_body]
  end

  def message_body
    ['疲れてる子がいないかちゃんと見ててよ？',
     'みんな、合言葉はセクシーよ！',
     '最後はなんとかしてあげるから、思い切って頑張りなさーい♪'
    ].sample(1).first
  end

  def github_agent
    unless @cli
      @cli = Octokit::Client.new(login: ENV['KONOMIN_USERNAME'], password: ENV['KONOMIN_PASSWORD'])
      @cli.login
    end
    @cli
  end

  def branch_name
    @branch_name ||= "update-seed-#{time_stamp}"
  end

  def time_stamp
    @time_stamp ||= Time.now.strftime('%Y%m%d-%H%M')
  end
end

KonominBotExecutor.new.execute
