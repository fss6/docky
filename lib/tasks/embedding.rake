# frozen_string_literal: true

namespace :embedding do
  desc "Enfileira varredura de EmbeddingRecord sem vetor (para cron ou quando não há Solid Queue recurring)"
  task sweep: :environment do
    PendingEmbeddingRecordsSweepJob.perform_later
    puts "PendingEmbeddingRecordsSweepJob enfileirado."
  end
end
