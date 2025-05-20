class CreateAiHelperSummaryCaches < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_summary_caches do |t|
      t.string :object_class
      t.integer :object_id
      t.text :content
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
