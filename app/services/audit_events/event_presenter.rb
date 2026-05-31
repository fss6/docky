# frozen_string_literal: true

module AuditEvents
  class EventPresenter
    TITLES = {
      "document.received" => "Arquivo recebido",
      "document.moved" => "Arquivo movido",
      "document.tag_added" => "Tag adicionada",
      "document.tag_replaced" => "Tag alterada",
      "document.tag_removed" => "Tag removida",
      "period.closed" => "Competência encerrada",
      "period.reopened" => "Competência reaberta",
      "period.created_retroactive" => "Competência retroativa criada",
      "monthly_collection.created" => "Competência criada",
      "checklist_item.marked_validated" => "Item validado",
      "checklist_item.reopened" => "Item reaberto",
      "checklist_item.document_linked" => "Documento vinculado ao checklist",
      "checklist_item.document_unlinked" => "Documento desvinculado",
      "checklist_item.created_from_document" => "Item criado a partir de documento",
      "upload_invite.created" => "Link de upload gerado",
      "upload_invite.revoked" => "Link de upload revogado",
      "upload_invite.email_sent" => "Convite enviado por e-mail",
      "upload_invite.email_failed" => "Falha ao enviar convite por e-mail",
      "client.created" => "Cliente criado",
      "client.archived" => "Cliente arquivado",
      "client.unarchived" => "Cliente desarquivado",
      "client.onboarding_started" => "Onboarding iniciado",
      "client.onboarding_reopened" => "Onboarding reaberto",
      "client.activated_from_onboarding" => "Cliente ativado",
      "client.onboarding_email_sent" => "E-mail de ativação enviado",
      "client.onboarding_email_failed" => "Falha ao enviar e-mail de ativação",
      "onboarding_item.marked_manual" => "Item de onboarding marcado",
      "permission_grant.updated" => "Permissões atualizadas"
    }.freeze

    METADATA_SKIP_KEYS = %w[client_id period period_id ip].freeze

    def initialize(audit_event)
      @event = audit_event
      @metadata = audit_event.metadata.is_a?(Hash) ? audit_event.metadata.stringify_keys : {}
    end

    def actor_name
      @event.user&.name || "Sistema"
    end

    def title
      TITLES.fetch(@event.event_type, @event.event_type.tr(".", " ").humanize)
    end

    def description
      case @event.event_type
      when "document.received"
        filename = @metadata["filename"].presence || "arquivo"
        "#{filename} · #{upload_source_label(@metadata['upload_source'])}"
      when "document.moved"
        document_moved_description
      when "document.tag_added"
        tag_label(@metadata["tag"])
      when "document.tag_replaced"
        "#{tag_label(@metadata['old_tag'])} → #{tag_label(@metadata['new_tag'])}"
      when "document.tag_removed"
        tag_label(@metadata["tag"])
      when "period.closed", "period.reopened", "period.created_retroactive"
        month_label
      when "checklist_item.marked_validated", "checklist_item.reopened", "checklist_item.document_linked",
           "checklist_item.document_unlinked", "checklist_item.created_from_document"
        [checklist_item_name, document_filename].compact.join(" · ").presence || "—"
      when "upload_invite.created", "upload_invite.revoked", "upload_invite.email_sent"
        upload_invite_description
      when "upload_invite.email_failed"
        upload_invite_email_failed_description
      when "monthly_collection.created"
        "Competência #{month_label} disponível para trabalho"
      when "client.created"
        client_created_description
      when "client.activated_from_onboarding"
        @metadata["automatic"] == true ? "Ativação automática" : "Ativação manual"
      when "client.onboarding_started"
        onboarding_kind_label(@metadata["onboarding_kind"])
      when "client.archived", "client.unarchived", "client.onboarding_reopened"
        client_name_from_subject
      when "client.onboarding_email_sent", "client.onboarding_email_failed"
        client_onboarding_email_description
      when "onboarding_item.marked_manual"
        @metadata["item_name"].presence || "—"
      when "permission_grant.updated"
        permission_grant_description
      else
        filtered_metadata_description
      end
    end

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

    def document_moved_description
      from_name = folder_name(@metadata["from_folder_id"])
      to_name = folder_name(@metadata["to_folder_id"])
      return "—" if from_name.blank? && to_name.blank?

      "#{from_name.presence || '—'} → #{to_name.presence || '—'}"
    end

    def folder_name(folder_id)
      return nil if folder_id.blank?

      Folder.find_by(id: folder_id)&.name
    end

    def tag_label(tag)
      tag.present? ? tag.to_s : "—"
    end

    def upload_invite_description
      parts = ["Link de upload do cliente"]
      parts << month_label if @metadata["period"].present?
      parts << "onboarding" if @metadata["purpose"] == "onboarding"
      parts.join(" · ")
    end

    def upload_invite_email_failed_description
      parts = []
      parts << @metadata["recipient"] if @metadata["recipient"].present?
      if @metadata["error_message"].present?
        parts << @metadata["error_message"].to_s.truncate(80)
      end
      parts.presence&.join(" · ") || "Link de upload do cliente"
    end

    def client_created_description
      parts = []
      parts << "Status: #{@metadata['status']}" if @metadata["status"].present?
      if @metadata["onboarding_skipped"] == true
        parts << "Onboarding pulado"
      elsif @metadata["onboarding_template_name"].present?
        parts << "Template: #{@metadata['onboarding_template_name']}"
      elsif @metadata["onboarding_kind"].present?
        parts << onboarding_kind_label(@metadata["onboarding_kind"])
      end
      parts.presence&.join(" · ") || client_name_from_subject
    end

    def client_onboarding_email_description
      parts = []
      parts << @metadata["recipient"] if @metadata["recipient"].present?
      if @metadata["error_message"].present?
        parts << @metadata["error_message"].to_s.truncate(80)
      end
      parts.presence&.join(" · ") || client_name_from_subject
    end

    def client_name_from_subject
      return "—" unless @event.subject_type == "Client"

      @event.subject&.name.presence || "—"
    end

    def permission_grant_description
      parts = []
      parts << @metadata["capability_key"] if @metadata["capability_key"].present?
      parts << (@metadata["granted"] ? "concedida" : "revogada") if @metadata.key?("granted")
      parts << "papel: #{@metadata['role']}" if @metadata["role"].present?
      parts.presence&.join(" · ") || "—"
    end

    def onboarding_kind_label(kind)
      return "—" if kind.blank?

      case kind.to_s
      when "full" then "Onboarding completo"
      when "light" then "Onboarding simplificado"
      else kind.to_s.humanize
      end
    end

    def filtered_metadata_description
      remaining = @metadata.except(*METADATA_SKIP_KEYS)
      return "—" if remaining.blank?

      remaining.map { |key, value| "#{key}: #{value}" }.join(" · ").truncate(120)
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
