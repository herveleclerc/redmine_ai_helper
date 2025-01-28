class CreateAiHelperConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_conversations do |t|
      t.string :title
      t.integer :user_id
      t.integer :version_id
      t.date :created_at
      t.date :update_at
    end
  end
end
