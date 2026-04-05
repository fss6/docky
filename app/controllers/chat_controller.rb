# frozen_string_literal: true

class ChatController < ApplicationController
  def index
    account = Account.order(:id).first
    unless account
      redirect_to accounts_path, alert: "Crie uma conta para usar o chat."
      return
    end

    user = account.users.order(:id).first
    unless user
      redirect_to account_path(account), alert: "Adicione um usuário à conta para usar o chat."
      return
    end

    if params[:focus_document_id].present?
      conversation = account.conversations.create!(user: user, title: Conversation::DEFAULT_TITLE)
      redirect_to account_conversation_path(
        account,
        conversation,
        focus_document_id: params[:focus_document_id]
      )
      return
    end

    redirect_to account_conversations_path(account)
  end
end
