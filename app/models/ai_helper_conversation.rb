class AiHelperConversation < ApplicationRecord
  has_many :messages, class_name: "AiHelperMessage", foreign_key: "conversation_id", dependent: :destroy
  belongs_to :user
  validates :title, presence: true
  validates :user_id, presence: true
end
