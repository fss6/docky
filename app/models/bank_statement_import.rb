# frozen_string_literal: true

class BankStatementImport < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :client
  belongs_to :institution
  has_many :bank_statements, dependent: :destroy
  has_many :embedding_records, as: :recordable, dependent: :destroy
  has_many :wiki_pages, foreign_key: :source_bank_statement_import_id, inverse_of: :source_bank_statement_import, dependent: :nullify

  has_one_attached :file

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  validates :client, presence: true
  validates :institution, presence: true, on: :create
  validate :client_belongs_to_same_account
  validate :institution_belongs_to_same_account

  validate :file_must_be_pdf, on: :create

  OCR_TEXT_MAX_CHARS = 200_000

  private

  def client_belongs_to_same_account
    return if client.blank? || account_id.blank?
    return if client.account_id == account_id

    errors.add(:client_id, "deve pertencer à mesma conta")
  end

  def institution_belongs_to_same_account
    return if institution.blank? || account_id.blank?
    return if institution.account_id == account_id

    errors.add(:institution_id, "deve pertencer à mesma conta")
  end

  def file_must_be_pdf
    return unless file.attached?

    ct = file.content_type.to_s
    return if ct == "application/pdf"

    errors.add(:file, "deve ser um PDF")
  end
end
