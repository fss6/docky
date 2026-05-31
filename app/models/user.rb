# frozen_string_literal: true

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
#  founding_user          :boolean          default(FALSE), not null
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
#  index_users_on_account_id                (account_id)
#  index_users_on_account_id_founding_user  (account_id,founding_user) UNIQUE WHERE (founding_user = true)
#  index_users_on_confirmation_token        (confirmation_token) UNIQUE
#  index_users_on_email                     (email) UNIQUE
#  index_users_on_reset_password_token      (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class User < ApplicationRecord
  acts_as_tenant(:account)
  attribute :active, :boolean, default: true
  attribute :founding_user, :boolean, default: false

  attr_accessor :updated_by
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

  has_one_attached :avatar

  before_validation :assign_founding_user, on: :create
  before_validation :enforce_founding_user_defaults, on: :create

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :account_id }
  validates :role, presence: true
  validates :active, inclusion: { in: [ true, false ] }
  validate :founding_user_must_be_owner, on: :create
  validate :updater_cannot_change_own_role, on: :update
  validate :account_owner_invariants, on: :update
  validate :acceptable_avatar, if: -> { avatar.attached? && avatar.changed? }

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

  def assign_initial_random_password!
    self.password = self.password_confirmation = SecureRandom.hex(32)
  end

  def role_label
    I18n.t("activerecord.enums.user.role.#{role}")
  end

  def sole_active_owner?
    role_owner? && active? && would_remove_last_active_owner?
  end

  def would_remove_last_active_owner?
    return false unless account
    return false unless role_owner? && active?

    other_active_owners.none?
  end

  def locked_role?
    founding_user?
  end

  def locked_active?
    founding_user? || would_remove_last_active_owner?
  end

  def self.role_options_for_select(administrator:)
    keys = administrator ? roles.keys : roles.keys - [ "administrator" ]
    keys.map { |key| [ I18n.t("activerecord.enums.user.role.#{key}"), key ] }
  end

  def remove_avatar=(value)
    avatar.purge if ActiveModel::Type::Boolean.new.cast(value)
  end

  private

  def acceptable_avatar
    return if Users::AvatarUpload.allowed_blob?(avatar.blob)

    errors.add(:avatar, Users::AvatarUpload.validation_error_message)
  end

  def assign_founding_user
    return unless account

    self.founding_user = account.users.where.not(id: id).none?
  end

  def enforce_founding_user_defaults
    return unless founding_user?

    self.role = :owner
    self.active = true
  end

  def founding_user_must_be_owner
    return unless founding_user?
    return if role_owner?

    errors.add(:role, :founding_must_be_owner)
  end

  def updater_cannot_change_own_role
    return unless updated_by
    return unless updated_by.id == id
    return unless role_changed?

    errors.add(:role, :cannot_change_own_role)
  end

  def account_owner_invariants
    return unless account

    if founding_user? && role_changed? && !role_owner?
      errors.add(:role, :founding_owner)
      return
    end

    if founding_user? && active_changed? && !active?
      errors.add(:active, :founding_owner)
      return
    end

    if role_changed? && role_was == "owner" && !role_owner? && other_active_owners.none?
      errors.add(:role, :account_requires_active_owner)
    end

    if active_changed? && !active? && role_owner? && other_active_owners.none?
      errors.add(:active, :account_requires_active_owner)
    end
  end

  def other_active_owners
    account.users.where(role: :owner, active: true).where.not(id: id)
  end
end
