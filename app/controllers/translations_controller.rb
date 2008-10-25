class TranslationsController < ApplicationController


  before_filter(:login_required)

	
  def index
    @languages = Language.find(:all, :conditions => "id in (7597, 1831, 5250)")
    
    
    @pie_chart = GoogleChart.new
    @pie_chart.type = :pie
    @pie_chart.width = 50
    @pie_chart.height = 50
    @pie_chart.colors = ["DDFFCC","FFD7D7"]
    
  end
  
  def find_language_name(id)
    @language = Language.find_by_id(id)
    return @language.english_name.capitalize if @language.native_name.nil?
    @language.native_name.capitalize
  end
  
  def untranslated
    id = params[:id]
    
    @language_name = find_language_name(id)
    
    @translations = Translation.paginate(:page => params[:page], :conditions => ["language_id = ? AND text is null", id], :order => 'tr_key asc', :per_page => 30)
    render(:action => 'list_translations')
  end
  
  def show
    id = params[:id]
    
    @language_name = find_language_name(id)
    
    @translations = Translation.paginate(:page => params[:page], :conditions => ["language_id = ?", id], :order => 'text asc, tr_key asc', :per_page => 30)
    render(:action => 'list_translations')
  end
  
  def search
    query = '%' + params[:q] + '%'
    conditions = case params[:language]
      when "tr_key": ["language_id = ? and tr_key like ?", params[:id], query]
      when "text": ["language_id = ? and text like ?", params[:id], query]
      else ["language_id = ? and (tr_key like ? or text like ?)", params[:id], query, query]
    end
    @translations = Translation.paginate(:page => params[:page], :conditions => conditions, :order => 'text asc, tr_key asc', :per_page => 30)
    @language_name = find_language_name(params[:id])
    render(:action => 'list_translations')
  end
  
  def update_translation
    if session[:person].status.nil?
      render(:text => "ERROR: You are not a translator. Please use the contact form if you would like to help translate MyChores.")
    elsif session[:person].status.include?("Site Translator") or session[:person].status.include?("Site Creator")
      translation = Translation.find(params[:id])
      
      previous_translation = translation.text
      translation.text = params[:value]
      translation.tr_version += 1
      translation.person_id = session[:person].id
      translation.text = previous_translation unless translation.save
      render(:text => translation.text)
    else
      render(:text => "ERROR: You are not a translator. Please use the contact form if you would like to help translate MyChores.")
    end
  end

end
