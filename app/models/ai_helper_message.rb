class AiHelperMessage < ApplicationRecord
  belongs_to :conversation, class_name: "AiHelperConversation", foreign_key: "conversation_id", dependent: :destroy, touch: true
  validates :content, presence: true
  validates :role, presence: true
  validates :conversation_id, presence: true
end
