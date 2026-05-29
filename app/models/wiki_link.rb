# frozen_string_literal: true

# == Schema Information
#
# Table name: wiki_links
#
#  id             :bigint           not null, primary key
#  link_type      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_page_id :bigint           not null
#  target_page_id :bigint           not null
#
# Indexes
#
#  index_wiki_links_on_source_page_id                     (source_page_id)
#  index_wiki_links_on_source_page_id_and_target_page_id  (source_page_id,target_page_id) UNIQUE
#  index_wiki_links_on_target_page_id                     (target_page_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_page_id => wiki_pages.id)
#  fk_rails_...  (target_page_id => wiki_pages.id)
#
class WikiLink < ApplicationRecord
  belongs_to :source_page, class_name: "WikiPage"
  belongs_to :target_page, class_name: "WikiPage"

  LINK_TYPES = %w[references contradicts extends supersedes].freeze

  validates :link_type, inclusion: { in: LINK_TYPES }, allow_nil: true
  validates :source_page_id, uniqueness: { scope: :target_page_id }
end
