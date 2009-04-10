module DateFormatHelper

  def formatted_date(date_to_format)
    preferred_format = session[:preference].nil? ? '%d %b %Y' : session[:preference].my_date_format
    preferred_format.gsub!('%m/%d/%Y', '%b %d %Y')
    preferred_format.gsub!('%d/%m/%Y', '%d %b %Y')
    date_to_format.strftime(preferred_format)
  end
	
  def time_from_today(target_date, todays_date)
    return 'today' if target_date == todays_date

    days_difference = target_date - todays_date
    return 'tomorrow' if days_difference == 1
    return 'yesterday' if days_difference == -1

    approx = case days_difference.abs
    when 2..10 then "#{days_difference.abs} days"
    when 11..38 then '~' + ((days_difference.abs + 3) / 7).floor.to_s + ' weeks'
    when 39..188 then '~' + ((days_difference.abs + 22) / 30.4375).floor.to_s + ' months'
    else "more than 6 months"
    end

    return "in #{approx}" if days_difference > 1
    "#{approx} ago"  
  end

  def descriptive_date(date_to_format, todays_date)
    "#{formatted_date(date_to_format)} (#{time_from_today(date_to_format, todays_date)})"
  end
end
