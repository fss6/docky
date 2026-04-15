class AddVisibleToFolders < ActiveRecord::Migration[8.0]
  def up
    add_column :folders, :visible, :boolean, null: false, default: false
  end

  def down
    remove_column :folders, :visible
  end
end
