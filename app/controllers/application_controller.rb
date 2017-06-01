class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  #before_action :hang, only: [:index]
  
  # Check for AJAX request, if so, render without layout
  layout proc { request.xhr? ? "mini" : nil }

  # Renders a view with sidebars only
  def sidebars
	  respond_to do |format|
		  format.html { render "application/sidebars", layout: false }
	  end
  end

  # Constants
  ENTRIES_LIMIT = 25.freeze

  private
  def default_url_options(options = {})
	  { locale: I18n.locale }.merge options
  end

  def set_locale
	  I18n.locale = params[:locale] || I18n.default_locale
  end

  def hang
	  sleep 5
	  return
  end
end
