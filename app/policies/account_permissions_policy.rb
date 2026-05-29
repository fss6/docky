# frozen_string_literal: true

class AccountPermissionsPolicy < ApplicationPolicy
  def show?
    user.role_owner?
  end

  def update?
    user.role_owner?
  end
end
