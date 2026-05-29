# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?
    allow_capability?("conversations.use")
  end

  def show?
    allow_capability?("conversations.use")
  end

  def create?
    allow_capability?("conversations.use")
  end

  def new?
    create?
  end

  def update?
    allow_capability?("conversations.use")
  end

  def edit?
    update?
  end

  def destroy?
    allow_capability?("conversations.use")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
