# frozen_string_literal: true

# Lista inicial (SEED_NAMES) deve coincidir com db/migrate/20260416140000_create_institutions_and_relate_bank_statements.rb
# == Schema Information
#
# Table name: institutions
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  system     :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_institutions_on_account_id           (account_id)
#  index_institutions_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Institution < ApplicationRecord
  acts_as_tenant(:account)

  has_many :bank_statement_imports, dependent: :restrict_with_exception
  has_many :bank_statements, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :account_id }

  scope :alphabetical, -> { order(:name) }

  # Lista inicial por conta (nomes canónicos para importação).
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

  def self.seed_defaults_for!(account)
    return if account.blank?

    ActsAsTenant.with_tenant(account) do
      SEED_NAMES.each do |name|
        find_or_create_by!(name: name) { |i| i.system = true }
      end
    end
  end
end
