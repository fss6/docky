# frozen_string_literal: true

module AuditLog
  class SubjectLabelResolver
    ITEM_TYPE_LABELS = {
      "Folder" => "Pasta",
      "Document" => "Documento",
      "Client" => "Cliente",
      "Period" => "Competência",
      "CompetencyChecklistItem" => "Item do checklist",
      "User" => "Usuário",
      "Account" => "Conta",
      "UploadInvite" => "Convite de upload"
    }.freeze

    def self.call(logs, account_id:)
      new(logs, account_id: account_id).resolve
    end

    def initialize(logs, account_id:)
      @logs = logs
      @account_id = account_id
    end

    def resolve
      grouped = @logs.group_by(&:item_type)
      labels = {}

      resolve_folders(grouped["Folder"], labels)
      resolve_clients(grouped["Client"], labels)
      resolve_documents(grouped["Document"], labels)
      resolve_periods(grouped["Period"], labels)
      resolve_checklist_items(grouped["CompetencyChecklistItem"], labels)
      resolve_upload_invites(grouped["UploadInvite"], labels)
      resolve_users(grouped["User"], labels)
      resolve_accounts(grouped["Account"], labels)

      labels
    end

    private

    def resolve_folders(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      Folder.where(id: ids, account_id: @account_id).pluck(:id, :name).each do |id, name|
        labels[label_key("Folder", id)] = format_label("Folder", name)
      end
    end

    def resolve_clients(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      Client.where(id: ids, account_id: @account_id).pluck(:id, :name).each do |id, name|
        labels[label_key("Client", id)] = format_label("Client", name)
      end
    end

    def resolve_documents(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      Document.where(id: ids, account_id: @account_id).includes(file_attachment: :blob).find_each do |doc|
        name = doc.file.attached? ? doc.file.filename.to_s : "Documento ##{doc.id}"
        labels[label_key("Document", doc.id)] = format_label("Document", name)
      end
    end

    def resolve_periods(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      Period.where(id: ids, account_id: @account_id).find_each do |period|
        period_key = period.period.strftime("%Y-%m")
        label = PeriodFormatting.display_label(period_key)
        labels[label_key("Period", period.id)] = format_label("Period", label)
      rescue ArgumentError
        labels[label_key("Period", period.id)] = format_label("Period", period.period.to_s)
      end
    end

    def resolve_checklist_items(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      CompetencyChecklistItem
        .joins(:competency_checklist)
        .where(id: ids, competency_checklists: { account_id: @account_id })
        .pluck(:id, :name_snapshot)
        .each do |id, name|
          labels[label_key("CompetencyChecklistItem", id)] = format_label("CompetencyChecklistItem", name)
        end
    end

    def resolve_upload_invites(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      UploadInvite.where(id: ids, account_id: @account_id).includes(:client).find_each do |invite|
        name = invite.client&.name || "Convite ##{invite.id}"
        labels[label_key("UploadInvite", invite.id)] = format_label("UploadInvite", name)
      end
    end

    def resolve_users(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      User.where(id: ids, account_id: @account_id).pluck(:id, :name).each do |id, name|
        labels[label_key("User", id)] = format_label("User", name)
      end
    end

    def resolve_accounts(records, labels)
      ids = extract_ids(records)
      return if ids.empty?

      Account.where(id: ids).pluck(:id, :name).each do |id, name|
        labels[label_key("Account", id)] = format_label("Account", name)
      end
    end

    def extract_ids(records)
      Array(records).filter_map(&:item_id).uniq
    end

    def label_key(item_type, item_id)
      "#{item_type}:#{item_id}"
    end

    def format_label(item_type, name)
      type_label = ITEM_TYPE_LABELS.fetch(item_type, item_type)
      display_name = name.presence
      display_name ? "#{type_label} · #{display_name}" : type_label
    end
  end
end
