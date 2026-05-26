# frozen_string_literal: true

# Agendamento: dia 1 de cada mês às 00:30 em America/Sao_Paulo.
# Requer sidekiq-cron no Gemfile. Alternativa sem gem: cron do host executando
#   docker compose run web rails periods:open_current_month
if defined?(Sidekiq::Cron) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash(
    "periods_open_current_month" => {
      "class" => "Periods::OpenMonthJob",
      "cron" => "30 0 1 * * America/Sao_Paulo",
      "queue" => "default"
    }
  )
end
