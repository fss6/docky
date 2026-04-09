# frozen_string_literal: true

class WikiEmbedJob < ApplicationJob
  queue_as :embeddings

  discard_on ActiveRecord::RecordNotFound

  def perform(wiki_page_id)
    page = WikiPage.find(wiki_page_id)
    return if page.content.blank?
    return if ENV["OPENAI_API_KEY"].to_s.blank?

    model = ENV.fetch("OPENAI_EMBEDDING_MODEL", Openai::Embeddings::DEFAULT_MODEL)
    vector = Openai::Embeddings.call(texts: [page.content.truncate(8000)], model: model).first

    record = EmbeddingRecord.find_or_initialize_by(
      recordable_type: "WikiPage",
      recordable_id: page.id
    )

    record.assign_attributes(
      account_id: page.account_id,
      content: page.content,
      embedding: vector,
      metadata: (record.metadata || {}).merge(
        "slug"              => page.slug,
        "page_type"         => page.page_type,
        "title"             => page.title,
        "embedding_model"   => model,
        "embedded_at"       => Time.current.iso8601
      )
    )
    record.save!
  rescue Openai::Embeddings::MissingApiKeyError
    Rails.logger.info("[WikiEmbedJob] OPENAI_API_KEY ausente; pulando.")
  rescue Openai::Embeddings::Error => e
    Rails.logger.error("[WikiEmbedJob] #{e.class}: #{e.message}")
    raise
  end
end
