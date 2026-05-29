# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    manage_users?
  end

  def show?
    manage_users?
  end

  def create?
    manage_users?
  end

  def new?
    create?
  end

  def update?
    manage_users?
  end

  def edit?
    update?
  end

  def edit_role?
    manage_users? && !editing_self? && !founding_user_record?
  end

  def edit_active?
    manage_users? && !editing_self? && !founding_user_record? && !would_remove_last_active_owner_record?
  end

  def destroy?
    return false unless manage_users?
    return false if disabling_self?
    return false if founding_user_record?

    !would_remove_last_active_owner_record?
  end

  def enable?
    return false unless manage_users?
    return false if enabling_self?

    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.role_administrator?
        all_users
      else
        scope.all
      end
    end

    private

    def all_users
      ActsAsTenant.without_tenant do
        scope.all
      end
    end
  end

  private

  def manage_users?
    user.role_administrator? || allow_capability?("users.manage")
  end

  def editing_self?
    record.is_a?(User) && record.persisted? && record.id == user.id
  end

  def disabling_self?
    editing_self?
  end

  def enabling_self?
    editing_self?
  end

  def founding_user_record?
    record.is_a?(User) && record.founding_user?
  end

  def would_remove_last_active_owner_record?
    record.is_a?(User) && record.would_remove_last_active_owner?
  end
end
