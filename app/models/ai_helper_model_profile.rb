class AiHelperModelProfile < ApplicationRecord
  include Redmine::SafeAttributes
  validates :name, presence: true, uniqueness: true
  validates :llm_type, presence: true
  validates :access_key, presence: true
  validates :llm_model, presence: true

  safe_attributes 'name', 'llm_type', 'access_key', 'organization_id', 'base_uri', 'version', 'llm_model'
end
