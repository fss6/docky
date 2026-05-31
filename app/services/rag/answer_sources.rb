# frozen_string_literal: true

module Rag
  # Filtra os trechos recuperados para exibir como "fontes" só o que a resposta cita,
  # menciona ou o que a pergunta do usuário indica (ex.: entidade no nome do arquivo).
  class AnswerSources
    FALLBACK_TOP = 1
    MIN_QUESTION_TOKEN_LENGTH = 4

    PT_STOPWORDS = %w[
      temos alguma algum algumas alguns como qual quais quem onde quando porque
      para com sem sobre este esta esse essa isso aquilo voce pode mais muito
      tambem ainda ja ser estar ter foi sao era foram
    ].freeze

    def self.source_infos_for_answer(records:, answer_text:, question_text: nil)
      return [] if records.blank?

      text = answer_text.to_s
      if text.present?
        cited = extract_fonte_titles(text)
        if cited.present?
          matched = records.select { |r| matches_citation?(r, cited, text) }
          infos = matched.map(&:source_info)
          return dedupe(infos) if infos.any?
        end

        matched = records.select { |r| full_filename_in_answer?(r.source_info["file"], text) }
        return dedupe(matched.map(&:source_info)) if matched.any?

        matched = records.select { |r| basename_in_answer?(r.source_info["file"], text) }
        return dedupe(matched.map(&:source_info)) if matched.any?
      end

      question_matched = records_matching_question(records, question_text)
      return dedupe(question_matched.map(&:source_info)) if question_matched.any?

      fallback_infos(records)
    end

    def self.source_infos_from_records(records)
      return [] if records.blank?

      dedupe(Array(records).map(&:source_info))
    end

    def self.fallback_infos(records)
      records.take(FALLBACK_TOP).map(&:source_info).then { |a| dedupe(a) }
    end

    def self.records_matching_question(records, question_text)
      tokens = question_tokens(question_text)
      return [] if tokens.empty?

      tags_by_document_id = load_tags_by_document_id(records)

      records.select do |record|
        matches_question_tokens?(record, tokens, tags_by_document_id)
      end
    end

    def self.question_tokens(question_text)
      normalized = normalize_text(question_text)
      return [] if normalized.blank?

      normalized.split(/\s+/).filter_map do |word|
        token = word.gsub(/[^[:alnum:]]/, "")
        next if token.length < MIN_QUESTION_TOKEN_LENGTH
        next if PT_STOPWORDS.include?(token)

        token
      end.uniq
    end

    def self.matches_question_tokens?(record, tokens, tags_by_document_id)
      info = record.source_info
      if info["wiki_slug"].present?
        haystack = [
          info["wiki_slug"],
          info["wiki_title"],
          info["page_type"]
        ].compact.map { |s| normalize_text(s) }.join(" ")
        return tokens.any? { |t| haystack.include?(t) }
      end

      fname = info["file"].to_s
      base = File.basename(fname, File.extname(fname))
      doc_tags = tags_by_document_id[info["document_id"] || record.try(:document_id)]
      haystack = normalize_text([fname, base, *Array(doc_tags)].join(" "))
      tokens.any? { |t| haystack.include?(t) }
    end

    def self.load_tags_by_document_id(records)
      doc_ids = records.reject { |r| r.source_info["wiki_slug"].present? }
        .filter_map { |r| r.source_info["document_id"] || r.try(:document_id) }
        .uniq
      return {} if doc_ids.empty?

      Document.where(id: doc_ids).pluck(:id, :tags).to_h { |id, tags| [id, Array(tags)] }
    end

    def self.dedupe(infos)
      infos.uniq { |h| dedupe_key(h) }
    end

    def self.dedupe_key(info)
      if info["wiki_slug"].present?
        [ "wiki", info["wiki_slug"].to_s, info["page_type"].to_s ]
      else
        [ info["file"].to_s, info["page"].to_s, info["chunk_id"].to_s ]
      end
    end

    def self.extract_fonte_titles(text)
      titles = []
      text.scan(/(?:\(|\A|\n)\s*Fonte:\s*([^·\n)]+)/mi) { titles << Regexp.last_match(1).strip }
      text.scan(/\bFonte:\s*([^·\n)]+)/mi) { titles << Regexp.last_match(1).strip }
      titles.map { |t| t.sub(/\s*·\s*pp?\.\s*[\d,\s]+\s*\z/i, "").strip }.reject(&:blank?).uniq
    end

    def self.matches_citation?(record, cited_titles, full_text)
      info = record.source_info
      fname = info["file"].to_s
      cited_titles.any? { |c| citation_matches_file?(c, fname) } || full_filename_in_answer?(fname, full_text)
    end

    def self.citation_matches_file?(cited, filename)
      c, f = cited.strip, filename.strip
      return true if f.include?(c) || c.include?(f)
      return true if normalize_filename(c) == normalize_filename(f)

      base_c = File.basename(c, File.extname(c))
      base_f = File.basename(f, File.extname(f))
      base_f.length >= 12 && (base_f.include?(base_c) || base_c.include?(base_f))
    end

    def self.full_filename_in_answer?(filename, text)
      fn = filename.to_s
      return false if fn.blank?

      text.include?(fn)
    end

    def self.basename_in_answer?(filename, text)
      fn = filename.to_s
      base = File.basename(fn, File.extname(fn))
      return false if base.length < 14

      text.include?(base)
    end

    def self.normalize_filename(s)
      normalize_text(s)
    end

    def self.normalize_text(s)
      s.to_s.unicode_normalize(:nfc).strip.downcase
    end
  end
end
