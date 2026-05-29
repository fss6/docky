# frozen_string_literal: true

class FolderPolicy < ApplicationPolicy
  def index?
    allow_capability?("clients.read")
  end

  def drawer_empty?
    index?
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
    allow_capability?("clients.write")
  end

  def edit?
    update?
  end

  def destroy?
    allow_capability?("clients.write")
  end

  class Scope < ApplicationPolicy::Scope
  end
end
