# frozen_string_literal: true

module ClientsHelper
  include AppConfirmModalHelper

  VALID_TABS = %w[documentos checklist convites historico].freeze

  def client_initials(client)
    parts = client.name.to_s.split(/\s+/).reject(&:blank?).first(2)
    parts.map { |p| p[0] }.join.upcase.presence || "?"
  end

  def client_tab_active?(tab, active_tab)
    tab.to_s == active_tab.to_s
  end

  def client_tab_classes(tab, active_tab)
    base = "inline-flex items-center gap-2 border-b-2 px-1 pb-3 text-sm font-medium no-underline transition-colors"
    if client_tab_active?(tab, active_tab)
      "#{base} client-tab-active"
    else
      "#{base} border-transparent text-zinc-500 hover:border-zinc-300 hover:text-zinc-700"
    end
  end

  def client_show_path(client, aba: nil, period: nil)
    params = {}
    params[:aba] = aba if aba.present?
    params[:period] = period.strftime("%Y-%m") if period.present?
    client_path(client, params)
  end

  def client_period_label(period)
    period_display_label(period)
  end

  def client_period_context_label(period)
    reference = period.to_date.beginning_of_month
    current = Date.current.beginning_of_month

    if reference == current
      "Atual"
    elsif reference < current
      "Retroativa"
    else
      "Futura"
    end
  end

  def client_period_phase(period)
    reference = period.to_date.beginning_of_month
    current = Date.current.beginning_of_month

    if reference == current
      :current
    elsif reference < current
      :past
    else
      :future
    end
  end

  def client_period_context_chip_classes(period)
    case client_period_phase(period)
    when :current
      "bg-sky-50 text-sky-800 ring-1 ring-inset ring-sky-600/20"
    when :past
      "bg-zinc-100 text-zinc-700 ring-1 ring-inset ring-zinc-300"
    else
      "bg-violet-50 text-violet-800 ring-1 ring-inset ring-violet-600/20"
    end
  end

  def client_period_navigator_icon_classes(period)
    case client_period_phase(period)
    when :current
      "h-4 w-4 shrink-0 text-sky-600"
    else
      "h-4 w-4 shrink-0 text-zinc-400"
    end
  end

  def client_period_navigator_picker_button_classes(period)
    base = "inline-flex items-center gap-2 rounded-lg border px-2 py-1 hover:border-zinc-200 hover:bg-zinc-50"
    if client_period_phase(period) == :current
      "#{base} border-sky-200 bg-sky-50"
    else
      "#{base} border-transparent"
    end
  end

  def client_period_navigator_label_classes(period)
    case client_period_phase(period)
    when :current
      "text-sm font-semibold text-sky-800"
    else
      "text-sm font-semibold text-zinc-900"
    end
  end

  def client_period_in_progress_chip_classes
    "inline-flex shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold bg-sky-50 text-sky-800 ring-1 ring-inset ring-sky-600/20"
  end

  def client_period_go_to_current_label
    "Ir para #{period_display_label(Date.current)}"
  end

  def client_period_go_to_current_link_classes
    "inline-flex shrink-0 items-center rounded-md border border-zinc-300 bg-white px-2 py-1 text-xs font-medium text-zinc-800 no-underline hover:border-zinc-400 hover:bg-zinc-50"
  end

  TAB_LABELS = {
    "documentos" => "Documentos",
    "checklist" => "Pendências do mês",
    "convites" => "Convites & Links",
    "historico" => "Histórico"
  }.freeze

  def summary_status_badge_classes(tone)
    case tone.to_sym
    when :success
      "bg-emerald-50 text-emerald-800 ring-1 ring-inset ring-emerald-600/20"
    when :warning
      "bg-amber-50 text-amber-900 ring-1 ring-inset ring-amber-600/20"
    when :neutral
      "bg-zinc-100 text-zinc-700 ring-1 ring-inset ring-zinc-300"
    else
      "bg-zinc-100 text-zinc-700"
    end
  end

  def period_lifecycle_label(period_record)
    return "—" if period_record.blank?

    period_record.closed? ? "Encerrada" : "Aberta"
  end

  def period_close_confirm_modal_data(url:, period_label:)
    app_confirm_modal_open_data(
      url: url,
      item_label: period_label,
      http_method: "patch",
      heading: "Fechar competência?",
      body_prefix: "Você está encerrando a competência ",
      body_suffix: ". Novos envios pelo portal e uploads internos ficarão bloqueados para esta competência.",
      confirm_text: "Fechar competência",
      confirm_variant: "primary"
    )
  end

  def period_activity_category_classes(category)
    case category.to_sym
    when :document
      "bg-sky-50 text-sky-700 ring-1 ring-inset ring-sky-600/15"
    when :checklist
      "bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/15"
    when :period
      "bg-violet-50 text-violet-700 ring-1 ring-inset ring-violet-600/15"
    when :invite
      "bg-amber-50 text-amber-800 ring-1 ring-inset ring-amber-600/15"
    else
      "bg-zinc-100 text-zinc-600 ring-1 ring-inset ring-zinc-300"
    end
  end

  def period_activity_icon(category)
    case category.to_sym
    when :document then "document-text"
    when :checklist then "clipboard-document-check"
    when :period then "calendar"
    when :invite then "link"
    else "clock"
    end
  end

  def period_reopen_confirm_modal_data(url:, period_label:)
    app_confirm_modal_open_data(
      url: url,
      item_label: period_label,
      http_method: "patch",
      heading: "Reabrir competência?",
      body_prefix: "Você está reabrindo a competência ",
      body_suffix: ". O cliente poderá voltar a enviar documentos deste período.",
      confirm_text: "Reabrir competência",
      confirm_variant: "primary"
    )
  end

  def period_lifecycle_chip_classes(period_record)
    return "bg-zinc-100 text-zinc-700 ring-1 ring-inset ring-zinc-300" if period_record.blank?

    if period_record.closed?
      "bg-zinc-100 text-zinc-700 ring-1 ring-inset ring-zinc-300"
    else
      "bg-emerald-50 text-emerald-800 ring-1 ring-inset ring-emerald-600/20"
    end
  end

  def public_upload_host
    raw = ENV["PUBLIC_APP_HOST"].presence || request&.host || "localhost"
    raw.sub(/\Aportal\./, "")
  end

  def public_upload_protocol
    request&.protocol&.delete_suffix("://") || "https"
  end

  def client_public_upload_url(token)
    public_folder_upload_url(
      token: token,
      host: public_upload_host,
      protocol: public_upload_protocol
    )
  end

  def upload_invite_share_text(client, url)
    "Olá! Envie seus documentos de #{client.name} pelo link: #{url}"
  end

  def upload_invite_whatsapp_url(client, url)
    text = upload_invite_share_text(client, url)
    "https://wa.me/?text=#{ERB::Util.url_encode(text)}"
  end

  def upload_invite_mailto_url(client, url)
    subject = "Envio de documentos — #{client.name}"
    body = upload_invite_share_text(client, url)
    "mailto:?subject=#{ERB::Util.url_encode(subject)}&body=#{ERB::Util.url_encode(body)}"
  end
end
