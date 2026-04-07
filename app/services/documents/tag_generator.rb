# frozen_string_literal: true

module Documents
  # Gera etiquetas a partir do nome do ficheiro, resumo e trechos (chunks OCR / conteúdo).
  class TagGenerator
    SYSTEM_PROMPT = <<~TEXT.squish.freeze
      Você extrai etiquetas (tags) para documentos.
      Responda APENAS com um objeto JSON com a chave "tags": array de strings (entre 1 e 5 itens).
      Cada tag deve ser curta (1 a 4 palavras), em português do Brasil, descrevendo tema, tipo de documento ou entidades relevantes.
      Sem hashtags, sem duplicatas, sem texto fora do JSON.
    TEXT

    MAX_SAMPLE_CHARS = 10_000
    MAX_TAGS = 12

    def self.call(document)
      sample = build_sample(document)
      return nil if sample.blank?

      raw = Openai::Completion.call(
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_payload(document, sample) }
        ],
        max_tokens: 500,
        temperature: 0.35,
        response_format: { type: "json_object" }
      )
      tags = normalize_tags(parse_tags_json(raw))
      tags.presence || []
    rescue JSON::ParserError
      []
    end

    def self.build_sample(document)
      parts = []
      parts << document.content.to_s.strip if document.content.present?
      document.embedding_records.ordered_for_display.limit(40).each do |rec|
        c = rec.content.to_s.strip
        parts << c if c.present?
      end
      text = parts.join("\n\n").squish
      text.truncate(MAX_SAMPLE_CHARS)
    end

    def self.user_payload(document, sample)
      lines = []
      lines << "Nome do arquivo: #{document.file.filename}" if document.file.attached?
      lines << "Pasta: #{document.folder&.name}" if document.folder&.name.present?
      lines << "Resumo:\n#{document.summary}" if document.summary.present?
      lines << "Trechos do documento:\n#{sample}"
      lines.join("\n\n")
    end

    def self.parse_tags_json(raw)
      s = raw.to_s.strip
      s = s.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
      obj = JSON.parse(s)
      Array(obj["tags"])
    end

    def self.normalize_tags(arr)
      arr.filter_map do |t|
        s = t.to_s.strip.squeeze(" ")
        next if s.blank?

        s.truncate(80, omission: "")
      end.uniq.first(MAX_TAGS)
    end
  end
end
