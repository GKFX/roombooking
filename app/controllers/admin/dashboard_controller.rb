# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    before_action :must_be_admin!

    def backup
      log_abuse "#{current_user.name.capitalize} downloaded a database dump"
      begin
        send_data `pg_dump -Fc roombooking_#{Rails.env}`,
          filename: "roombooking_#{Rails.env}_#{DateTime.now.to_i}.pgdump"
      rescue Exception => e
        Raven.capture_exception(e)
        render plain: "An error occurred when creating the backup!"
      end
    end

    def info
      render html: Rails::Info.to_html.html_safe
    end
  end
end
