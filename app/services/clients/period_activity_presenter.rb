# frozen_string_literal: true

module Clients
  class PeriodActivityPresenter
    def initialize(audit_event)
      @event = audit_event
      @metadata = audit_event.metadata.is_a?(Hash) ? audit_event.metadata.stringify_keys : {}
    end

    def actor_name
      @event.user&.name || "Sistema"
    end

    def category
      case @event.event_type
      when "document.received" then :document
      when "period.closed", "period.reopened", "monthly_collection.created" then :period
      when /^upload_invite\./ then :invite
      when /^checklist_item\./ then :checklist
      else :other
      end
    end

    def title
      TITLES.fetch(@event.event_type, @event.event_type.humanize)
    end

    def description
      case @event.event_type
      when "document.received"
        filename = @metadata["filename"].presence || "arquivo"
        "#{filename} · #{upload_source_label(@metadata['upload_source'])}"
      when "period.closed", "period.reopened"
        month_label
      when "checklist_item.marked_validated", "checklist_item.reopened", "checklist_item.document_linked",
           "checklist_item.document_unlinked", "checklist_item.created_from_document"
        [checklist_item_name, document_filename].compact.join(" · ").presence || "—"
      when "upload_invite.created", "upload_invite.revoked", "upload_invite.email_sent"
        "Link de upload do cliente"
      when "monthly_collection.created"
        "Competência #{month_label} disponível para trabalho"
      else
        @metadata.except("client_id", "period", "period_id", "ip").presence&.to_json&.truncate(120) || "—"
      end
    end

    TITLES = {
      "document.received" => "Arquivo recebido",
      "period.closed" => "Competência encerrada",
      "period.reopened" => "Competência reaberta",
      "monthly_collection.created" => "Competência criada",
      "checklist_item.marked_validated" => "Item validado",
      "checklist_item.reopened" => "Item reaberto",
      "checklist_item.document_linked" => "Documento vinculado ao checklist",
      "checklist_item.document_unlinked" => "Documento desvinculado",
      "checklist_item.created_from_document" => "Item criado a partir de documento",
      "upload_invite.created" => "Link de upload gerado",
      "upload_invite.revoked" => "Link de upload revogado",
      "upload_invite.email_sent" => "Convite enviado por e-mail"
    }.freeze

    private

    def month_label
      period_raw = @metadata["period"]
      return period_raw if period_raw.blank?

      PeriodFormatting.display_label(period_raw)
    rescue ArgumentError
      period_raw
    end

    def checklist_item_name
      @metadata["item_name"].presence || load_checklist_item&.name_snapshot
    end

    def document_filename
      doc_id = @metadata["document_id"]
      return nil if doc_id.blank?

      doc = Document.find_by(id: doc_id)
      return nil unless doc&.file&.attached?

      doc.file.filename.to_s
    end

    def load_checklist_item
      return @checklist_item if defined?(@checklist_item)

      @checklist_item = @event.subject if @event.subject_type == "CompetencyChecklistItem"
    end

    def upload_source_label(source)
      case source
      when "public_link" then "via portal"
      when "internal_upload" then "upload manual"
      when "email_forward" then "e-mail forward"
      else "upload na conta"
      end
    end
  end
end
