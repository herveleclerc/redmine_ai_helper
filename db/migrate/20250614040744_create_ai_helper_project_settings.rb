class CreateAiHelperProjectSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_helper_project_settings do |t|
      t.integer :project_id
      t.text :issue_draft_instructions
      t.text :subtask_instructions
      t.datetime :updated_at
      t.datetime :created_at
      t.integer :version
    end
  end
end
