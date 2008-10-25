class Setting < ActiveRecord::Base

  def self.value(key)
    setting = Setting.find_by_key(key)
    return '' if setting.nil?
    setting.value
  end

end
