class CreateAiHelperSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_settings do |t|
      t.integer :model_profile_id
      t.text :additional_instructions
      t.integer :version
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
