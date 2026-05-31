# frozen_string_literal: true

module Messages
  # Instruções para o LLM produzir Markdown GFM válido (renderizado com CommonMarker).
  module MarkdownGuidelines
    PROSE_ONLY_BLOCK = <<~PROMPT.strip.freeze
      Formate a prosa em Markdown GFM válido:
      - Linha em branco entre parágrafos e antes de listas ou cabeçalhos.
      - Negrito: **texto** sem espaços dentro dos asteriscos (ex.: **Período:**).
      - Listas com `- item` em linhas separadas; nunca vários itens na mesma linha.
      - Cabeçalhos com `### Título` em linha própria.

      Exemplo de parágrafo e lista:

      Resumo do período analisado:

      - **Maior:** 714 kWh em novembro de 2025
      - **Menor:** 410 kWh em junho de 2025
    PROMPT

    PROMPT_BLOCK = <<~PROMPT.strip.freeze
      #{PROSE_ONLY_BLOCK}
      - Nunca use tabelas com pipes (`| col |`); use listas ou parágrafos. Tabelas visuais são geradas pelo sistema noutro fluxo.
      - Se o utilizador pedir tabela, responda em prosa organizada sem pipes; não diga que não pode estruturar dados.
    PROMPT
  end
end
