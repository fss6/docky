# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy
  def index?
    allow_capability?("institutions.read")
  end

  def show?
    index?
  end

  def create?
    allow_capability?("institutions.manage")
  end

  def new?
    create?
  end

  def update?
    allow_capability?("institutions.manage")
  end

  def edit?
    update?
  end

  def destroy?
    allow_capability?("institutions.manage") && !record.system?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
