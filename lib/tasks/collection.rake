# frozen_string_literal: true

namespace :collection do
  desc "Executa avaliação diária dos lembretes automáticos (opcional: DATE=2026-06-02)"
  task tick: :environment do
    date = ENV["DATE"].presence
    Collection::DailyTickJob.perform_now(date)
    puts "Collection tick: DailyTickJob concluído; EvaluateAccountJob enfileirado por conta."
    puts "Requer worker Sidekiq rodando (docker compose up web worker)."
    puts "Dispatches antigos em scheduled: rails collection:flush"
  end

  desc "Reenfileira envio de dispatches scheduled elegíveis (janela de envio, SMTP, etc.)"
  task flush: :environment do
    count = Collection::FlushScheduledDispatchesJob.perform_now
    puts "Collection flush: #{count} envio(s) enfileirado(s). Requer worker Sidekiq."
  end

  desc "Garante etapas padrão dos lembretes automáticos para todas as contas"
  task seed_ladders: :environment do
    Account.find_each do |account|
      CollectionSetting.ensure_for!(account)
      Collection::SeedDefaultSteps.call(account: account)
      puts "Account #{account.id}: #{account.collection_steps.count} steps"
    end
  end
end
