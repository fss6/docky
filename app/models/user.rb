# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  active                 :boolean
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#
# Indexes
#
#  index_users_on_account_id            (account_id)
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class User < ApplicationRecord
  acts_as_tenant(:account)
  attribute :active, :boolean, default: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable
  belongs_to :account

  has_many :conversations, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :audit_events, dependent: :nullify
  has_many :validated_competency_checklist_items, class_name: "CompetencyChecklistItem", foreign_key: :validated_by_user_id, dependent: :nullify, inverse_of: :validated_by_user
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :account_id }
  validates :role, presence: true
  validates :active, inclusion: { in: [ true, false ] }

  enum :role, {
    member: "member", # Membro da conta
    owner: "owner", # Administrador da conta
    administrator: "administrator" # Administrador do SaaS
  }, prefix: true

  def active_for_authentication?
    super && active?
  end

  def enabled?
    active?
  end

  # Satisfies Devise validations on create; pair with +send_reset_password_instructions+ so the
  # user sets their own password (admin-created users).
  def assign_initial_random_password!
    self.password = self.password_confirmation = SecureRandom.hex(32)
  end

  def role_label
    I18n.t("activerecord.enums.user.role.#{role}")
  end

  def self.role_options_for_select(administrator:)
    keys = administrator ? roles.keys : roles.keys - [ "administrator" ]
    keys.map { |key| [ I18n.t("activerecord.enums.user.role.#{key}"), key ] }
  end
end
