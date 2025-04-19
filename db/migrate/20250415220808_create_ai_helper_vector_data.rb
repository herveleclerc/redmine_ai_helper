class CreateAiHelperVectorData < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_vector_data do |t|
      t.integer :object_id
      t.string :index
      t.string :uuid
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
