class WikiPagePolicy < ApplicationPolicy
  def index?
    user.role_member? || user.role_owner?
  end

  def show?
    user.role_member? || user.role_owner?
  end

  def log?
    index?
  end

  def lint_report?
    index?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
