class AiHelperModelProfile < ApplicationRecord
  include Redmine::SafeAttributes
  validates :name, presence: true, uniqueness: true
  validates :llm_type, presence: true
  validates :access_key, presence: true
  validates :llm_model, presence: true

  safe_attributes 'name', 'llm_type', 'access_key', 'organization_id', 'base_uri', 'version', 'llm_model'

  # Replace all characters after the 4th with *
  def masked_access_key
    return access_key if access_key.blank? || access_key.length <= 4
    masked_key = access_key.dup
    masked_key[4..-1] = '*' * (masked_key.length - 4)
    masked_key
  end

  def display_name
    "#{name} (#{llm_type}: #{llm_model})"
  end
end
