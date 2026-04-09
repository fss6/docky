# frozen_string_literal: true

class WikiLink < ApplicationRecord
  belongs_to :source_page, class_name: "WikiPage"
  belongs_to :target_page, class_name: "WikiPage"

  LINK_TYPES = %w[references contradicts extends supersedes].freeze

  validates :link_type, inclusion: { in: LINK_TYPES }, allow_nil: true
  validates :source_page_id, uniqueness: { scope: :target_page_id }
end
