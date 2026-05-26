# frozen_string_literal: true

class PeriodPolicy < ApplicationPolicy
  def close?
    user.role_member? || user.role_owner?
  end

  def reopen?
    close?
  end

  def show?
    close?
  end
end
