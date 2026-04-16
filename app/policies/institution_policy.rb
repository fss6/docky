# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy
  def index?
    user.role_member? || user.role_owner?
  end

  def show?
    index?
  end

  def create?
    user.role_owner?
  end

  def new?
    create?
  end

  def update?
    user.role_owner?
  end

  def edit?
    update?
  end

  def destroy?
    user.role_owner? && !record.system?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
