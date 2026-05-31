# frozen_string_literal: true

class ClientPolicy < ApplicationPolicy
  def index?
    allow_capability?("clients.read")
  end

  def show?
    allow_capability?("clients.read")
  end

  def create?
    allow_capability?("clients.write")
  end

  def new?
    create?
  end

  def update?
    allow_capability?("clients.write") && record_kept?
  end

  def edit?
    update?
  end

  def archive?
    allow_capability?("clients.write") && record_kept?
  end

  def unarchive?
    allow_capability?("clients.write") && record_archived?
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

  def manage_onboarding_checklist?
    show? && record_kept?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.kept
    end
  end

  private

  def record_kept?
    record.is_a?(Class) || !record.archived?
  end

  def record_archived?
    !record.is_a?(Class) && record.archived?
  end
end
