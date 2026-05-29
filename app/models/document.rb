# == Schema Information
#
# Table name: documents
#
#  id                :bigint           not null, primary key
#  collection_period :date
#  content           :text
#  content_sha256    :string(64)
#  metadata          :jsonb
#  status            :string
#  summary           :text
#  tags              :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  client_id         :bigint
#  folder_id         :bigint           not null
#  period_id         :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_documents_on_account_content_sha256_processed  (account_id,content_sha256) WHERE (((status)::text = 'processed'::text) AND (content_sha256 IS NOT NULL))
#  index_documents_on_account_id                        (account_id)
#  index_documents_on_client_collection_created         (client_id,collection_period,created_at)
#  index_documents_on_client_id                         (client_id)
#  index_documents_on_client_period_created             (client_id,period_id,created_at)
#  index_documents_on_folder_id                         (folder_id)
#  index_documents_on_period_id                         (period_id)
#  index_documents_on_tags                              (tags) USING gin
#  index_documents_on_user_id                           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (folder_id => folders.id)
#  fk_rails_...  (period_id => competency_checklists.id)
#  fk_rails_...  (user_id => users.id)
#
class Document < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :user
  belongs_to :folder
  belongs_to :client, optional: true
  belongs_to :period, optional: true

  has_one_attached :file

  has_many :embedding_records, as: :recordable, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, default: :pending

  scope :for_client_period, ->(client, period) {
    month = period.to_date.beginning_of_month
    period_record = Period.find_by(client_id: client.id, period: month)
    if period_record
      where(client_id: client.id, period_id: period_record.id)
    else
      where(client_id: client.id, collection_period: month)
    end
  }

  scope :for_period, ->(period_record) {
    where(period_id: period_record.id)
  }

  after_create_commit :notify_client_documents_channel, if: :client_id?
  before_validation :sync_collection_period_from_period

  validate :user_belongs_to_account
  validate :folder_belongs_to_account
  validate :tags_are_strings
  validate :acceptable_file_type, if: -> { file.attached? && file.changed? }
  validate :content_sha256_format, if: -> { content_sha256.present? }
  # validates :file, attached: true, on: :create

  def tags
    v = read_attribute(:tags)
    v.is_a?(Array) ? v : []
  end

  def self.normalize_tags(raw_tags, max: 20)
    Array(raw_tags).filter_map do |tag|
      normalized = tag.to_s.strip.squeeze(" ")
      next if normalized.blank?

      normalized.truncate(80, omission: "")
    end.uniq { |t| t.downcase }.first(max)
  end

  def upload_source_label
    source = metadata.is_a?(Hash) ? metadata["upload_source"] : nil
    case source
    when "public_link" then "portal"
    when "email_forward" then "e-mail forward"
    else "conta"
    end
  end

  def linked_checklist_item
    CompetencyChecklistItem.find_by(last_document_id: id)
  end

  private

  def tags_are_strings
    return unless tags.is_a?(Array)

    tags.each do |t|
      next if t.is_a?(String)

      errors.add(:tags, "deve ser uma lista de textos")
      break
    end
  end

  def acceptable_file_type
    return if Documents::AllowedUpload.allowed_blob?(file.blob)

    errors.add(:file, Documents::AllowedUpload.validation_error_message)
  end

  def content_sha256_format
    return if content_sha256.match?(/\A[0-9a-f]{64}\z/)

    errors.add(:content_sha256, "deve ser um SHA256 hexadecimal válido")
  end

  def user_belongs_to_account
    return if account_id.blank? || user_id.blank?
    return if user&.account_id == account_id

    errors.add(:user_id, "deve pertencer à mesma conta selecionada")
  end

  def folder_belongs_to_account
    return if account_id.blank? || folder_id.blank?
    return if folder&.account_id == account_id

    errors.add(:folder_id, "deve pertencer à mesma conta selecionada")
  end

  def sync_collection_period_from_period
    return if period.blank?

    self.collection_period = period.period
    self.client_id ||= period.client_id
    self.account_id ||= period.account_id
  end

  def notify_client_documents_channel
    ActionCable.server.broadcast(
      "client_#{client_id}_documents",
      { "event" => "document_created", "document_id" => id }
    )
  end
end
