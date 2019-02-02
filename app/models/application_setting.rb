# == Schema Information
#
# Table name: application_settings
#
#  id :bigint(8)        not null, primary key
#

class ApplicationSetting < ApplicationRecord
  @@instance = nil
  after_create :freeze
  before_save :prevent_changes
  before_update :prevent_changes
  after_update :freeze
  before_destroy :prevent_changes

  def self.instance
    @@instance || self.refresh
  end

  def self.refresh
    @@instance = self.last.freeze || self.create_with_default_settings
  end

  def self.create_with_default_settings
    create! do |settings|
    end
  end

  def prevent_changes
    unless new_record?
      raise ActiveRecord::ReadOnlyRecord.new 'Application settings cannot be update or deleted. You must insert a new record and refresh the instance.'
    end
  end
end
