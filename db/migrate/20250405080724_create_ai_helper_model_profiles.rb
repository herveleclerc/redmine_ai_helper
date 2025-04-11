class CreateAiHelperModelProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_model_profiles do |t|
      t.string :type
      t.string :name
      t.string :access_key
      t.string :organization_id
      t.string :base_uri
      t.integer :version
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
