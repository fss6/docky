# frozen_string_literal: true

class PlatformSettingPolicy < ApplicationPolicy
  def show?
    user.role_administrator?
  end

  def update?
    user.role_administrator?
  end
end
