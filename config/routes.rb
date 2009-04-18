ActionController::Routing::Routes.draw do |map|

  map.resources 'testimonials', :except => [:show, :destroy]
  map.resources 'questions', :as => 'faq'
  map.resources :teams, :member => {:workload => :get}

  map.contact 'contact', :controller => 'messages', :action => 'new'
  map.sitemap 'sitemap', :controller => 'home', :action => 'sitemap'
  map.search 'search', :controller => 'home', :action => 'search'
  map.privacy 'privacy', :controller => 'home', :action => 'privacy'
  map.welcome 'welcome', :controller => 'home', :action => 'welcome'
  
  map.workload 'workload', :controller => 'tasks', :action => 'workload'
  map.hotmap 'hotmap', :controller => 'tasks', :action => 'matrix'
  map.calendar 'calendar', :controller => 'tasks', :action => 'calendar'
  map.collage 'collage', :controller => 'tasks', :action => 'collage'
  map.my_statistics 'my_statistics', :controller => 'tasks', :action => 'statistics'
  map.print 'print', :controller => 'tasks', :action => 'print'
  
  map.login 'login', :controller => 'admin', :action => 'login'
  map.logout 'logout', :controller => 'admin', :action => 'logout'
  map.register 'register', :controller => 'admin', :action => 'register'
  
  
  map.root :controller => 'home'

  # Allow something like /person/sermoa
  # which maps to /people/show/1
  map.connect 'person/:login',
    :controller => 'people',
    :action => 'show_by_login'

  # Quick turn on and off of email settings
  map.connect 'subscription/:id/:code/:key/:value',
    :controller => 'admin',
    :action => 'subscription_options'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action.:format'
end
