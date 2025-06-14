class ChangeVersionToLockVersion < ActiveRecord::Migration[7.2]
  def change
    # Change the column name from 'version' to 'lock_version'
    rename_column :ai_helper_project_settings, :version, :lock_version
  end
end
