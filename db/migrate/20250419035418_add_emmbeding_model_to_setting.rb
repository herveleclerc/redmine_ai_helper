class AddEmmbedingModelToSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_settings, :embedding_model, :string
  end
end
