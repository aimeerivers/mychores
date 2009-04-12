ActionController::Routing::Routes.draw do |map|

  map.resources 'testimonials'

  map.contact 'contact', :controller => 'messages', :action => 'new'
  map.sitemap 'sitemap', :controller => 'home', :action => 'sitemap'
  map.search 'search', :controller => 'home', :action => 'search'
  
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
