module KeyFactory
  
  def self.new
    Digest::SHA1.hexdigest("#{rand(390625)}--#{Time.now}--")
  end
  
end