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
