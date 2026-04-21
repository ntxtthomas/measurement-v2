class ApplicationController < ActionController::Base
  before_action :require_login

  helper_method :current_user, :current_observer, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_observer
    @current_observer ||= current_user&.observer
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Not authorized."
    end
  end
end
