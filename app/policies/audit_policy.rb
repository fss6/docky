# frozen_string_literal: true

class AuditPolicy < ApplicationPolicy
  def index?
    user.role_administrator? || allow_capability?("audit.read")
  end
end
