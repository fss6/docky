# frozen_string_literal: true

# Gera chunks de texto (OCR do extrato) e vetores em EmbeddingRecord para RAG.
class BankStatementImportEmbeddingRecordsJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  retry_on ::Openai::Embeddings::Error, wait: :polynomially_longer, attempts: 5

  def perform(bank_statement_import_id)
    import = BankStatementImport.find(bank_statement_import_id)
    ActsAsTenant.with_tenant(import.account) do
      import.embedding_records.destroy_all

      body = import.ocr_text.to_s.strip
      if body.blank?
        Rails.logger.info("[BankStatementImportEmbeddingRecordsJob] import #{import.id}: ocr_text vazio; sem chunks.")
        return
      end

      fname =
        if import.file.attached?
          import.file.filename.to_s
        else
          "extrato-#{import.id}.pdf"
        end

      ::MistralOcr::ChunkPageMarkdown.call(body).each_with_index do |chunk_text, chunk_index|
        ::EmbeddingRecord.create!(
          account: import.account,
          recordable: import,
          document_id: nil,
          content: chunk_text,
          metadata: {
            "chunk_index" => chunk_index,
            "source" => "bank_statement_ocr",
            "filename" => fname,
            "client_id" => import.client_id,
            "bank_statement_import_id" => import.id,
            "institution_id" => import.institution_id
          }
        )
      end

      records = import.embedding_records.pending_embedding.order(:id).to_a
      ::EmbeddingRecords::Embed.call(records)
    end
  end
end
