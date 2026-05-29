# frozen_string_literal: true

# == Schema Information
#
# Table name: wiki_pages
#
#  id                 :bigint           not null, primary key
#  content            :text
#  page_type          :string           not null
#  slug               :string           not null
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  source_document_id :integer
#
# Indexes
#
#  index_wiki_pages_on_account_id           (account_id)
#  index_wiki_pages_on_account_id_and_slug  (account_id,slug) UNIQUE
#  index_wiki_pages_on_page_type            (page_type)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class WikiPage < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
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
