class AiHelperConversation < ApplicationRecord
  has_many :messages, class_name: "AiHelperMessage", foreign_key: "conversation_id"
  belongs_to :user, dependent: :destroy
  belongs_to :project, dependent: :destroy
  validates :title, presence: true
  validates :user_id, presence: true
end
