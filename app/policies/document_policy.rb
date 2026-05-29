# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  def index?
    allow_capability?("documents.read")
  end

  def show?
    allow_capability?("documents.read")
  end

  def tags_search?
    index?
  end

  def term_search?
    index?
  end

  def add_tag?
    update?
  end

  def move?
    update?
  end

  def replace_tag?
    update?
  end

  def remove_tag?
    update?
  end

  def create?
    allow_capability?("documents.write")
  end

  def new?
    create?
  end

  def update?
    allow_capability?("documents.write")
  end

  def edit?
    update?
  end

  def destroy?
    allow_capability?("documents.destroy")
  end

  class Scope < ApplicationPolicy::Scope
  end
end
