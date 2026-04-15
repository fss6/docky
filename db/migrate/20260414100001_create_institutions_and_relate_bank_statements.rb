# frozen_string_literal: true

class CreateInstitutionsAndRelateBankStatements < ActiveRecord::Migration[8.0]
  # Mantido alinhado com Institution::SEED_NAMES (evita carregar o modelo antes da tabela existir).
  SEED_NAMES = [
    "Agibank",
    "Banco ABC Brasil",
    "Banco BTG Pactual",
    "Banco C6",
    "Banco da Amazônia",
    "Banco do Brasil",
    "Banco do Nordeste",
    "Banco Inter",
    "Banco Modal",
    "Banco Original / PagBank",
    "Banco Pan",
    "Banco Pine",
    "Banco Safra",
    "Banco Santander (Brasil)",
    "Banco Sofisa Direto",
    "Banco Votorantim",
    "Banrisul",
    "Bradesco",
    "Caixa Econômica Federal",
    "Citibank",
    "Itaú Unibanco",
    "Mercado Pago",
    "Neon",
    "Nubank",
    "PicPay",
    "Sicoob",
    "Sicredi",
    "Stone",
    "Outros"
  ].freeze

  FALLBACK_NAME = "Outros"

  def up
    create_table :institutions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :system, null: false, default: false
      t.timestamps
    end
    add_index :institutions, [:account_id, :name], unique: true

    now = connection.quote(Time.current.utc)
    Account.reset_column_information
    Account.find_each do |account|
      aid = connection.quote(account.id)
      SEED_NAMES.each do |name|
        execute <<-SQL.squish
          INSERT INTO institutions (account_id, name, system, created_at, updated_at)
          VALUES (#{aid}, #{connection.quote(name)}, TRUE, #{now}, #{now})
          ON CONFLICT (account_id, name) DO NOTHING
        SQL
      end
    end

    add_reference :bank_statement_imports, :institution, foreign_key: true

    execute <<-SQL.squish
      UPDATE bank_statement_imports bsi
      SET institution_id = i.id
      FROM institutions i
      WHERE i.account_id = bsi.account_id
        AND i.name = #{connection.quote(FALLBACK_NAME)}
        AND bsi.institution_id IS NULL
    SQL

    change_column_null :bank_statement_imports, :institution_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
