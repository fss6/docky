# frozen_string_literal: true

class OnboardingTemplatePolicy < ApplicationPolicy
  def index?
    allow_capability?("settings.read")
  end

  def show?
    index?
  end

  def edit?
    update?
  end

  def update?
    allow_capability?("settings.manage")
  end

  def create?
    update?
  end

  def new?
    create?
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
