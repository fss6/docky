# frozen_string_literal: true

module Collection
  class TimelineBuilder
    Event = Struct.new(:kind, :title, :description, :occurred_at, :delivery_label, keyword_init: true)

    def self.call(client:, period_record:)
      new(client: client, period_record: period_record).call
    end

    def initialize(client:, period_record:)
      @client = client
      @period_record = period_record
    end

    def call
      events = []
      events.concat(dispatch_events)
      events.concat(audit_events)
      events.sort_by(&:occurred_at).reverse
    end

    private

    def dispatch_events
      dispatches = CollectionDispatch.where(client: @client, period: @period_record)
        .includes(:collection_step, :delivery_events)
        .order(created_at: :desc)

      dispatches.flat_map do |dispatch|
        list = []
        list << Event.new(
          kind: dispatch.channel,
          title: "#{dispatch.collection_step.name} · #{channel_label(dispatch)}",
          description: dispatch.rendered_body.to_s.truncate(200),
          occurred_at: dispatch.sent_at || dispatch.created_at,
          delivery_label: delivery_label_for(dispatch)
        )
        dispatch.delivery_events.each do |ev|
          list << Event.new(
            kind: "#{dispatch.channel}_status",
            title: "Status · #{ev.event}",
            description: "",
            occurred_at: ev.occurred_at,
            delivery_label: ev.reliability_tier_weak? ? "#{ev.event} (e-mail, estimado)" : ev.event
          )
        end
        list
      end
    end

    def audit_events
      types = %w[
        document.received
        checklist_item.auto_matched
        collection.email_sent
        collection.whatsapp_sent
        upload_invite.email_sent
      ]
      AuditEvent.where(account: @client.account, event_type: types)
        .where("metadata->>'client_id' = ?", @client.id.to_s)
        .order(created_at: :desc)
        .limit(30)
        .map do |audit|
          presenter = AuditEvents::EventPresenter.new(audit)
          Event.new(
            kind: :system,
            title: presenter.title,
            description: presenter.description,
            occurred_at: audit.created_at,
            delivery_label: nil
          )
        end
    end

    def channel_label(dispatch)
      { "email" => "E-mail", "whatsapp" => "WhatsApp", "internal" => "Interno" }.fetch(dispatch.channel, dispatch.channel)
    end

    def delivery_label_for(dispatch)
      return dispatch.status if dispatch.status_skipped? || dispatch.status_failed?

      latest = dispatch.delivery_events.order(occurred_at: :desc).first
      return "enviado" unless latest

      if latest.event == "read" && dispatch.channel_whatsapp?
        "lida (WhatsApp)"
      elsif latest.event == "opened" && dispatch.channel_email?
        "aberto (e-mail, estimado)"
      else
        latest.event
      end
    end
  end
end
