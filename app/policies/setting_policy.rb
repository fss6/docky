class SettingPolicy < ApplicationPolicy
  def show?
    user.role_owner? || user.role_administrator?
  end

  def update?
    show?
  end
end
