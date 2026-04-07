class Document < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :user
  belongs_to :folder

  has_one_attached :file

  has_many :embedding_records, as: :recordable, dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed"
  }, default: :pending

  validate :user_belongs_to_account
  validate :folder_belongs_to_account
  validate :tags_are_strings
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

  private

  def tags_are_strings
    return unless tags.is_a?(Array)

    tags.each do |t|
      next if t.is_a?(String)

      errors.add(:tags, "deve ser uma lista de textos")
      break
    end
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
end
