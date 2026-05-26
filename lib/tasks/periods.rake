# frozen_string_literal: true

namespace :periods do
  desc "Abre a competência do mês atual para todos os clientes (agendar dia 1 às 00:30 America/Sao_Paulo)"
  task open_current_month: :environment do
    Periods::OpenMonthJob.perform_now
    puts "Competências de #{Date.current.beginning_of_month.strftime('%Y-%m')} abertas."
  end
end
