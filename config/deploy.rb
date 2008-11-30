set :application, 'mychores'
set :user, 'mychore'
set :domain, 'wycliffe'


set :scm_passphrase,  Proc.new { Capistrano::CLI.password_prompt('Git Password: ') }

set :server_hostname, 'mychores.co.uk'

role :web, server_hostname
role :app, server_hostname
role :db, server_hostname, :primary => true

default_run_options[:pty] = true
set :repository,  "git@github.com:sermoa/#{application}.git"
set :scm, "git"
set :user, "mychore"

ssh_options[:forward_agent] = true
set :branch, "master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :git_enable_submodules, 1
set :use_sudo, false
set :deploy_to, "/home/#{user}/#{application}"

