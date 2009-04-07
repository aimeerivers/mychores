require 'login_system'
require 'boiler_plate'
gem 'recaptcha'



# require_dependency 'openid_login_system'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper(:all)

  include ReCaptcha::AppHelper

  filter_parameter_logging :password, :password_confirmation

  before_filter :set_charset
  def set_charset
    content_type = headers["Content-Type"] || "text/html"
    if /^text\//.match(content_type)
      headers["Content-Type"] = "#{content_type}; charset=utf-8"
    end
  end

  include LoginSystem
	
  # include OpenidLoginSystem
  # model :person
	
  # session :session_expires => 1.month.from_now
	

  prepend_before_filter :localize_date_format, :set_time_zone

  def localize_date_format
    # determine locale and set other relevant stuff
       
    if session[:preferred_short_date_format].nil?
      ActiveRecord::Base.date_format = '%d/%m/%Y'
    else
      ActiveRecord::Base.date_format = session[:preferred_short_date_format]
    end
    
  end

  def set_time_zone
    Time.zone = session[:person].timezone_name if session[:person]
  end
  
  protected
  
  def redirect_back(redirect_opts = nil)
    redirect_opts ||= {:controller => 'tasks', :action => 'workload'}
    request.env["HTTP_REFERER"] ? redirect_to(request.env["HTTP_REFERER"]) : redirect_to(redirect_opts)
  end

   
  
  private

  def html_escape(s)
    s.to_s.gsub(/&/n, '&').gsub(/\"/n, '"').gsub(/>/n, '>').gsub(/</n, '<')
  end
  alias h html_escape

  def link_to_person(to_link, specific_class)
    if to_link.usertype == 2
      return_string = "<span class='" + specific_class + " virtualperson'>" + h(to_link.name) + "</span>"
    elsif to_link.usertype == 3
      return_string = "<strike><span class='" + specific_class + " deletedperson'>" + h(to_link.name) + "</span></strike>"
    elsif to_link.usertype == 4
      return_string = "<span class='" + specific_class + " kid'>" + h(to_link.name) + "</span>"
    else
      return_string = "<a href='/person/" + to_link.login + "' class='" + specific_class + " person' title='" + h(to_link.name) + "'>" + h(to_link.login) + "</a>"
    end
    return return_string
  end

  def link_to_team(to_link, specific_class)
    if to_link.use_colour == true
      style=" style='background-color:#" + to_link.colour + "; color:#" + to_link.text_colour + ";'"
    else
      style=""
    end
    return_string = "<a href='/teams/show/" + to_link.id.to_s + "' class='" + specific_class + " team'" + style + ">" + h(to_link.name) + "</a>"
    return return_string
  end

  def link_to_list(to_link, specific_class)
    if to_link.team.use_colour == true
      style=" style='background-color:#" + to_link.team.colour + "; color:#" + to_link.team.text_colour + ";'"
    else
      style=""
    end
    return_string = "<span class='specialhover'><a href='/lists/show/" + to_link.id.to_s + "' class='" + specific_class + " list'" + style + ">" + h(to_link.name) + "</a><div><a href='/lists/edit/" + to_link.id.to_s + "'>" + "Edit list".t + "</a><br /><a href='/tasks/new?list=" + to_link.id.to_s + "'>" + "Create new task".t + "</a></div></span>"
    return return_string
  end

  def link_to_task(to_link, specific_class)
    if to_link.recurrence_description.nil?
      to_link.describe_recurrence
      to_link.save
    end
		
    if to_link.list.team.use_colour == true
      style=" style='background-color:#" + to_link.list.team.colour + "; color:#" + to_link.list.team.text_colour + ";'"
    else
      style=""
    end
	    
    javascript_safe_name = (to_link.short_name).to_s.gsub(/\"/, "").gsub(/\'/, "")
		
    return_string = "<span class='specialhover'>"
    return_string += "<a href='/tasks/show/" + to_link.id.to_s + "' class='" + specific_class + " task'" + style + " title='" + to_link.recurrence_description + "'>" + h(to_link.short_name) + "</a>"
    return_string += "<div>"
    return_string += "<a href='/tasks/edit/" + to_link.id.to_s + "'>" + "Edit task".t + "</a><br />"
    return_string += "<a href='/tasks/markdone/" + to_link.id.to_s + "'>" + "Mark as done".t + "</a><br />"
    return_string += "<a href='/tasks/skip/" + to_link.id.to_s + "'>" + "Skip".t + "</a><br />"
    return_string += "<a href='/tasks/nudge/" + to_link.id.to_s + "'>" + "Nudge someone".t + "</a><br />"
    return_string += "<a href='/tasks/destroy/" + to_link.id.to_s + "' onclick='return confirm(\"" + "Are you sure you want to delete this task: %s?" / javascript_safe_name + "\");'>" + "Delete task".t + "</a>"
    return_string += "</div>"
    return_string += "</span>"
		
    return return_string
  end

  def link_to_tip(to_link)
    return_string = "<a href='/tips/show/" + to_link.id.to_s + "'>Tip #" + to_link.id.to_s + ": " + h(to_link.short_description) + "</a>"
    return return_string
  end
	
	
   
  def formatted_date(date_to_format)
  
    if session[:preferred_long_date_format].nil?
      preferred_format = "%d %b %Y"
    else
      preferred_format = session[:preferred_long_date_format]
    end
    
    return date_to_format.strftime(preferred_format)
  end
	
	
  # Note this is duplicated in application_helper.rb!
  # Needs to be here for the controller to be able to send back after a change_due_date.
  def time_from_today(target_date, todays_date)
    # Finds period of time between today and the target date
    # If target_date is in the future it will be like '3 days time' or '2 weeks time'
    # If target_date is in the past it will be like '4 days ago' or '1 week ago'

		
    if target_date == todays_date
      return "today"
			
    else
      days_difference = target_date - todays_date
      if days_difference == 1
        return "tomorrow".t
      elsif days_difference == -1
        return "yesterday".t
				
      else
        absolute_difference = days_difference.abs
        case absolute_difference
        when 2..10 then return_string = absolute_difference.to_s + " days"
        when 11..17 then return_string = "~2 weeks"
        when 18..24 then return_string = "~3 weeks"
        when 25..31 then return_string = "~4 weeks"
        when 32..38 then return_string = "~5 weeks"
        when 39..68 then return_string = "~2 months"
        when 69..98 then return_string = "~3 months"
        when 99..128 then return_string = "~4 months"
        when 129..158 then return_string = "~5 months"
        when 159..188 then return_string = "~6 months"
        else return_string = "more than 6 months"
        end
					
        if days_difference > 1
          return_string = "in " + return_string
        else
          return_string += " ago"
        end
      end
			
      return return_string
			
    end
		
  end
	
end
