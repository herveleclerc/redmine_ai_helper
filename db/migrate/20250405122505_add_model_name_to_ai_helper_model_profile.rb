class AddModelNameToAiHelperModelProfile < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_model_profiles, :llm_model, :string
  end
end
