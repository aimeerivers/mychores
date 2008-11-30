set :application, 'mychores'
set :user, 'mychore'
set :domain, 'wycliffe'

set :server_hostname, 'mychores.co.uk'

role :web, server_hostname
role :app, server_hostname
role :db, server_hostname

default_run_options[:pty] = true
set :repository,  "git@github.com:sermoa/#{application}.git"
set :scm, "git"
set :user, "mychore"

ssh_options[:forward_agent] = true
set :branch, "master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :git_enable_submodules, 1
set :deploy_to, "/home/#{user}/#{application}"

