class AddHealthReportInstructionsToProjectSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_helper_project_settings, :health_report_instructions, :text
  end
end
