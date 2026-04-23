class AddPublicUploadTokenToFolders < ActiveRecord::Migration[8.0]
  def change
    add_column :folders, :public_upload_token, :string
    add_index :folders, :public_upload_token, unique: true
  end
end
