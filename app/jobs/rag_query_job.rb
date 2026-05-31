# frozen_string_literal: true

class RagQueryJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  STRUCTURED_ERROR_TEXT = "Não foi possível gerar a resposta. Tente novamente."
  TABULAR_ERROR_TEXT = "Não foi possível gerar a tabela. Tente novamente."

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

    case Rag::QueryIntent.kind(user_message.content, conversation: conversation, user_message: user_message)
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

    focus_id     = user_message.focus_document_id
    document_ids = focus_id.present? ? [focus_id] : nil

    retrieval_question = Rag::RetrievalQuery.build(conversation: conversation, user_message: user_message)
    account = conversation.account

    wiki_result = nil
    begin
      wiki_result = Wiki::QueryService.new(
        retrieval_question,
        account,
        document_ids: document_ids
      ).call
    rescue Openai::Embeddings::MissingApiKeyError
      finish_with_text(ai_message, conversation, "Configuração ausente: defina OPENAI_API_KEY.")
      return
    rescue Openai::Embeddings::Error => e
      Rails.logger.error("[RagQueryJob] embeddings: #{e.class}: #{e.message}")
      finish_with_text(ai_message, conversation, "Erro ao buscar trechos nos documentos. Tente novamente.")
      return
    end

    wiki_chunks = wiki_result[:wiki_chunks]
    doc_chunks  = wiki_result[:doc_chunks]
    all_records = wiki_chunks + doc_chunks

    if all_records.blank?
      finish_with_text(
        ai_message,
        conversation,
        Rag::QueryIntent::Responses.no_relevant_chunks(focus_document: focus_id.present?)
      )
      return
    end

    context = { wiki_chunks: wiki_chunks, doc_chunks: doc_chunks }

    tabular = Rag::QueryIntent.tabular_request?(
      user_message.content,
      conversation: conversation,
      user_message: user_message
    )
    mode = tabular ? :tabular : :document
    thinking_intent = Messages::ThinkingStatus.intent_for(user_message: user_message, tabular: tabular)
    focus_name = focus_document_display_name(focus_id)

    broadcast_thinking(
      ai_message,
      conversation,
      phase: "retrieving",
      intent: thinking_intent,
      chunks_count: all_records.size,
      focus_document_name: focus_name,
      tabular: tabular
    )

    structured_assistant_reply(
      ai_message,
      conversation,
      user_message,
      context,
      all_records,
      mode: mode,
      thinking_intent: thinking_intent,
      chunks_count: all_records.size,
      focus_document_name: focus_name
    )
  end

  private

  def stream_greeting_reply(ai_message, conversation, user_message)
    stream_llm_reply(ai_message, conversation, user_message, "", nil)
  end

  def stream_llm_reply(ai_message, conversation, user_message, context, records)
    history = LlmConversationHistory.for_conversation(conversation, before_message_id: user_message.id)
    buffer = +""

    begin
      LlmService.stream(context: context, history: history, user_content: user_message.content) do |token|
        next if token.blank?

        buffer = append_stream_token(buffer, token)
      end
    rescue Openai::Chat::MissingApiKeyError
      finish_with_text(ai_message, conversation, "Configuração ausente: defina OPENAI_API_KEY.")
      return
    rescue Openai::Chat::Error => e
      Rails.logger.error("[RagQueryJob] #{e.class}: #{e.message}")
      finish_with_text(ai_message, conversation, "Erro ao gerar resposta. Tente novamente.")
      return
    end

    final_content = Messages::StripInlineCitations.call(buffer.to_s)
    sources =
      if records.present?
        Rag::AnswerSources.source_infos_for_answer(
          records: records,
          answer_text: buffer.to_s,
          question_text: user_message.content
        )
      else
        []
      end
    metadata = ai_message.metadata.is_a?(Hash) ? ai_message.metadata.dup : {}
    metadata.delete("loading")
    metadata.delete("thinking")
    ai_message.update!(
      content: final_content,
      sources: sources,
      streaming: false,
      metadata: metadata
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_for(conversation),
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload, account: conversation.account }
    )
  end

  def stream_for(conversation)
    "conversation_#{conversation.id}"
  end

  def indexed?(conversation, user_message)
    account_id = conversation.account_id
    fid = user_message.focus_document_id

    doc_scope = EmbeddingRecord.where(account_id: account_id, recordable_type: "Document").where.not(embedding: nil)
    doc_scope = doc_scope.where(document_id: fid) if fid.present?
    return true if doc_scope.exists?

    return false if fid.present?

    EmbeddingRecord.where(account_id: account_id, recordable_type: "WikiPage").where.not(embedding: nil).exists?
  end

  def structured_assistant_reply(ai_message, conversation, user_message, context, records, mode:,
                                 thinking_intent:, chunks_count:, focus_document_name: nil)
    broadcast_thinking(
      ai_message,
      conversation,
      phase: "generating",
      intent: thinking_intent,
      chunks_count: chunks_count,
      focus_document_name: focus_document_name,
      tabular: mode == :tabular
    )

    history = LlmConversationHistory.for_conversation(conversation, before_message_id: user_message.id)
    effective_question =
      if mode == :tabular
        Rag::QueryIntent.tabular_effective_question(user_message, conversation)
      else
        user_message.content
      end

    result = call_structured_assistant_reply(
      context: context,
      history: history,
      user_content: effective_question,
      mode: mode
    )

    raw_answer = Messages::AiComponents::Registry.plain_text_answer(
      summary: result.summary,
      components: result.components
    )
    components = Messages::StripInlineCitations.strip_components(result.components)
    answer_text = Messages::StripInlineCitations.call(raw_answer)
    sources =
      if records.present?
        Rag::AnswerSources.source_infos_for_answer(
          records: records,
          answer_text: raw_answer,
          question_text: user_message.content
        )
      else
        []
      end

    metadata = ai_message.metadata.is_a?(Hash) ? ai_message.metadata.dup : {}
    metadata["schema_version"] = result.schema_version
    metadata["components"] = components
    metadata["tables"] = legacy_tables_from_components(result.components)
    metadata.delete("loading")
    metadata.delete("thinking")

    ai_message.update!(
      content: answer_text,
      metadata: metadata,
      sources: sources,
      streaming: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_for(conversation),
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload, account: conversation.account }
    )
  rescue Openai::Completion::MissingApiKeyError
    finish_with_text(ai_message, conversation, "Configuração ausente: defina OPENAI_API_KEY.")
  rescue Openai::Completion::Error,
         JSON::ParserError,
         Messages::AiComponents::Registry::EmptyResponseError,
         Messages::AiComponents::Registry::MissingTableError => e
    Rails.logger.error("[RagQueryJob] structured_assistant_reply failed: #{e.class}: #{e.message}")
    error_text = mode == :tabular ? TABULAR_ERROR_TEXT : STRUCTURED_ERROR_TEXT
    finish_with_text(ai_message, conversation, error_text)
  end

  def broadcast_thinking(ai_message, conversation, phase:, intent:, chunks_count:, focus_document_name: nil,
                         tabular: false)
    metadata = ai_message.metadata.is_a?(Hash) ? ai_message.metadata.dup : {}
    metadata["loading"] = tabular ? "tabular" : "assistant"
    metadata["thinking"] = Messages::ThinkingStatus.thinking_payload(
      phase: phase,
      intent: intent,
      chunks_count: chunks_count,
      focus_document_name: focus_document_name
    )
    ai_message.update!(content: "", metadata: metadata, streaming: true)
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_for(conversation),
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload, account: conversation.account }
    )
  end

  def focus_document_display_name(focus_id)
    return nil if focus_id.blank?

    document = Document.find_by(id: focus_id)
    return nil if document.blank? || !document.file.attached?

    document.file.filename.to_s
  end

  def call_structured_assistant_reply(context:, history:, user_content:, mode:)
    attempts = 0
    begin
      attempts += 1
      Messages::StructuredAssistantReply.call(
        context: context,
        history: history,
        user_content: user_content,
        mode: mode
      )
    rescue Openai::Completion::Error => e
      raise if attempts >= 2

      Rails.logger.warn("[RagQueryJob] structured_assistant_reply retry: #{e.class}: #{e.message}")
      retry
    end
  end

  def legacy_tables_from_components(components)
    Array(components).filter_map do |component|
      next unless component["type"] == "table"

      data = component["data"]
      {
        "title" => data["title"],
        "columns" => data["headers"],
        "rows" => data["rows"]
      }
    end
  end

  def finish_with_text(ai_message, conversation, text)
    metadata = ai_message.metadata.is_a?(Hash) ? ai_message.metadata.dup : {}
    metadata.delete("loading")
    metadata.delete("thinking")
    ai_message.update!(content: text, sources: [], streaming: false, metadata: metadata)
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_for(conversation),
      target: dom_id(ai_message),
      partial: "messages/message",
      locals: { message: ai_message.reload, account: conversation.account }
    )
  end

  def append_stream_token(current_text, token)
    return current_text + token if current_text.blank?

    last_char = current_text[-1]
    first_char = token[0]
    needs_space = (letter?(last_char) && digit?(first_char)) || (digit?(last_char) && letter?(first_char))

    needs_space ? "#{current_text} #{token}" : current_text + token
  end

  def letter?(char)
    char.to_s.match?(/[[:alpha:]]/)
  end

  def digit?(char)
    char.to_s.match?(/\d/)
  end
end
