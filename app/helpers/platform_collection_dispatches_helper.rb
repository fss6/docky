# frozen_string_literal: true

module PlatformCollectionDispatchesHelper
  SKIP_REASON_LABELS = {
    "email_opt_out" => "Cliente cancelou lembretes por e-mail",
    "whatsapp_opt_out" => "Cliente cancelou lembretes por WhatsApp",
    "email_not_configured" => "SMTP não configurado na plataforma",
    "whatsapp_not_configured" => "WhatsApp não configurado na plataforma",
    "no_email" => "Cliente sem e-mail",
    "no_phone" => "Cliente sem telefone",
    "no_contact_email" => "Escritório sem e-mail de contato (alerta interno)",
    "daily_limit" => "Limite diário do canal (e-mail ou WhatsApp)",
    "missing_whatsapp_template" => "Template WhatsApp não informado na etapa"
  }.freeze

  STATUS_LABELS = {
    "scheduled" => "Agendado",
    "sent" => "Enviado",
    "failed" => "Falhou",
    "skipped" => "Ignorado"
  }.freeze

  CHANNEL_LABELS = {
    "email" => "E-mail",
    "whatsapp" => "WhatsApp",
    "internal" => "Interno"
  }.freeze

  def platform_dispatch_skip_reason_label(reason)
    return "—" if reason.blank?

    SKIP_REASON_LABELS.fetch(reason, reason)
  end

  def platform_dispatch_status_label(status)
    STATUS_LABELS.fetch(status.to_s, status.to_s.humanize)
  end

  def platform_dispatch_channel_label(channel)
    CHANNEL_LABELS.fetch(channel.to_s, channel.to_s.humanize)
  end

  def platform_dispatch_status_chip_class(dispatch)
    return "bg-red-50 text-red-800" if dispatch.status_failed?
    return "bg-amber-50 text-amber-900" if dispatch.status_scheduled? && dispatch_stale?(dispatch)
    return "bg-sky-50 text-sky-800" if dispatch.status_scheduled?

    {
      "sent" => "bg-emerald-50 text-emerald-800",
      "skipped" => "bg-zinc-100 text-zinc-700"
    }.fetch(dispatch.status, "bg-zinc-100 text-zinc-700")
  end

  def platform_dispatch_filter_params(overrides = {})
    {
      status: @filters&.status,
      channel: @filters&.channel,
      account_id: @filters&.account_id,
      skip_reason: @filters&.skip_reason,
      from: @filters&.from,
      to: @filters&.to,
      q: @filters&.q
    }.compact.merge(overrides).compact
  end

  def platform_dispatch_status_filter_chip(label, status_value)
    active = @filters&.status == status_value || (@filters&.status.blank? && status_value.blank?)
    base = "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold no-underline transition"
    classes = if active
                "#{base} bg-accent text-white"
              else
                "#{base} bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
              end
    link_to label, collection_dispatches_platform_settings_path(platform_dispatch_filter_params(status: status_value)),
            class: classes
  end

  def platform_collection_panel_link(dispatch)
    return unless dispatch.account_id == current_user.account_id

    collection_panel_path(period_id: dispatch.period_id, q: dispatch.client.name)
  end

  def dispatch_stale?(dispatch, hours: 1)
    dispatch.status_scheduled? && dispatch.created_at < hours.hours.ago
  end
end
