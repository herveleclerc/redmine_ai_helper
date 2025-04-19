class AddFieldsForVectorSearch < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_settings, :vector_search_enabled, :boolean, default: false
    add_column :ai_helper_settings, :vector_search_uri, :string
    add_column :ai_helper_settings, :vector_search_api_key, :string
  end
end
