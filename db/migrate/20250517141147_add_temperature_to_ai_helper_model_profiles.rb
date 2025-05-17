class AddTemperatureToAiHelperModelProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_model_profiles, :temperature, :float, default: 0.5
  end
end
