# frozen_string_literal: true

module ClientsHelper
  VALID_TABS = %w[documentos checklist convites email historico].freeze

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

  def summary_status_badge_classes(tone)
    case tone.to_sym
    when :success
      "bg-emerald-50 text-emerald-800 ring-1 ring-inset ring-emerald-600/20"
    when :warning
      "bg-amber-50 text-amber-900 ring-1 ring-inset ring-amber-600/20"
    else
      "bg-zinc-100 text-zinc-700"
    end
  end
end
