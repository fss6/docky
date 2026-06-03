# frozen_string_literal: true

namespace :collection do
  desc "Executa avaliação diária dos lembretes automáticos (opcional: DATE=2026-06-02)"
  task tick: :environment do
    date = ENV["DATE"].presence
    Collection::DailyTickJob.perform_now(date)
    puts "Collection tick enqueued/completed."
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
