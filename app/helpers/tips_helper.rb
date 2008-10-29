module TipsHelper

  def textilize(str)
    RedCloth.new(str).to_html
  end

end
