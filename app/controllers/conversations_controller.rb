# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :set_account
  before_action :authorize_policy

  def index
    @conversations = @account.conversations.includes(:user).order(updated_at: :desc)
    @sidebar_conversations = @conversations.limit(40)
  end

  def show
    @conversation = @account.conversations.find(params.expect(:id))
    @messages = @conversation.messages.order(:id)
    @document_count = @account.documents.count
    @focus_document_id = params[:focus_document_id].presence
    @focus_document =
      if @focus_document_id
        @account.documents.with_attached_file.find_by(id: @focus_document_id)
      end
    @focus_document_id = nil if @focus_document.blank? && @focus_document_id.present?

    @sidebar_conversations = @account.conversations
      .includes(:user)
      .order(updated_at: :desc)
      .limit(40)
  end

  def create
    @conversation = @account.conversations.build(conversation_params)
    @conversation.user_id ||= current_user&.id

    if @conversation.save
      redirect_to account_conversation_path(@account, @conversation),
                    notice: "Conversa criada.",
                    status: :see_other
    else
      redirect_back_or_root alert: @conversation.errors.full_messages.to_sentence
    end
  end

  def destroy
    @conversation = @account.conversations.find(params.expect(:id))
    @conversation.destroy
    redirect_to account_conversations_path(@account), notice: "Conversa removida.", status: :see_other
  end

  private

  def authorize_policy
    authorize Conversation
  end

  def set_account
    @account = current_tenant
  end

  def conversation_params
    params.expect(conversation: [:title, :user_id])
  end

  def redirect_back_or_root(alert:)
    redirect_back fallback_location: root_path, alert: alert
  end
end
