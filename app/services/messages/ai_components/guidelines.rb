# frozen_string_literal: true

module Messages
  module AiComponents
    module Guidelines
      PROMPT_BLOCK = <<~PROMPT.strip.freeze
        Responda APENAS com JSON válido no formato: { "summary": "...", "components": [ { "type": "...", "data": { ... } } ] }.
        Nunca retorne HTML. Nunca use tabelas com pipes (|); use o componente "table".

        Componentes disponíveis:
        - rich_text: { "content": "Markdown GFM" } — narrativa principal, sem referências a arquivo ou página no texto.
        - table: { "title" opcional, "headers": ["..."], "rows": [["...", "..."]] } — dados tabulares.
        - alert: { "severity": "info|success|warning|error", "title", "description" } — só se o facto estiver no contexto.
        - action_list: { "title" opcional, "actions": ["..."] } — próximos passos sugeridos com base nos documentos.

        Regras:
        - #{Messages::CitationGuidelines::NO_INLINE_CITATIONS}
        - Use somente dados do contexto; não invente métricas ou totais agregados.
        - Pelo menos um rich_text com a resposta principal (ou summary + rich_text).
        - alert apenas para avisos explícitos nos trechos.
      PROMPT

      TABULAR_SUFFIX = <<~PROMPT.strip.freeze
        O usuário pediu formato de tabela. Inclua pelo menos um componente "table" com headers e rows preenchidos.
        rich_text introdutório curto é opcional. Não diga que não pode formatar em tabela.
      PROMPT
    end
  end
end
