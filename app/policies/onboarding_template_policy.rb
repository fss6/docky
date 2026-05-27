# frozen_string_literal: true

class OnboardingTemplatePolicy < ApplicationPolicy
  def index?
    user.role_member? || user.role_owner? || user.role_administrator?
  end

  def show?
    index?
  end

  def update?
    index?
  end

  def create?
    update?
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account_id: user.account_id)
    end
  end
end
