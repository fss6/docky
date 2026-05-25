# frozen_string_literal: true

class ClientAuditTrail
  def initialize(client:)
    @client = client
  end

  def limit(n)
    events = AuditEvent.where(account_id: @client.account_id)
      .where("metadata ->> 'client_id' = ?", @client.id.to_s)
      .includes(:user)
      .order(created_at: :desc)
      .limit(n)

    folder_ids = @client.folders.pluck(:id)
    audits = Audit.where(account_id: @client.account_id, auditable_type: "Folder", auditable_id: folder_ids)
      .includes(:user)
      .order(created_at: :desc)
      .limit(n)

    (events.map { |e| row_from_event(e) } + audits.map { |a| row_from_audit(a) })
      .sort_by { |r| r[:at] }
      .reverse
      .first(n)
  end

  private

  def row_from_event(event)
    {
      at: event.created_at,
      actor: event.user&.name || "Sistema",
      verb: event.event_type,
      detail: event.metadata.to_json.truncate(120)
    }
  end

  def row_from_audit(audit)
    {
      at: audit.created_at,
      actor: audit.user&.name || "Sistema",
      verb: "#{audit.auditable_type} #{audit.action}",
      detail: audit.comment.presence || audit.audited_changes.to_s.truncate(120)
    }
  end
end
