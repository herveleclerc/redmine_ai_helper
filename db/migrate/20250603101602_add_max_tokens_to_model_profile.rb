class AddMaxTokensToModelProfile < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_model_profiles, :max_tokens, :integer
  end
end
