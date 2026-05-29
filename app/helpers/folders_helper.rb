# frozen_string_literal: true

module FoldersHelper
  def folder_destination_path(folder, period: nil)
    period_param = folder_period_param(folder, period)

    if folder.visible? && folder.client_id.present?
      client_path(folder.client, aba: "pastas", period: period_param, folder_id: folder.id)
    elsif folder.client_id.present?
      folder_documents_path(folder)
    else
      clients_path
    end
  end

  def folder_pastas_hub_path(folder, period: nil)
    return clients_path unless folder.client_id.present?

    client_path(folder.client, aba: "pastas", period: folder_period_param(folder, period))
  end

  private

  def folder_period_param(folder, period)
    explicit = period.respond_to?(:strftime) ? period.strftime("%Y-%m") : period.to_s.presence
    return explicit if explicit.present?
    return folder.name if folder.name.to_s.match?(/\A\d{4}-\d{2}\z/)

    Date.current.strftime("%Y-%m")
  end
end
