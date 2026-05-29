# frozen_string_literal: true

class AddContentSha256ToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :content_sha256, :string, limit: 64

    add_index :documents, %i[account_id content_sha256],
              where: "status = 'processed' AND content_sha256 IS NOT NULL",
              name: "index_documents_on_account_content_sha256_processed"
  end
end
