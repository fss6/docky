# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  def index?
    member_or_owner?
  end

  def show?
    member_or_owner?
  end

  def create?
    member_or_owner?
  end

  def new?
    create?
  end

  def update?
    member_or_owner? && record_kept?
  end

  def edit?
    update?
  end

  def archive?
    member_or_owner? && record_kept?
  end

  def unarchive?
    member_or_owner? && record_archived?
  end

  def destroy?
    false
  end

  def activate_onboarding?
    show? && record_kept?
  end

  def reopen_onboarding?
    show? && record_kept?
  end

  def start_onboarding?
    show? && record_kept?
  end

  def manage_onboarding_checklist?
    show? && record_kept?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.kept
    end
  end

  private

  def member_or_owner?
    user.role_member? || user.role_owner?
  end

  def record_kept?
    record.is_a?(Class) || !record.archived?
  end

  def record_archived?
    !record.is_a?(Class) && record.archived?
  end
end
