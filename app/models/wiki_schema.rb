# frozen_string_literal: true

class WikiSchema < ApplicationRecord
  belongs_to :account

  DEFAULT_INSTRUCTIONS = <<~INSTRUCTIONS
    Você é o assistente de base de conhecimento desta empresa.
    Ao processar documentos, sempre:
    1. Identifique as partes envolvidas (pessoas, empresas, departamentos)
    2. Extraia datas críticas e prazos
    3. Destaque cláusulas de penalidade, rescisão e obrigações
    4. Relacione com documentos anteriores quando houver conexão
    5. Sinalize contradições com documentos já processados

    Convenções de nomenclatura de slug:
    - Entidades: entidades/{tipo}-{nome-normalizado}
    - Resumos: documentos/{id}-{titulo-normalizado}
    - Sínteses: temas/{assunto}
  INSTRUCTIONS

  def effective_instructions
    instructions.presence || DEFAULT_INSTRUCTIONS
  end
end
