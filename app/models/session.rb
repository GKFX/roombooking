# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id          :bigint(8)        not null, primary key
#  user_id     :bigint(8)        not null
#  invalidated :boolean          default(FALSE), not null
#  expires_at  :datetime         not null
#  login_at    :datetime         not null
#  ip          :inet             not null
#  user_agent  :string           not null
#

class Session < ApplicationRecord
  belongs_to :user

  validates :expires_at, presence: true
  validates :login_at, presence: true
  validates :ip, presence: true
  validates :user_agent, presence: true

  def self.from_user_and_request(user, request)
    login_at = DateTime.now
    expires_at = login_at + 60.days
    ip = request.remote_ip
    user_agent = request.user_agent
    create!(user: user, login_at: login_at, expires_at: expires_at, ip: ip, user_agent: user_agent)
  end

  # True if the Session has expired, false otherwise.
  def expired?
    Time.now >= self.expires_at
  end

  # Invalidates the session.
  def invalidate!
    self.update(invalidated: true)
  end
end
