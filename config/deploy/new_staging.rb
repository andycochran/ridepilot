set :branch, 'rails-upgrade'
set :rvm_ruby_version, '2.2.0@ridepilot'
set :deploy_to, '/home/deploy/rails/ridepilot'
set :rails_env, 'staging'
server 'apps2.rideconnection.org', roles: [:app, :web, :db], user: 'deploy'