class ApplicationController < ActionController::Base
  include LoginSystem

  helper(:all)

  include ReCaptcha::AppHelper

  filter_parameter_logging :password, :password_confirmation

  before_filter :set_charset, :set_time_zone

  def logged_in?
    !session[:person].nil?
  end

  def show_ads?
    return true if !logged_in?
    session[:person].ads
  end
  
  def admin?
    return false if !logged_in?
    session[:person].status == 'Site Creator'
  end
  
  # local: starts with a / or contains the same domain of this site.
  def local?(referer)
    return true if referer =~ /^\//
    referer.include?(request.domain)
  end
  
  def home_path
    return welcome_path if !logged_in?
    case session[:person].default_view
    when 'Workload' then return workload_path
    when 'Hot map' then return hotmap_path
    when 'Calendar' then return calendar_path
    when 'Collage' then return collage_path
    when 'Statistics' then return my_statistics_path
    else return workload_path
    end
  end


  protected
  
  def admin_authorised
    if !admin?
      flash[:notice] = "Sorry, you don't have permission to view that page."
      redirect_back
    end
  end

  def set_charset
    content_type = headers["Content-Type"] || "text/html"
    if /^text\//.match(content_type)
      headers["Content-Type"] = "#{content_type}; charset=utf-8"
    end
  end

  def set_time_zone
    Time.zone = session[:person].timezone_name if session[:person]
  end

  def redirect_back
    referer = request.env["HTTP_REFERER"]
    if referer.blank? or !(local?(referer))
      redirect_to(home_path)
      return
    end
    redirect_to(referer)
  end

  def find_current_date
    @datetoday = Time.zone.today
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
    return_string = "<span class='specialhover'><a href='/lists/show/" + to_link.id.to_s + "' class='" + specific_class + " list'" + style + ">" + h(to_link.name) + "</a><div><a href='/lists/edit/" + to_link.id.to_s + "'>Edit list</a><br /><a href='/tasks/new?list=" + to_link.id.to_s + "'>Create new task</a></div></span>"
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
    return_string += "<a href='/tasks/edit/" + to_link.id.to_s + "'>Edit task</a><br />"
    return_string += "<a href='/tasks/markdone/" + to_link.id.to_s + "'>Mark as done</a><br />"
    return_string += "<a href='/tasks/skip/" + to_link.id.to_s + "'>Skip</a><br />"
    return_string += "<a href='/tasks/nudge/" + to_link.id.to_s + "'>Nudge someone</a><br />"
    return_string += "<a href='/tasks/destroy/" + to_link.id.to_s + "' onclick='return confirm(\"Are you sure you want to delete this task: #{javascript_safe_name}\");'>Delete task</a>"
    return_string += "</div>"
    return_string += "</span>"

    return return_string
  end

  def link_to_tip(to_link)
    return_string = "<a href='/tips/show/" + to_link.id.to_s + "'>Tip #" + to_link.id.to_s + ": " + h(to_link.short_description) + "</a>"
    return return_string
  end

end
