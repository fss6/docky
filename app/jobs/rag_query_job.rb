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

    if Rag::GreetingMessage.only?(user_message.content)
      unless indexed?(conversation, user_message)
        finish_with_text(
          ai_message,
          conversation,
          "Olá! Sou o assistente desta conta — estou aqui para ajudar você a entender os documentos que enviar: " \
          "pode perguntar o que quiser sobre o texto, pedir resumos, localizar cláusulas ou dados; respondo com base no que estiver indexado e cito arquivo e página quando fizer sentido.\n\n" \
          "Ainda não há arquivos processados. Depois do upload e do processamento, envie sua primeira pergunta e seguimos."
        )
        return
      end

      stream_greeting_reply(ai_message, conversation, user_message)
      return
    end

    case Rag::QueryIntent.kind(user_message.content)
    when :meta_identity
      finish_with_text(ai_message, conversation, Rag::QueryIntent::Responses.meta_identity)
      return
    when :meta_capabilities
      finish_with_text(ai_message, conversation, Rag::QueryIntent::Responses.meta_capabilities)
      return
    when :out_of_scope
      finish_with_text(ai_message, conversation, Rag::QueryIntent::Responses.out_of_scope)
      return
    end

    unless indexed?(conversation, user_message)
      finish_with_text(ai_message, conversation, "Nenhum documento indexado. Faça upload e aguarde o processamento.")
      return
    end

    focus_id = user_message.focus_document_id
    document_ids = focus_id.present? ? [focus_id] : nil

    records = nil
    retrieval_question = Rag::RetrievalQuery.build(conversation: conversation, user_message: user_message)
    begin
      records = Rag::Retrieve.call(
        account_id: conversation.account_id,
        question: retrieval_question,
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
      finish_with_text(
        ai_message,
        conversation,
        Rag::QueryIntent::Responses.no_relevant_chunks(focus_document: focus_id.present?)
      )
      return
    end

    context = records.map.with_index do |r, i|
      info = r.source_info
      "--- Trecho #{i + 1} (#{info['file']} · p. #{info['page'] || '?'}) ---\n#{r.content}"
    end.join("\n\n")

    stream_llm_reply(ai_message, conversation, user_message, context, records)
  end

  private

  def stream_greeting_reply(ai_message, conversation, user_message)
    stream_llm_reply(ai_message, conversation, user_message, "", nil)
  end

  def stream_llm_reply(ai_message, conversation, user_message, context, records)
    history = LlmConversationHistory.for_conversation(conversation, before_message_id: user_message.id)

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

    ai_message.reload
    sources =
      if records.present?
        Rag::AnswerSources.source_infos_for_answer(records: records, answer_text: ai_message.content)
      else
        []
      end
    ai_message.update!(sources: sources, streaming: false)

    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{conversation.id}",
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload, account: conversation.account }
    )
  end

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
      locals: { message: ai_message.reload, account: conversation.account }
    )
  end
end
