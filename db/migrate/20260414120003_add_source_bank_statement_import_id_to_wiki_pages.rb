# frozen_string_literal: true

class AddSourceBankStatementImportIdToWikiPages < ActiveRecord::Migration[8.0]
  def change
    add_reference :wiki_pages, :source_bank_statement_import, null: true, foreign_key: { to_table: :bank_statement_imports }
  end
end
