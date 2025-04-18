# frozen_string_literal: true
# This is the model for messages in the AI Helper plugin.
# It represents a message in a conversation between a user and the AI assistant.
#
class AiHelperMessage < ApplicationRecord
  belongs_to :conversation, class_name: "AiHelperConversation", foreign_key: "conversation_id", touch: true
  validates :content, presence: true
  validates :role, presence: true
  validates :conversation_id, presence: true
end
