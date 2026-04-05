# frozen_string_literal: true

module Rag
  # Filtra os trechos recuperados para exibir como "fontes" só o que a resposta de fato cita ou menciona.
  # Antes: listávamos todos os chunks do top-k; isso gerava chips incoerentes com o texto.
  class AnswerSources
    # Se nada casar com o texto, mostramos só o melhor trecho (1º vizinho).
    FALLBACK_TOP = 1

    def self.source_infos_for_answer(records:, answer_text:)
      return [] if records.blank?

      text = answer_text.to_s
      return fallback_infos(records) if text.blank?

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

      fallback_infos(records)
    end

    def self.fallback_infos(records)
      records.take(FALLBACK_TOP).map(&:source_info).then { |a| dedupe(a) }
    end

    def self.dedupe(infos)
      infos.uniq { |h| [h["file"].to_s, h["page"].to_s, h["chunk_id"].to_s] }
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
      s.to_s.unicode_normalize(:nfc).strip.downcase
    end
  end
end
