set :branch, 'stable'
set :rvm_ruby_version, '2.2.1@ridepilot'
set :passenger_rvm_ruby_version, '2.2.1@passenger'
set :deploy_to, '/home/deploy/rails/ridepilot'
set :default_env, { "RAILS_RELATIVE_URL_ROOT" => "/ridepilot" }

# capistrano-rails directives
set :rails_env, 'production'
set :assets_roles, [:web, :app]
set :migration_role, [:db]
set :conditionally_migrate, false
set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

server 'apps.rideconnection.org', roles: [:app, :web, :db], user: 'deploy'
