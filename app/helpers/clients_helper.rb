# frozen_string_literal: true

module ClientsHelper
  include AppConfirmModalHelper

  VALID_TABS = %w[documentos checklist convites pastas historico].freeze

  def client_archived_badge_classes
    "inline-flex rounded-full bg-zinc-100 px-2 py-0.5 text-xs font-semibold text-zinc-700 ring-1 ring-inset ring-zinc-300"
  end

  def client_index_status_badge(client)
    if client.archived?
      tag.span(t("clients.archived.badge"), class: client_archived_badge_classes)
    elsif client.onboarding?
      tag.span("Em onboarding", class: client_onboarding_badge_classes)
    else
      tag.span("Ativo", class: "inline-flex rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-800 ring-1 ring-inset ring-emerald-600/20")
    end
  end

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

  def client_show_path(client, aba: nil, period: nil, folder_id: nil)
    params = {}
    params[:aba] = aba if aba.present?
    if period.present?
      params[:period] = period.respond_to?(:strftime) ? period.strftime("%Y-%m") : period.to_s
    end
    params[:folder_id] = folder_id if folder_id.present?
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

  def missing_period_cta_label(period_phase)
    case period_phase
    when :past
      "Criar competência retroativa"
    when :future
      "Abrir competência antecipada"
    else
      "Abrir competência"
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
    "pastas" => "Pastas",
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
    when :email
      "bg-red-50 text-[#D93025] ring-1 ring-inset ring-[#D93025]/20"
    when :email_failed
      "bg-red-100 text-red-800 ring-1 ring-inset ring-red-700/25"
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
    when :email, :email_failed then "envelope"
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

  def client_onboarding_public_url(token)
    public_onboarding_upload_url(
      token: token,
      host: public_upload_host,
      protocol: public_upload_protocol
    )
  end

  def client_onboarding_badge_classes
    "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold client-onboarding-badge ring-1 ring-inset ring-violet-600/20"
  end

  def client_onboarding_start_confirm_modal_data(client:)
    app_confirm_modal_open_data(
      url: client_onboarding_start_path(client),
      item_label: client.name,
      http_method: "post",
      heading: I18n.t("clients.onboarding_start_confirm_modal.heading"),
      body_prefix: I18n.t("clients.onboarding_start_confirm_modal.body_prefix"),
      body_suffix: I18n.t("clients.onboarding_start_confirm_modal.body_suffix"),
      confirm_text: I18n.t("clients.onboarding_start_confirm_modal.confirm"),
      confirm_variant: "primary"
    )
  end

  def client_onboarding_reopen_confirm_modal_data(client:)
    app_confirm_modal_open_data(
      url: client_onboarding_reopen_path(client),
      item_label: client.name,
      http_method: "post",
      heading: I18n.t("clients.onboarding_reopen_confirm_modal.heading"),
      body_prefix: I18n.t("clients.onboarding_reopen_confirm_modal.body_prefix"),
      body_suffix: I18n.t("clients.onboarding_reopen_confirm_modal.body_suffix"),
      confirm_text: I18n.t("clients.onboarding_reopen_confirm_modal.confirm"),
      confirm_variant: "primary"
    )
  end

  def client_archive_confirm_modal_data(client:)
    app_confirm_modal_open_data(
      url: archive_client_path(client),
      item_label: client.name,
      http_method: "post",
      heading: I18n.t("clients.archive_confirm_modal.heading"),
      body_prefix: I18n.t("clients.archive_confirm_modal.body_prefix"),
      body_suffix: I18n.t("clients.archive_confirm_modal.body_suffix"),
      confirm_text: I18n.t("clients.archive_confirm_modal.confirm"),
      confirm_variant: "danger"
    )
  end

  def client_unarchive_confirm_modal_data(client:)
    app_confirm_modal_open_data(
      url: unarchive_client_path(client),
      item_label: client.name,
      http_method: "post",
      heading: I18n.t("clients.unarchive_confirm_modal.heading"),
      body_prefix: I18n.t("clients.unarchive_confirm_modal.body_prefix"),
      body_suffix: I18n.t("clients.unarchive_confirm_modal.body_suffix"),
      confirm_text: I18n.t("clients.unarchive_confirm_modal.confirm"),
      confirm_variant: "primary"
    )
  end

  def client_archived_banner_message(client)
    I18n.t(
      "clients.archived.banner",
      date: l(client.archived_at, format: :short)
    )
  end

  def onboarding_activate_confirm_modal_data(url:, client_name:)
    app_confirm_modal_open_data(
      url: url,
      item_label: client_name,
      http_method: "post",
      heading: "Marcar como ativo?",
      body_prefix: "Tem certeza? Itens pendentes de ",
      body_suffix: " ficarão como não recebidos no histórico do onboarding. A primeira competência mensal será aberta.",
      confirm_text: "Marcar como ativo",
      confirm_variant: "primary"
    )
  end

  def onboarding_share_rendered(client, url)
    setting = current_user.account.setting || current_user.account.create_setting!
    progress = client.onboarding_checklist ? Onboarding::Progress.call(checklist: client.onboarding_checklist) : nil
    UploadShareMessageRenderer.call(
      setting: setting,
      client: client,
      url: url,
      context: :onboarding,
      progress: progress
    )
  end

  def onboarding_whatsapp_url(client, url)
    text = onboarding_share_rendered(client, url).whatsapp_text
    "https://wa.me/?text=#{ERB::Util.url_encode(text)}"
  end

  def upload_invite_share_rendered(client, url, period_param: nil)
    setting = current_user.account.setting || current_user.account.create_setting!
    period = upload_invite_period_from_param(period_param)
    UploadShareMessageRenderer.call(
      setting: setting,
      client: client,
      url: url,
      period: period
    )
  end

  def upload_invite_whatsapp_url(client, url, period_param: nil)
    text = upload_invite_share_rendered(client, url, period_param: period_param).whatsapp_text
    "https://wa.me/?text=#{ERB::Util.url_encode(text)}"
  end

  def upload_invite_period_from_param(period_param)
    return nil if period_param.blank?

    normalized = period_param.to_s.strip.tr("/", "-")
    Date.strptime(normalized, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end
end
