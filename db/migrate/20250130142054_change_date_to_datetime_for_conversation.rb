class ChangeDateToDatetimeForConversation < ActiveRecord::Migration[7.2]
  def up
    change_column :ai_helper_conversations, :updated_at, :datetime
    change_column :ai_helper_conversations, :created_at, :datetime
    change_column :ai_helper_messages, :created_at, :datetime
  end

  def down
    change_column :ai_helper_conversations, :updated_at, :date
    change_column :ai_helper_conversations, :created_at, :date
    change_column :ai_helper_messages, :created_at, :date
  end
end
