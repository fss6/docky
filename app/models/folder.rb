class Folder < ApplicationRecord
  acts_as_tenant(:account)
  audited on: %i[create update destroy], except: %i[created_at updated_at public_upload_token public_upload_token_expires_at]

  belongs_to :client, optional: true

  has_many :documents, dependent: :destroy

  scope :for_nav_client, ->(client) {
    if client
      where(client_id: client.id)
    else
      all
    end
  }

  validates :public_upload_token, uniqueness: true, allow_nil: true

  def ensure_public_upload_token!
    return public_upload_token if public_upload_token.present?

    update!(
      public_upload_token: SecureRandom.urlsafe_base64(24),
      public_upload_token_expires_at: nil
    )
    public_upload_token
  end

  def regenerate_public_upload_token!
    update!(
      public_upload_token: SecureRandom.urlsafe_base64(24),
      public_upload_token_expires_at: nil
    )
    public_upload_token
  end

  def expire_public_upload_token!
    update!(public_upload_token_expires_at: Time.now.utc)
  end

  def public_upload_token_expired?
    public_upload_token_expires_at.present? && public_upload_token_expires_at <= Time.now.utc
  end

  def public_upload_enabled?
    public_upload_token.present? && !public_upload_token_expired?
  end
end
