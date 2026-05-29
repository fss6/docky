# frozen_string_literal: true

# == Schema Information
#
# Table name: bank_statements
#
#  id                       :bigint           not null, primary key
#  amount                   :decimal(16, 2)   not null
#  description              :text             not null
#  occurred_on              :date             not null
#  possible_duplicate       :boolean          default(FALSE), not null
#  transaction_type         :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  bank_statement_import_id :bigint           not null
#  client_id                :bigint           not null
#  institution_id           :bigint           not null
#
# Indexes
#
#  index_bank_statements_on_account_id                 (account_id)
#  index_bank_statements_on_bank_statement_import_id   (bank_statement_import_id)
#  index_bank_statements_on_client_id                  (client_id)
#  index_bank_statements_on_client_id_and_occurred_on  (client_id,occurred_on)
#  index_bank_statements_on_institution_id             (institution_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (bank_statement_import_id => bank_statement_imports.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (institution_id => institutions.id)
#
class BankStatement < ApplicationRecord
  acts_as_tenant(:account)
  audited on: %i[create update destroy], except: %i[created_at updated_at possible_duplicate]

  belongs_to :client
  belongs_to :bank_statement_import
  belongs_to :institution

  # Rails 8: enum com valores string precisa de coluna na BD ou tipo explícito.
  attribute :transaction_type, :string
  enum :transaction_type, {
    credit: "credit",
    debit: "debit"
  }, validate: true

  validates :client, presence: true
  validates :institution, presence: true
  validates :occurred_on, presence: true
  validates :description, presence: true
  validates :possible_duplicate, inclusion: { in: [true, false] }

  before_validation :detect_possible_duplicate

  validate :client_matches_import
  validate :institution_matches_import
  validate :client_belongs_to_same_account

  private

  def client_matches_import
    return if bank_statement_import.blank? || client.blank?
    return if client_id == bank_statement_import.client_id

    errors.add(:client_id, "deve coincidir com o import")
  end

  def institution_matches_import
    return if bank_statement_import.blank? || institution.blank?
    return if institution_id == bank_statement_import.institution_id

    errors.add(:institution_id, "deve coincidir com o import")
  end

  def client_belongs_to_same_account
    return if client.blank? || account_id.blank?
    return if client.account_id == account_id

    errors.add(:client_id, "deve pertencer à mesma conta")
  end

  def detect_possible_duplicate
    return if occurred_on.blank? || institution_id.blank? || transaction_type.blank? || amount.blank?

    normalized_description = description.to_s.strip.downcase

    self.possible_duplicate = self.class
      .where(client_id: client_id)
      .where(
        occurred_on: occurred_on,
        institution_id: institution_id,
        transaction_type: transaction_type,
        amount: amount
      )
      .where("LOWER(TRIM(bank_statements.description)) = ?", normalized_description)
      .exists?
  end
end
