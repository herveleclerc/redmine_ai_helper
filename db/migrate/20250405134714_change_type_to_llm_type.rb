class ChangeTypeToLlmType < ActiveRecord::Migration[7.2]
  def change
    rename_column :ai_helper_model_profiles, :type, :llm_type
  end
end
