# frozen_string_literal: true

class SettingPolicy < ApplicationPolicy
  def show?
    allow_capability?("settings.read")
  end

  def update?
    allow_capability?("settings.manage")
  end

  def edit?
    update?
  end
end
