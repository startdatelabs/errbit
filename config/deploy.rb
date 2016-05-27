# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap errbit:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to ./docs/deployment/capistrano.md for more info

# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'errbit'

# Repository
set :scm, :git
set :scm_verbose, false
set :repo_url, 'git@github.com:startdatelabs/errbit.git'
set :git_enable_submodules, false


set :branch, ENV['branch'] || 'master'
set :deploy_to, '/var/data/www/apps/errbit'
set :keep_releases, 5

set :default_env, {
  'RAILS_ROOT' => release_path,
  # 'BUNDLE_GEMFILE' => release_path.join('Gemfile'),
  'RAILS_ENV' => fetch(:rails_env)
}

set :pty, false
set :ssh_options, {
  forward_agent: true
}

set :linked_files, fetch(:linked_files, []) + %w(
  .env
)

set :linked_dirs, fetch(:linked_dirs, []) + %w(
  log
  tmp/cache tmp/pids tmp/sockets
  vendor/bundle
  tmp/minified_js
  tmp/maps_js
)

set :log_level, :debug

# Rvm
set :rvm_roles, [:app, :web, :db]
set :rvm_type, :user
set :rvm_ruby_version, '2.3.0@errbit'

# Unicorn
set :unicorn_pid, -> { "#{ current_path }/tmp/pids/unicorn.pid" }
set :unicorn_config_path, -> { "#{ release_path }/config/unicorn.rb" }
after 'deploy:publishing', 'deploy:restart'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end
end

before "deploy:assets:precompile", "deploy:npm_install"

namespace :deploy do
  desc "Run npm install"
  task :npm_install do
    invoke_command "bash -c '. /home/deploy/.nvm/nvm.sh && cd #{release_path} && npm install'"
  end
end

namespace :errbit do
  desc "Setup config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/pids"
      execute "touch #{shared_path}/.env"

      {
        'config/newrelic.example.yml' => 'config/newrelic.yml',
        'config/unicorn.default.rb' => 'config/unicorn.rb',
      }.each do |src, target|
        unless test("[ -f #{shared_path}/#{target} ]")
          upload! src, "#{shared_path}/#{target}"
        end
      end
    end
  end
end

namespace :db do
  desc "Create and setup the mongo db"
  task :setup do
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'errbit:bootstrap'
        end
      end
    end
  end
end
