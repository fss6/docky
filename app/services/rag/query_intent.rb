# frozen_string_literal: true

module Rag
  # Classifica a mensagem do usuário antes do RAG (saudação já tratada em GreetingMessage).
  module QueryIntent
    module Responses
      module_function

      def meta_identity
        <<~TXT.strip
          Sou o assistente Docfy desta conta. Não sou uma pessoa: sou o assistente configurado para ajudar você a consultar os documentos indexados aqui.

          Posso responder perguntas com base nesses arquivos, resumir trechos, localizar cláusulas, valores ou prazos, e citar a fonte (arquivo e página) quando uso o conteúdo dos documentos.

          O que você gostaria de saber sobre os seus documentos?
        TXT
      end

      def meta_capabilities
        <<~TXT.strip
          Sou o assistente Docfy. Posso ajudar com:

          - Consultas sobre o conteúdo dos documentos desta conta (só uso o que foi enviado e indexado)
          - Resumos e sínteses de trechos ou temas presentes nos arquivos
          - Localização de informações (cláusulas, prazos, valores, definições) dentro dos textos
          - Citações: quando a resposta vem de um documento, indico arquivo e página

          Faça uma pergunta objetiva sobre o que está nos seus documentos — por exemplo sobre um contrato, cláusula ou dado que você sabe que enviou.
        TXT
      end

      def out_of_scope
        <<~TXT.strip
          Sou o assistente desta conta e trabalho apenas com os documentos que você enviou e que foram indexados aqui. Para assuntos gerais, opiniões ou temas que não estão nesses arquivos, não consigo dar respostas confiáveis.

          Pergunte algo que possa estar nos documentos da conta (por exemplo um prazo, valor, obrigação ou trecho que você queira encontrar).
        TXT
      end

      def no_relevant_chunks(focus_document: false)
        hint = focus_document ? "neste documento" : "nos documentos desta conta"
        <<~TXT.strip
          Não encontrei trechos que respondam bem a isso #{hint}.

          Tente ser mais específico (termo, cláusula, data ou nome de arquivo), ou confira se o arquivo certo foi enviado e processado. Se a pergunta for sobre o assistente em si (nome, o que posso fazer), pode perguntar diretamente.
        TXT
      end
    end

    # :greeting tratado em Rag::GreetingMessage antes de chamar #kind para título/RAG.
    def self.kind(text)
      return :greeting if GreetingMessage.only?(text)
      return :meta_identity if meta_identity?(text)
      return :meta_capabilities if meta_capabilities?(text)
      return :out_of_scope if out_of_scope?(text)

      :document
    end

    def self.skip_title_generation?(text)
      kind(text) != :document
    end

    def self.meta_identity?(text)
      t = text.to_s.strip
      return false if t.blank? || t.length > 220

      META_IDENTITY_PATTERNS.any? { |re| t.match?(re) }
    end

    def self.meta_capabilities?(text)
      t = text.to_s.strip
      return false if t.blank? || t.length > 220

      META_CAPABILITIES_PATTERNS.any? { |re| t.match?(re) }
    end

    def self.out_of_scope?(text)
      t = text.to_s.strip
      return false if t.blank? || t.length > 600

      OUT_OF_SCOPE_PATTERNS.any? { |re| t.match?(re) }
    end

    META_IDENTITY_PATTERNS = [
      /\bqual\s+(é|e|eh)\s+(o\s+)?(seu|teu)\s+nome\b/i,
      /\bcomo\s+(você|vc|tu)\s+se\s+chama\b/i,
      /\bquem\s+(é|e)\s+(você|vc|tu)\b/i,
      /\bwhat\s+is\s+your\s+name\b/i,
      /\bwho\s+are\s+you\b/i,
      /\bwhat\s+are\s+you\b/i
    ].freeze

    META_CAPABILITIES_PATTERNS = [
      /\A\s*no\s+que\s+você\s+(pode|consegue)\s+ajudar\b/i,
      /\A\s*(em\s+)?que\s+você\s+pode\s+ajudar\b/i,
      /\A\s*o\s+que\s+você\s+(faz|pode\s+fazer|sabe\s+fazer|é\s+capaz)\b/i,
      /\A\s*como\s+(você|vc)\s+pode\s+ajudar\b/i,
      /\bcomo\s+funciona\s+(o\s+docfy|este\s+assistente|aqui)\b/i,
      /\A\s*(principais\s+)?func(ões|oes|ionalidades)\b/i,
      /\A\s*what\s+can\s+you\s+do\b/i,
      /\A\s*how\s+does\s+(it|this)\s+work\b/i,
      /\A\s*help\s*[!?.]*\s*\z/i
    ].freeze

    OUT_OF_SCOPE_PATTERNS = [
      /\bignore\s+(instruç(ões|oes)|as\s+regras|tudo|os\s+documentos)\b/i,
      /\bmodo\s+(jailbreak|developer|DAN)\b/i,
      /\bescreva\s+um\s+(poema|conto|redação|ensaio)\s+(sobre|de)\b/i,
      /\bsem\s+usar\s+(os\s+)?documentos\b/i
    ].freeze
  end
end
