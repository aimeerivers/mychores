# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  require 'recaptcha'
  include ReCaptcha::ViewHelper

  def link_to_person(to_link, specific_class)
    @controller.send(:link_to_person, to_link, specific_class)
  end

  def link_to_list(to_link, specific_class)
    @controller.send(:link_to_list, to_link, specific_class)
  end

  def link_to_task(to_link, specific_class)
    @controller.send(:link_to_task, to_link, specific_class)
  end

  def link_to_tip(to_link)
    @controller.send(:link_to_tip, to_link)
  end
	
	
	
	
	
	

  def access_denied()
    @heading = "Access denied"
    return "<p>Sorry, you don't have permission to view this page.</p>"
  end

  def is_member_of_team(this_person_id, this_team_id)
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ?", this_person_id, this_team_id ])
    if @membership_search.nil?
      return false
    else
      return true
    end
  end

  def is_confirmed_member_of_team(this_person_id, this_team_id)
    @membership_search = Membership.find(:first, :conditions => [ "person_id = ? and team_id = ? and confirmed = 1", this_person_id, this_team_id ])
    if @membership_search.nil?
      return false
    else
      return true
    end
  end
	
  def find_my_teams
    @person = session[:person]
    return Team.find_by_sql(["select * from teams where id in (select team_id from memberships where confirmed = 1 and person_id = ?) order by name ASC", @person.id])
  end
	
	
	
	
  def formatted_date(date_to_format)
    @controller.send(:formatted_date, date_to_format)
  end
	
  # Used by email script.
  def particularly_formatted_date(preferred_format, date_to_format)
    return date_to_format.strftime(preferred_format)
  end
	
	
  def denormalize_url(url)
    url.strip.sub(/^http:\/\//, '').sub(/^([^\/]+)\/$/, '\1')
  end
  
  def javascript_safe(string)
    string.gsub(/[\"\']/, '')
  end
  
  
  def print_tags_for_tip(tip)
    require 'cgi'
    
    taglist = tip.tag_list()
    
    return_string = ""
    
    taglist.each do |tag|
      return_string += "<a href='/tips/list?tag=" + CGI::escape(tag) + "'>" + tag + "</a>, "
    end
    
    # Return without the last space and comma
    return return_string.rstrip.chop
  end
  
  
  def underline_access_key(title, accesskey)

    if title.include?(accesskey.upcase)
      return title.sub(accesskey.upcase, "<u>" + accesskey.upcase + "</u>")
    elsif title.include?(accesskey.downcase)
      return title.sub(accesskey.downcase, "<u>" + accesskey.downcase + "</u>")
    else
      return title
    end

  end
  
  
  
  def show_picture(picture)
    width = picture.width
    height = picture.height
    
    if width > 240 or height > 240
      if width > height
        constraint = "width='240' height='" + ((height * (240.to_f/width.to_f)).to_i).to_s + "'"
      else
        constraint = "height='240' width='" + ((width * (240.to_f/height.to_f)).to_i).to_s + "'"
      end
    else
      constraint = "width='" + width.to_s + "' height='" + height.to_s + "'"
    end
    return "<img src='" + picture.public_filename + "' alt='" + picture.filename + "' title='" + picture.filename + "' style = 'border: 1px solid #999999;' align='absmiddle' " + constraint + " />"
  end
  
  
  
  def show_picture_with_alt_text(picture, alt_text)
    width = picture.width
    height = picture.height
    
    if width > 240 or height > 240
      if width > height
        constraint = "width='240' height='" + ((height * (240.to_f/width.to_f)).to_i).to_s + "'"
      else
        constraint = "height='240' width='" + ((width * (240.to_f/height.to_f)).to_i).to_s + "'"
      end
    else
      constraint = "width='" + width.to_s + "' height='" + height.to_s + "'"
    end
    return "<img src='" + picture.public_filename + "' alt='" + alt_text + "' title='" + alt_text + "' style = 'border: 1px solid #999999;' align='absmiddle' " + constraint + " />"
  end
  
  




  def gravatar_url(email,gravatar_options={})
  
    # Default highest rating.
    # Rating can be one of G, PG, R X.
    # If set to nil, the Gravatar default of X will be used.
    gravatar_options[:rating] ||= 'R'
  
    # Default size of the image.
    # If set to nil, the Gravatar default size of 80px will be used.
    gravatar_options[:size] ||= 60 
  
    # Default image url to be used when no gravatar is found
    # or when an image exceeds the rating parameter.
    gravatar_options[:default] ||= "http://www.mychores.co.uk/images/no-gravatar.jpg"
  
    # Build the Gravatar url.
    grav_url = 'http://www.gravatar.com/avatar.php?'
    grav_url << "gravatar_id=#{Digest::MD5.new.update(email)}" 
    grav_url << "&rating=#{gravatar_options[:rating]}" if gravatar_options[:rating]
    grav_url << "&size=#{gravatar_options[:size]}" if gravatar_options[:size]
    grav_url << "&default=#{gravatar_options[:default]}" if gravatar_options[:default]
    return grav_url
  end


  
  def aimee_in_place_editor(field_id, options = {})
    img_tag="<img src='/images/edit.png' width='12' height='13' alt='click to edit' title='click to edit' id='edit-" + field_id + "' />"
    
    function =  "new Ajax.AimeeInPlaceEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['onComplete']   = "function(transport, element) { #{options[:oncomplete]} }" if options[:oncomplete]
    
    # Aimee added the below ...
    js_options['submitOnBlur'] = true
    js_options['okButton'] = false
    js_options['cancelLink'] = false
    js_options['clickToEditText'] = "''"
    js_options['externalControl'] = "'edit-" + field_id + "'"
    js_options['externalControlOnly'] = true
    js_options['value'] = "'" + escape_javascript(options[:value]) + "'" if options[:value]
    
    
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
        
    function << ')'

    img_tag + javascript_tag(function)
  end


  
  def aimee_in_place_date_editor(field_id, datevalue, options = {})
    img_tag="<img src='/images/edit.png' width='12' height='13' alt='click to edit' title='click to edit' id='edit-" + field_id + "' />"
    
    function =  "new Ajax.AimeeInPlaceDateEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    
    # Aimee added the below ...
    js_options['submitOnBlur'] = true
    js_options['okButton'] = false
    js_options['cancelLink'] = false
    js_options['clickToEditText'] = "''"
    js_options['externalControl'] = "'edit-" + field_id + "'"
    js_options['onlyExternalControl'] = true
    # js_options['year'] = datevalue.strftime("%Y")
    # js_options['month'] = datevalue.strftime("%m")
    # js_options['day'] = datevalue.strftime("%d")
    
    
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
        
    function << ')'

    img_tag + javascript_tag(function)
  end
  
  
  def in_place_collection_editor_field(object,method,container, tag_options={})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = { :tag => "span",
      :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor",
      :class => "in_place_editor_field" }.merge!(tag_options)
    url = url_for( :action => "set_#{object}_#{method}", :id => tag.object.id )
    collection = container.inject([]) do |options, element|
      options << "[ '#{escape_javascript(element.last.to_s)}', '#{escape_javascript(element.first.to_s)}']" 
    end
    function =  "new Ajax.InPlaceCollectionEditor("
    function << "'#{object}_#{method}_#{tag.object.id}_in_place_editor',"
    function << "'#{url}',"
    function << "{collection: [#{collection.join(',')}], id: '#{object}_#{method}'});"
    tag.to_content_tag(tag_options.delete(:tag), tag_options) + javascript_tag(function)
  end


  
  def aimee_in_place_collection_editor(field_id, container, options = {})
    function =  "new Ajax.InPlaceCollectionEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"
    
    collection = container.inject([]) do |options, element|
      options << "[ '#{escape_javascript(element.last.to_s)}', '#{escape_javascript(element.first.to_s)}']" 
    end

    js_options = {}
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]        
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    
    # Aimee added the below ...
    js_options['submitOnBlur'] = true
    js_options['okButton'] = false
    js_options['cancelLink'] = false
    js_options['onlyExternalControl'] = true if options[:external_control]
    js_options['collection'] = collection.join(',')
    
    
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
        
    function << ')'

    javascript_tag(function)
  end


end
