# frozen_string_literal: true

class PeriodPolicy < ApplicationPolicy
  def close?
    allow_capability?("clients.write")
  end

  def reopen?
    close?
  end

  def show?
    allow_capability?("clients.read")
  end
end
