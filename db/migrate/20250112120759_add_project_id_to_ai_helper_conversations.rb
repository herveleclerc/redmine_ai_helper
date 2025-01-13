class AddProjectIdToAiHelperConversations < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_conversations, :project_id, :integer
  end
end
