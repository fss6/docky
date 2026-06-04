class RemoveAutoConfirmReceiptFromCollectionSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :collection_settings, :auto_confirm_receipt, :boolean
  end
end
