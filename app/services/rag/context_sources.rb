# frozen_string_literal: true

module Rag
  # Agrupa trechos RAG para o painel de contexto (metadata da mensagem).
  class ContextSources
    EXCERPT_LENGTH = 280

    def self.build_from_records(records)
      return [] if records.blank?

      list = Array(records)
      tags_by_document_id = load_tags_by_document_id(list)

      groups = {}
      list.each do |record|
        if record.wiki_page?
          key = "wiki:#{record.source_info['wiki_slug']}"
          groups[key] ||= wiki_group(record)
          append_chunk(groups[key], record)
        else
          doc_id = record.document_id
          key = "doc:#{doc_id || record.id}"
          groups[key] ||= document_group(record, tags_by_document_id[doc_id])
          append_chunk(groups[key], record)
        end
      end

      groups.values.map { |g| finalize_group(g) }
    end

    def self.load_tags_by_document_id(records)
      doc_ids = records.reject(&:wiki_page?).filter_map(&:document_id).uniq
      return {} if doc_ids.empty?

      Document.where(id: doc_ids).pluck(:id, :tags).to_h { |id, tags| [id, Array(tags)] }
    end

    def self.wiki_group(record)
      info = record.source_info
      {
        "kind" => "wiki",
        "wiki_slug" => info["wiki_slug"],
        "wiki_title" => info["wiki_title"],
        "document_name" => info["wiki_title"].presence || info["wiki_slug"].to_s,
        "pages" => [],
        "tags" => [],
        "chunks" => []
      }
    end

    def self.document_group(record, tags)
      info = record.source_info
      {
        "kind" => "document",
        "document_id" => record.document_id,
        "document_name" => info["file"].to_s.presence || "Documento",
        "pages" => [],
        "tags" => Array(tags).map(&:to_s).reject(&:blank?),
        "chunks" => []
      }
    end

    def self.append_chunk(group, record)
      page = record.page_number
      group["pages"] << page if page.present?
      group["chunks"] << {
        "chunk_id" => record.id,
        "page" => page,
        "excerpt" => record.content.to_s.truncate(EXCERPT_LENGTH)
      }
    end

    def self.finalize_group(group)
      group["pages"] = group["pages"].compact.uniq.sort
      group["chunks"] = group["chunks"].uniq { |c| c["chunk_id"] }
      group
    end

    private_class_method :load_tags_by_document_id, :wiki_group, :document_group,
                         :append_chunk, :finalize_group
  end
end
