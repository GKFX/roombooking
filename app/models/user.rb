# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  email      :string           not null
#  admin      :boolean          default(FALSE), not null
#  sysadmin   :boolean          default(FALSE), not null
#  blocked    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
  has_paper_trail
  include PgSearch
  pg_search_scope :search_by_name_and_email, against: [:name, :email],
    ignoring: :accents, using: { tsearch: { prefix: true, dictionary: 'english' },
    dmetaphone: { any_word: true }, trigram: { only: [:name] } }

  has_many :booking, dependent: :destroy
  has_many :provider_account, dependent: :delete_all
  has_one :camdram_account, -> { where(provider: 'camdram') }, class_name: 'ProviderAccount'
  has_many :camdram_token, dependent: :delete_all
  has_one :latest_camdram_token, -> { order(created_at: :desc) }, class_name: 'CamdramToken'
  has_one :two_factor_token, dependent: :delete

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, email: true

  # Returns a user from an OmniAuth::AuthHash.
  def self.from_omniauth(auth_hash)
    provider = auth_hash['provider']
    uid = auth_hash['uid'].to_s
    account = ProviderAccount.find_by(provider: provider, uid: uid)
    if account.present?
      account.user
    else
      name = auth['info']['name'] || ''
      email = auth['info']['email'] || ''
      user = User.find_by(email: email)
      ActiveRecord::Base.transaction do
        user = User.create!(name: name, email: email) unless user.present?
        ProviderAccount.create!(provider: provider, uid: uid, user: user)
      end
      user
    end
  end

  # Grants administrator privileges to the user.
  def make_admin!
    self.update(admin: true)
  end

  # Revokes administrator privileges from the user.
  def revoke_admin!
    self.update(admin: false)
  end

  # Blocks the user and invalidates all their sessions.
  def block!
    self.update(blocked: true)
    Session.where(user_id: self.id).each(&:invalidate!)
  end

  # Unblocks the user.
  def unblock!
    self.update(blocked: false)
  end

  # Returns the user's Camdram uid.
  def camdram_id
    self.camdram_account.try(:uid)
  end

  def authorised_camdram_shows
    if self.admin
      # Admins are authorised for all active shows that haven't been marked
      # as dormant (which happens at the start of each new term).
      CamdramShow.where(dormant: false, active: true)
    else
      begin
        # Poll Camdram for future shows that the user has access to.
        shows = camdram_client.user.get_shows
        shows.reject! { |show| show.performances.last.end_date < Time.now }
        # Then authorise any such active shows that are not dormant.
        CamdramShow.where(camdram_id: shows.map(&:id), dormant: false, active: true)
      rescue Roombooking::CamdramAPI::NoAccessToken => e
        raise e
      rescue
        raise Roombooking::CamdramAPI::CamdramError
      end
    end
  end

  def authorised_camdram_societies
    if self.admin
      # Admins are authorised for all active societies.
      CamdramSociety.where(active: true)
    else
      begin
        # Poll Camdram for any societies that the user has access to.
        societies = camdram_client.user.get_societies
        # Then authorise any such active societies.
        CamdramSociety.where(camdram_id: societies.map(&:id), active: true)
      rescue Roombooking::CamdramAPI::NoAccessToken => e
        raise e
      rescue
        raise Roombooking::CamdramAPI::CamdramError
      end
    end
  end

  private

  # Private method to create a Camdram client with the user's OAuth access
  # token. This client will be able to act as the user and view the list of
  # shows and societies the user administers.
  def camdram_client
    token = latest_camdram_token
    raise Roombooking::CamdramAPI::NoAccessToken, 'No Camdram tokens found for the user' unless token.present?
    token_hash = { access_token: token.access_token,
      refresh_token: token.refresh_token, expires_at: token.expires_at }
    Roombooking::CamdramAPI::ClientFactory.new(token_hash)
  end

end
