# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    allow_capability?("groups.read")
  end

  def show?
    allow_capability?("groups.read")
  end

  def create?
    allow_capability?("groups.manage")
  end

  def new?
    create?
  end

  def update?
    allow_capability?("groups.manage")
  end

  def edit?
    update?
  end

  def destroy?
    allow_capability?("groups.manage")
  end

  class Scope < ApplicationPolicy::Scope
  end
end
