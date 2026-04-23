class AddPublicUploadTokenExpiresAtToFolders < ActiveRecord::Migration[8.0]
  def change
    add_column :folders, :public_upload_token_expires_at, :datetime
  end
end
