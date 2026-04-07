# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_account_and_conversation
  before_action :authorize_policy

  def create
    content = message_params[:content].to_s.strip
    if content.blank?
      redirect_to account_conversation_path(@account, @conversation),
                  alert: "Digite uma pergunta.",
                  status: :see_other
      return
    end

    meta = user_message_metadata

    @user_message = @conversation.messages.create!(
      role: "user",
      content: content,
      streaming: false,
      metadata: meta
    )
    @ai_message = @conversation.messages.create!(role: "assistant", content: "", streaming: true)

    RagQueryJob.perform_later(@ai_message.id)

    ConversationTitleJob.perform_later(@conversation.id, @user_message.id) if @conversation.default_title?

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to account_conversation_path(@account, @conversation), status: :see_other }
    end
  end

  private

  def authorize_policy
    authorize Message
  end

  def set_account_and_conversation
    @account = current_tenant
    @conversation = @account.conversations.find(params.expect(:conversation_id))
  end

  def message_params
    params.require(:message).permit(:content, :focus_document_id)
  end

  def user_message_metadata
    fid = message_params[:focus_document_id].to_s.presence
    return {} if fid.blank?
    return {} unless @account.documents.exists?(fid)

    { "focus_document_id" => fid.to_i }
  end
end
