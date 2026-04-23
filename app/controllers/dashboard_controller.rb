class DashboardController < ApplicationController
  before_action :authorize_policy

  def index
    account = current_user.account
    documents = account_documents_for_context(account)
    bank_statements = account_bank_statements_for_context(account)
    checklist_items = account_checklist_items_for_context(account)
    ordered_documents = documents.order("documents.created_at DESC")
    @documents_last_30_days = documents_last_30_days_series(documents)

    @total_documents = documents.count
    @total_folders = account.folders.count
    @total_users = account.users.count

    @recent_documents = ordered_documents.includes(:user, :folder).limit(8)
    @documents_by_type = documents
      .joins(file_attachment: :blob)
      .group("COALESCE(active_storage_blobs.content_type, 'desconhecido')")
      .order(Arel.sql("COUNT(*) DESC"))
      .count

    @total_tags, @recent_tags = tags_metrics(documents: documents, recent_documents: ordered_documents.includes(:folder).limit(100))
    @alerts = [
      {
        key: :duplicates,
        label: "Duplicatas",
        description: "Lançamentos marcados como possível duplicata.",
        total: bank_statements.where(possible_duplicate: true).count,
        path: bank_statements_path
      },
      {
        key: :pending,
        label: "Pendências",
        description: "Documentos pendentes de processamento.",
        total: documents.where(status: :pending).count,
        path: "/folders"
      },
      {
        key: :checklist_pending,
        label: "Checklist pendente",
        description: "Itens de checklist ainda pendentes.",
        total: checklist_items.pending.count,
        path: timeline_path
      }
    ]

    @show_wiki_insights = WikiPagePolicy.new(current_user, :wiki_page).index?
    return unless @show_wiki_insights

    @total_wiki_pages = account.wiki_pages.count
    @wiki_pages_by_type = wiki_pages_by_type_series(account.wiki_pages)
    @wiki_pages_last_30_days = wiki_pages_last_30_days_series(account.wiki_pages)
  end

  private

  def account_documents_for_context(account)
    rel = account.documents
    return rel unless current_client

    rel.joins(:folder).where(folders: { client_id: current_client.id })
  end

  def account_bank_statements_for_context(account)
    rel = account.bank_statements
    return rel unless current_client

    rel.where(client_id: current_client.id)
  end

  def account_checklist_items_for_context(account)
    rel = account.competency_checklist_items
    return rel unless current_client

    rel.joins(:competency_checklist).where(competency_checklists: { client_id: current_client.id })
  end

  def authorize_policy
    authorize :dashboard, :index?
  end

  def tags_metrics(documents:, recent_documents:)
    all_tags = documents.pluck(:tags).flatten.compact.map(&:to_s).map(&:strip).reject(&:blank?)
    total_tags = all_tags.uniq.count

    recent_tags = recent_documents.flat_map do |document|
      document.tags.map do |tag|
        normalized_tag = tag.to_s.strip
        next if normalized_tag.blank?

        {
          name: normalized_tag,
          created_at: document.created_at,
          document: document
        }
      end
    end.compact.uniq { |entry| entry[:name].downcase }.first(10)

    [total_tags, recent_tags]
  end

  def documents_last_30_days_series(documents)
    range = 29.days.ago.to_date..Date.current
    grouped = documents
      .where(documents: { created_at: range.begin.beginning_of_day..range.end.end_of_day })
      .group(Arel.sql("DATE(documents.created_at)"))
      .count

    range.map do |date|
      {
        date: date.strftime("%d/%m"),
        total: grouped[date] || 0
      }
    end
  end

  def wiki_pages_by_type_series(wiki_pages)
    counts = wiki_pages.group(:page_type).count
    ordered_types = %w[index summary entity synthesis]

    ordered_types.map do |page_type|
      {
        key: page_type,
        label: wiki_page_type_label(page_type),
        total: counts[page_type] || 0
      }
    end
  end

  def wiki_pages_last_30_days_series(wiki_pages)
    range = 29.days.ago.to_date..Date.current
    grouped = wiki_pages
      .where(wiki_pages: { created_at: range.begin.beginning_of_day..range.end.end_of_day })
      .group(Arel.sql("DATE(wiki_pages.created_at)"))
      .count

    range.map do |date|
      {
        date: date.strftime("%d/%m"),
        total: grouped[date] || 0
      }
    end
  end

  def wiki_page_type_label(page_type)
    {
      "index" => "Indice",
      "summary" => "Resumos",
      "entity" => "Entidades",
      "synthesis" => "Sinteses"
    }[page_type] || page_type.to_s.humanize
  end
end
