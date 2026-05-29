# == Schema Information
#
# Table name: folders
#
#  id                             :bigint           not null, primary key
#  name                           :string
#  public_upload_token            :string
#  public_upload_token_expires_at :datetime
#  visible                        :boolean          default(FALSE), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :bigint           not null
#  client_id                      :bigint
#
# Indexes
#
#  index_folders_on_account_id           (account_id)
#  index_folders_on_client_id            (client_id)
#  index_folders_on_public_upload_token  (public_upload_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (client_id => clients.id)
#
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
