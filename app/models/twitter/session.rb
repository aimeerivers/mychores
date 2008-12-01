module Twitter
  ENDPOINT = "twitter.com"
  UPDATE = "/statuses/update.xml"
  DIRECT = "/direct_messages/new.xml"
  
  #--
  # This should really go in it's own file, but it's only used here and it
  # seems too much work for so little code.
  class Response
    attr_accessor :body
    def initialize(body=nil)
      @body = body
    end
  end
  # See above.
  class Success < Twitter::Response; end
  class Error < Twitter::Response; end
  class Unavailable < Twitter::Error; end
  class ServiceError < Twitter::Error; end
  class Unauthorized < Twitter::Error; end
  #++
  
  class Session
    def initialize(person)
      pref = person.preference
      @username = pref.twitter_email
      @password = pref.twitter_password.tr("A-Za-z", "N-ZA-Mn-za-m")
      @update_prototype = pref.twitter_update_string + " (www.mychores.co.uk)"
    end
    
    def update(text_or_task)
      update_string = text_or_task.is_a?(Task) ? task_update_string(text_or_task) : text_or_task      
      request = new_request(Twitter::UPDATE, {'status' => update_string})
      do_request(request)
    end
    
    def direct_message(text, recipient)
      request = new_request(Twitter::DIRECT, {'text' => text, 'user' => recipient})
      do_request(request)
    end
    
    private
    def new_request(action, form_data)
      returning Net::HTTP::Post.new(action) do |request|
        request.basic_auth(@username, @password)
        request.set_form_data(form_data)
      end
    end
    
    def do_request(request)
      begin
        response = Net::HTTP.new(Twitter::ENDPOINT, 80).start do |http|
          http.request(request)
        end
      rescue SocketError
        return Twitter::Unavailable.new
      end
      
      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
        if response.body.empty?
          Twitter::ServiceError.new
        else
          Twitter::Success.new(response.body)
        end
      when Net::HTTPUnauthorized
        Twitter::Unauthorized.new
      else
        Twitter::Error.new
      end
    end
    
    def task_update_string(task)
      returning @update_prototype.dup do |str|
        str.gsub!('{TASK}', task.name)
        str.gsub!('{LIST}', task.list.name)
        str.gsub!('{TEAM}', task.list.team.name)
      end
    end
    
  end
end