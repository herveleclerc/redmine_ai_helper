class RenameUpdateAtHelperConversations < ActiveRecord::Migration[7.2]
  def change
    rename_column :ai_helper_conversations, :update_at, :updated_at
  end
end
