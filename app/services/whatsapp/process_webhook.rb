# frozen_string_literal: true

module Whatsapp
  class ProcessWebhook
    OPT_OUT_PATTERN = /\A\s*(parar|stop|cancelar|sair)\s*\z/i

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    def call
      entries = @payload.fetch("entry", [])
      entries.each do |entry|
        Array(entry["changes"]).each do |change|
          process_change(change)
        end
      end
    end

    private

    def process_change(change)
      value = change["value"] || {}
      Array(value["statuses"]).each { |status| process_status(status) }
      Array(value["messages"]).each { |message| process_inbound_message(message) }
    end

    def process_status(status)
      wamid = status["id"]
      return if wamid.blank?

      dispatch = CollectionDispatch.find_by(provider_message_id: wamid)
      return unless dispatch

      event_name = status["status"].to_s
      return if event_name.blank?

      tier = %w[read delivered].include?(event_name) ? :strong : :strong
      dispatch.delivery_events.create!(
        event: event_name,
        occurred_at: Time.zone.at(status["timestamp"].to_i),
        reliability_tier: tier,
        raw_payload: status
      )
    end

    def process_inbound_message(message)
      from = message.dig("from")
      text = extract_text(message)
      return if from.blank?

      clients = find_clients_by_phone(from)
      return if clients.empty?

      if opt_out_message?(text)
        clients.each { |client| apply_opt_out!(client) }
        Whatsapp::ChannelResolver.client.send_text_message(
          to: from,
          body: "Ok! Você não receberá mais lembretes automáticos por WhatsApp."
        )
      end
    end

    def extract_text(message)
      message.dig("text", "body").to_s
    end

    def opt_out_message?(text)
      OPT_OUT_PATTERN.match?(text.to_s.strip)
    end

    def find_clients_by_phone(from)
      normalized = PhoneNormalizer.normalize(from)
      return [] if normalized.blank?

      Client.kept.where.not(phone: [nil, ""]).select do |client|
        PhoneNormalizer.same?(client.phone, from)
      end
    end

    def apply_opt_out!(client)
      pref = ClientCollectionPreference.ensure_for!(client)
      pref.update!(
        whatsapp_opted_out_at: Time.current,
        whatsapp_opt_out_source: :reply_parar
      )
    end
  end
end
