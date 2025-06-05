# frozen_string_literal: true
# AiHelperModelProfile model for managing AI Helper model profiles
class AiHelperModelProfile < ApplicationRecord
  include Redmine::SafeAttributes
  validates :name, presence: true, uniqueness: true
  validates :llm_type, presence: true
  validates :access_key, presence: true, if: :access_key_required?
  validates :llm_model, presence: true
  validates :base_uri, presence: true, if: :base_uri_required?
  validates :base_uri, format: { with: URI::regexp(%w[http https]), message: l("ai_helper.model_profiles.messages.must_be_valid_url") }, if: :base_uri_required?
  validates :temperature, presence: true, numericality: { greater_than_or_equal_to: 0.0 }

  safe_attributes "name", "llm_type", "access_key", "organization_id", "base_uri", "version", "llm_model", "temperature", "max_tokens"

  # Replace all characters after the 4th with *
  def masked_access_key
    return access_key if access_key.blank? || access_key.length <= 4
    masked_key = access_key.dup
    masked_key[4..-1] = "*" * (masked_key.length - 4)
    masked_key
  end

  # Returns the String which is displayed in the select box
  def display_name
    "#{name} (#{llm_type}: #{llm_model})"
  end

  # returns true if base_uri is required.
  def base_uri_required?
    # Check if the llm_type is OpenAICompatible
    llm_type == RedmineAiHelper::LlmProvider::LLM_OPENAI_COMPATIBLE ||
      llm_type == RedmineAiHelper::LlmProvider::LLM_AZURE_OPENAI
  end

  # returns true if access_key is required.
  def access_key_required?
    llm_type != RedmineAiHelper::LlmProvider::LLM_OPENAI_COMPATIBLE
  end

  # Returns the LLM type name for display
  def display_llm_type
    names = RedmineAiHelper::LlmProvider.option_for_select
    name = names.find { |n| n[1] == llm_type }
    name ? name[0] : ""
  end
end
