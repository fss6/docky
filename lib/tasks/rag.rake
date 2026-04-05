# frozen_string_literal: true

namespace :rag do
  desc <<~DESC.squish
    Busca semântica sobre embedding_records (interação mínima com os docs).
    Uso: RAG_ACCOUNT_ID=1 RAG_QUESTION="sua pergunta" bundle exec rake rag:retrieve
    Opcional: RAG_DOCUMENT_ID=42 (restringe a um documento), RAG_LIMIT=5
  DESC
  task retrieve: :environment do
    account_id = ENV.fetch("RAG_ACCOUNT_ID")
    question = ENV.fetch("RAG_QUESTION")
    document_id = ENV["RAG_DOCUMENT_ID"].presence
    limit = (ENV["RAG_LIMIT"] || "5").to_i

    records = Rag::Retrieve.call(
      account_id: account_id,
      question: question,
      document_id: document_id,
      limit: limit
    )

    if records.empty?
      puts "Nenhum trecho com embedding encontrado (account_id=#{account_id}" \
           "#{document_id ? ", document_id=#{document_id}" : ""})."
      next
    end

    records.each_with_index do |r, i|
      dist = r.respond_to?(:neighbor_distance) ? format("%.4f", r.neighbor_distance) : "n/a"
      page = r.page_number || "?"
      fname = r.document&.file&.filename&.to_s || "(sem arquivo)"
      puts "--- ##{i + 1} distance=#{dist} page=#{page} file=#{fname} ---"
      puts r.content.to_s.truncate(800)
      puts
    end
  end
end
