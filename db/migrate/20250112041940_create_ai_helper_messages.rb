class CreateAiHelperMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_messages do |t|
      t.integer :conversation_id
      t.string :role
      t.text :content
      t.date :created_at
    end
  end
end
