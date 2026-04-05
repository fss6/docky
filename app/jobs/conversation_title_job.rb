# frozen_string_literal: true

class ConversationTitleJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  def perform(conversation_id, user_message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?
    return unless conversation.default_title?

    user_message = conversation.messages.find_by(id: user_message_id, role: "user")
    return if user_message.blank?
    return if Rag::QueryIntent.skip_title_generation?(user_message.content)

    title = Conversations::TitleGenerator.generate(user_message.content)
    return if title.blank?

    conversation.update!(title: title)
    broadcast_title_updates(conversation)
  rescue Openai::Completion::MissingApiKeyError => e
    Rails.logger.warn("[ConversationTitleJob] #{e.message}")
  rescue Openai::Completion::Error => e
    Rails.logger.error("[ConversationTitleJob] #{e.class}: #{e.message}")
  end

  private

  def broadcast_title_updates(conversation)
    stream = "conversation_#{conversation.id}"

    Turbo::StreamsChannel.broadcast_replace_to(
      stream,
      target: dom_id(conversation, :title_header),
      partial: "conversations/title_header_span",
      locals: { conversation: conversation }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream,
      target: dom_id(conversation, :sidebar_title_desktop),
      partial: "conversations/sidebar_title_span",
      locals: { conversation: conversation, variant: :desktop }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream,
      target: dom_id(conversation, :sidebar_title_mobile),
      partial: "conversations/sidebar_title_span",
      locals: { conversation: conversation, variant: :mobile }
    )
  end
end
