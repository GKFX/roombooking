# frozen_string_literal: true

class TwoFactorController < ApplicationController
  skip_before_action :handle_2fa!

  def new
    render 'sessions/two_factor'
  end

  def create
    code = params[:totp]
    token = current_user.two_factor_token
    auth = token.verify(code)
    if auth
      session[:two_factor_auth] = auth
      alert = { 'class' => 'success', 'message' => 'You have successfully logged in.' }
      flash[:alert] = alert
      redirect_to root_path
    else
      alert = { 'class' => 'warning', 'message' => 'Invalid two-factor authentication code.' }
      flash.now[:alert] = alert
      render 'sessions/two_factor'
    end
  end
end
