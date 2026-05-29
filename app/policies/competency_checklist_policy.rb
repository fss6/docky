# frozen_string_literal: true

class CompetencyChecklistPolicy < ApplicationPolicy
  def show?
    allow_capability?("clients.read")
  end

  def refresh_receipts?
    allow_capability?("clients.write")
  end

  def create_template_item?
    allow_capability?("clients.write")
  end

  def mark_validated?
    allow_capability?("clients.write")
  end

  def mark_pending?
    allow_capability?("clients.write")
  end

  def remove_item?
    allow_capability?("clients.write")
  end

  def attach_document?
    allow_capability?("clients.write")
  end

  def detach_document?
    allow_capability?("clients.write")
  end
end
