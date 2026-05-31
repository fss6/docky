# frozen_string_literal: true

class AccountProfilePolicy < ApplicationPolicy
  def edit?
    user&.role_owner?
  end

  def update?
    user&.role_owner?
  end
end
