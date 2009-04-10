module DateFormatHelper

  def formatted_date(date_to_format)
    preferred_format = session[:preference] ? session[:preference].my_date_format : '%d %b %Y'
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
    when 11..17 then "~2 weeks"
    when 18..24 then "~3 weeks"
    when 25..31 then "~4 weeks"
    when 32..38 then "~5 weeks"
    when 39..68 then "~2 months"
    when 69..98 then "~3 months"
    when 99..128 then "~4 months"
    when 129..158 then "~5 months"
    when 159..188 then "~6 months"
    else "more than 6 months"
    end

    return "in #{approx}" if days_difference > 1
    "#{approx} ago"  
  end

  def descriptive_date(date_to_format, todays_date)
    "#{formatted_date(date_to_format)} (#{time_from_today(date_to_format, todays_date)})"
  end
end
