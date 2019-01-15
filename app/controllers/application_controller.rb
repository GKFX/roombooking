class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception

  before_action :set_raven_context
  before_action :check_browser_version
  before_action :check_user!
  before_action :set_paper_trail_whodunnit
  helper_method :current_user
  helper_method :user_logged_in?
  helper_method :user_is_admin?

  # Record this information when auditing models.
  def info_for_paper_trail
    {
      ip: request.remote_ip,
      user_agent: request.user_agent,
      session: current_session.try(:id)
    }
  end

  # Rescue exceptions raised by user access violations from CanCan.
  rescue_from CanCan::AccessDenied do |exception|
    if user_logged_in?
      alert = { 'class' => 'danger', 'message' => 'Access denied.' }
      flash.now[:alert] = alert
      render 'layouts/blank', locals: {reason: "cancan access denied: #{exception.message}"}, status: :forbidden
    else
      alert = { 'class' => 'danger', 'message' => 'You need to login to access this page.' }
      flash.now[:alert] = alert
      render 'layouts/blank', locals: {reason: 'not logged in'}, status: :unauthorized
    end
  end

  # Recue exceptions raised due to cross-site request forgery.
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    invalidate_session
    alert = { 'class' => 'danger', 'message' => "Cross-site request forgery detected! If you are seeing this message, try clearing your browser's cache/cookies and then try again." }
    flash.now[:alert] = alert
    render 'layouts/blank', locals: {reason: "CSRF detected: #{exception.message}"}, status: :forbidden
  end

  private

  # Finds the Session model object with the ID that is stored in the Rails
  # session store. Logging in sets this session value and logging out
  # removes it.
  def current_session
    begin
      @current_session ||= Session.find(session[:sesh_id]) if session[:sesh_id]
    rescue Exception => e
      nil
    end
  end

  # Returns the User associated with the current session.
  def current_user
    @current_user ||= current_session.try(:user)
  end

  # Returns the CamdramToken associated with the current user.
  def current_camdram_token
    @current_camdram_token ||= current_user.try(:latest_camdram_token)
  end

  # True if the user is signed in, false otherwise.
  def user_logged_in?
    current_user.present?
  end

  # True if the user is a site administrator, false otherwise.
  def user_is_admin?
    user_logged_in? && current_user.admin?
  end

  # Method to ensure a logged in user has a valid Camdram API token and is
  # not blocked.
  def check_user!
    if user_logged_in?
      if current_user.blocked?
        invalidate_session
        alert = { 'class' => 'danger', 'message' => 'Your account has been blocked by an administrator. Please try again later.' }
        flash.now[:alert] = alert
        render 'layouts/blank', locals: {reason: 'user blocked'}, status: :unauthorized and return
      end
      if current_session.invalidated?
        invalidate_session
        alert = { 'class' => 'warning', 'message' => 'Your session has been invalidated by yourself or an administrator. Please login again.' }
        flash.now[:alert] = alert
        render 'layouts/blank', locals: {reason: 'session invalidated'}, status: :unauthorized and return
      end
      if current_session.expired?
        invalidate_session
        alert = { 'class' => 'warning', 'message' => 'Your session has expired. Please login again.' }
        flash.now[:alert] = alert
        render 'layouts/blank', locals: {reason: 'session expired'}, status: :unauthorized and return
      end
      unless current_camdram_token.present?
        # The user is logged in but we can't find a Camdram API token for
        # them. Maybe it was purged from the database? Maybe there was a
        # session issue?
        invalidate_session
        alert = { 'class' => 'danger', 'message' => 'A Camdram OAuth token error has occured. Please logout and then login again.' }
        flash.now[:alert] = alert
        render 'layouts/blank', locals: {reason: 'camdram token error'}, status: :internal_server_error and return
      end
      if current_camdram_token.expired?
        current_camdram_token.refresh
      end
    end
  end

  # Method to simulate/force a user logoff.
  def invalidate_session
    reset_session
    @current_session = nil
    @current_user = nil
    @current_camdram_token = nil
  end

  # Add extra context to any Sentry error reports.
  def set_raven_context
    Raven.user_context(id: current_user.try(:id), name: current_user.try(:name), email: current_user.try(:email))
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  # Make sure the user is using a modern browser.
  def check_browser_version
    unless browser.modern?
      alert = { 'class' => 'danger', 'message' => "You seem to be using a very outdated web browser! Unfortunately you'll need to update your system in order to use Room Booking." }
      flash.now[:alert] = alert
      render 'layouts/blank', locals: {reason: "outdated browser"}, status: :ok
    end
  end

  def peek_enabled?
    current_user.try(:sysadmin?)
  end

end
