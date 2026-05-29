# frozen_string_literal: true

class WikiPagePolicy < ApplicationPolicy
  def index?
    allow_capability?("wiki.read")
  end

  def show?
    allow_capability?("wiki.read")
  end

  def log?
    index?
  end

  def lint_report?
    index?
  end

  def destroy?
    index?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
