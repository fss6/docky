# frozen_string_literal: true

class WikiPage < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :source_bank_statement_import, class_name: "BankStatementImport", optional: true, inverse_of: :wiki_pages
  has_many :embedding_records, as: :recordable, dependent: :destroy
  has_many :outgoing_links, class_name: "WikiLink", foreign_key: :source_page_id, dependent: :destroy
  has_many :incoming_links, class_name: "WikiLink", foreign_key: :target_page_id, dependent: :destroy

  PAGE_TYPES = %w[summary entity synthesis index].freeze

  validates :slug, presence: true, uniqueness: { scope: :account_id }
  validates :title, presence: true
  validates :page_type, inclusion: { in: PAGE_TYPES }

  after_save :embed_async, if: :saved_change_to_content?

  scope :by_type, ->(type) { where(page_type: type) }
  scope :ordered, -> { order(:page_type, :title) }

  private

  def embed_async
    WikiEmbedJob.perform_later(id)
  end
end
