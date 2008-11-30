load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

namespace :deploy do

  task :start, :roles => :app do
    run "rm -rf /home/#{user}/public_html;ln -s #{current_path}/public /home/#{user}/public_html"
    run "cd #{current_path} && mongrel_rails start -e production -p #{mongrel_port} -d"
  end

  task :restart, :roles => :app do
    run "cd #{current_path} && mongrel_rails stop && mongrel_rails start -e production -p #{mongrel_port} -d"
  end

end

task :after_update_code, :roles => :app do
  run "cp -pf #{deploy_to}/to_copy/.htaccess #{current_path}/public/.htaccess"
  run "cp -pf #{deploy_to}/to_copy/environment.rb #{current_path}/config/environment.rb"
  run "cp -pf #{deploy_to}/to_copy/database.yml #{current_path}/config/database.yml"
  run "ln -s #{deploy_to}/pictures #{current_path}/public/pictures"
  run "ln -s #{deploy_to}/exports #{current_path}/public/exports"
  run "chmod 0755 #{current_path}/public/dispatch.*"
end
