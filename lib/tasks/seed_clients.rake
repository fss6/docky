# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Seed de clientes demo (50 clientes, períodos, etc.) — só development"
    task clients: :environment do
      unless Rails.env.development?
        abort "db:seed:clients só pode rodar em development (RAILS_ENV=#{Rails.env})."
      end

      require Rails.root.join("db/seeds/clients")
      Seeds::Clients.run!
    end
  end
end
