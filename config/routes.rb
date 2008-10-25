ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "home"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
	# Allow something like /person/sermoa
	# which maps to /people/show/1
	map.connect 'person/:login',
		:controller => 'people',
		:action => 'show_by_login'
  
	# Quick turn on and off of email settings
	map.connect 'subscription/:id/:code/:key/:value',
		:controller => 'admin',
		:action => 'subscription_options'
  
	# Allow something like /statistics/monthly/2007/1
	map.connect 'statistics/monthly/:year/:month',
		:controller => 'statistics',
		:action => 'monthly'

	# Install the default route as the lowest priority.
	map.connect ':controller/:action/:id'
	map.connect ':controller/:action/:id.:format'
	map.connect ':controller/:action.:format'
end
