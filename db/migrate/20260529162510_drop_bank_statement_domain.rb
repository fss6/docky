# frozen_string_literal: true

class DropBankStatementDomain < ActiveRecord::Migration[8.0]
  def up
    remove_reference :wiki_pages, :source_bank_statement_import, foreign_key: { to_table: :bank_statement_imports }

    execute <<~SQL.squish
      DELETE FROM embedding_records WHERE recordable_type = 'BankStatementImport'
    SQL

    drop_table :bank_statements, if_exists: true
    drop_table :bank_statement_imports, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
