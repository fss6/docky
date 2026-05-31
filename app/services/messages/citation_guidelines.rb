# frozen_string_literal: true

module Messages
  module CitationGuidelines
    NO_INLINE_CITATIONS = <<~PROMPT.strip.freeze
      Não inclua no texto da resposta: nome de arquivo, número de página, blocos "(Fonte: ...)", "[Fonte]" nem frases do tipo "Segundo o documento X". O sistema mostra as fontes utilizadas num painel à parte.
    PROMPT
  end
end
