class AddDimentionToSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_settings, :dimension, :integer, null: true, default: nil
  end
end
