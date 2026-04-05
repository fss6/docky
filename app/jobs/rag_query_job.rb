# frozen_string_literal: true

class RagQueryJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  def perform(ai_message_id)
    ai_message = Message.find_by(id: ai_message_id)
    return if ai_message.blank? || !ai_message.assistant?

    conversation = ai_message.conversation
    user_message = conversation.messages.where(role: "user").where("id < ?", ai_message.id).order(:id).last
    return if user_message.blank?

    unless indexed?(conversation, user_message)
      finish_with_text(ai_message, conversation, "Nenhum documento indexado. Faça upload e aguarde o processamento.")
      return
    end

    focus_id = user_message.focus_document_id
    document_ids = focus_id.present? ? [focus_id] : nil

    records = nil
    begin
      records = Rag::Retrieve.call(
        account_id: conversation.account_id,
        question: user_message.content,
        document_ids: document_ids,
        limit: 5
      )
    rescue Openai::Embeddings::MissingApiKeyError
      finish_with_text(ai_message, conversation, "Configuração ausente: defina OPENAI_API_KEY.")
      return
    rescue Openai::Embeddings::Error => e
      Rails.logger.error("[RagQueryJob] embeddings: #{e.class}: #{e.message}")
      finish_with_text(ai_message, conversation, "Erro ao buscar trechos nos documentos. Tente novamente.")
      return
    end

    if records.blank?
      hint = focus_id.present? ? "neste documento." : "nos documentos da conta."
      finish_with_text(ai_message, conversation, "Não encontrei informação relevante #{hint}")
      return
    end

    context = records.map.with_index do |r, i|
      info = r.source_info
      "--- Trecho #{i + 1} (#{info['file']} · p. #{info['page'] || '?'}) ---\n#{r.content}"
    end.join("\n\n")

    history = conversation.messages
      .where("id < ?", user_message.id)
      .order(:id)
      .map { |m| { role: m.role, content: m.content.to_s } }

    begin
      LlmService.stream(context: context, history: history, user_content: user_message.content) do |token|
        next if token.blank?

        new_content = ai_message.content.to_s + token
        ai_message.update_column(:content, new_content)
        Turbo::StreamsChannel.broadcast_replace_to(
          "conversation_#{conversation.id}",
          target: dom_id(ai_message, :content),
          partial: "messages/content",
          locals: { message: ai_message }
        )
      end
    rescue Openai::Chat::MissingApiKeyError
      finish_with_text(ai_message, conversation, "Configuração ausente: defina OPENAI_API_KEY.")
      return
    rescue Openai::Chat::Error => e
      Rails.logger.error("[RagQueryJob] #{e.class}: #{e.message}")
      finish_with_text(ai_message, conversation, "Erro ao gerar resposta. Tente novamente.")
      return
    end

    sources = records.map(&:source_info).uniq do |s|
      [s["file"], s["page"], s["chunk_id"]]
    end
    ai_message.reload
    ai_message.update!(sources: sources, streaming: false)

    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{conversation.id}",
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload }
    )
  end

  private

  def indexed?(conversation, user_message)
    scope = EmbeddingRecord.where(account_id: conversation.account_id).where.not(embedding: nil)
    fid = user_message.focus_document_id
    scope = scope.where(document_id: fid) if fid.present?
    scope.exists?
  end

  def finish_with_text(ai_message, conversation, text)
    ai_message.update!(content: text, sources: [], streaming: false)
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{conversation.id}",
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload }
    )
  end
end
