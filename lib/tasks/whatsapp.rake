# frozen_string_literal: true

namespace :whatsapp do
  desc "Verifica configuração da Meta Cloud API (plataforma Dokivo)"
  task test: :environment do
    if Whatsapp::PlatformConfig.configured?
      puts "OK: WhatsApp configurado (phone_number_id=#{Whatsapp::PlatformConfig.phone_number_id})"
    else
      puts "Faltando: #{Whatsapp::PlatformConfig.missing_keys.join(', ')}"
      exit 1
    end
  end
end
