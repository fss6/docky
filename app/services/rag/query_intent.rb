# frozen_string_literal: true

module Rag
  # Classifica a mensagem do usuário antes do RAG (saudação já tratada em GreetingMessage).
  module QueryIntent
    module Responses
      module_function

      def meta_identity
        <<~TXT.strip
          Sou o assistente Dokivo desta conta. Não sou uma pessoa: sou o assistente configurado para ajudar você a consultar os documentos indexados aqui.

          Posso responder perguntas com base nesses arquivos, resumir trechos, localizar cláusulas, valores ou prazos. As fontes utilizadas aparecem no painel de contexto ao lado da conversa.

          O que você gostaria de saber sobre os seus documentos?
        TXT
      end

      def meta_capabilities
        <<~TXT.strip
          Sou o assistente Dokivo. Posso ajudar com:

          - Consultas sobre o conteúdo dos documentos desta conta (só uso o que foi enviado e indexado)
          - Resumos e sínteses de trechos ou temas presentes nos arquivos
          - Localização de informações (cláusulas, prazos, valores, definições) dentro dos textos
          - Rastreabilidade: as fontes e trechos dos documentos aparecem no painel de contexto

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
    def self.kind(text, conversation: nil, user_message: nil)
      return :greeting if GreetingMessage.only?(text)
      return :meta_identity if meta_identity?(text)
      return :meta_capabilities if meta_capabilities?(text)
      return :out_of_scope if out_of_scope?(text)
      return :tabular if tabular_request?(text, conversation: conversation, user_message: user_message)

      :document
    end

    TABULAR_ERROR_SNIPPET = "Não foi possível gerar a tabela"

    def self.tabular_request?(text, conversation: nil, user_message: nil)
      t = text.to_s.strip
      return false if t.blank? || t.length > 800
      return true if direct_tabular_request?(t)

      conversation.present? && user_message.present? &&
        tabular_follow_up?(t) &&
        tabular_context_in_conversation?(conversation, before_message_id: user_message.id)
    end

    def self.direct_tabular_request?(text)
      t = text.to_s.strip
      return false if t.blank?

      TABULAR_REQUEST_PATTERNS.any? { |re| t.match?(re) }
    end

    # Pergunta efectiva para o LLM quando o utilizador só diz "gere" após pedido de tabela.
    def self.tabular_effective_question(user_message, conversation)
      current = user_message.content.to_s.strip
      return current if direct_tabular_request?(current)

      prior = conversation.messages
        .where(role: "user")
        .where("id < ?", user_message.id)
        .order(id: :desc)
        .find { |m| direct_tabular_request?(m.content) }

      return current if prior.blank?

      "#{prior.content}\n\n(Continuação: #{current})"
    end

    def self.tabular_follow_up?(text)
      t = text.to_s.strip
      return false if t.blank? || t.length > 120

      TABULAR_FOLLOW_UP_PATTERNS.any? { |re| t.match?(re) }
    end

    def self.tabular_context_in_conversation?(conversation, before_message_id:)
      conversation.messages
        .where("id < ?", before_message_id)
        .order(id: :desc)
        .limit(8)
        .any? { |m| tabular_context_message?(m) }
    end

    def self.tabular_context_message?(message)
      if message.user?
        direct_tabular_request?(message.content)
      else
        assistant_tabular_context?(message)
      end
    end

    def self.assistant_tabular_context?(message)
      return true if message.structured_tables.any?

      meta = message.metadata
      return true if meta.is_a?(Hash) && Array(meta["tables"]).any?

      message.content.to_s.include?(TABULAR_ERROR_SNIPPET)
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
      /\bcomo\s+funciona\s+(o\s+dokivo|este\s+assistente|aqui)\b/i,
      /\A\s*(principais\s+)?func(ões|oes|ionalidades)\b/i,
      /\A\s*what\s+can\s+you\s+do\b/i,
      /\A\s*how\s+does\s+(it|this)\s+work\b/i,
      /\A\s*help\s*[!?.]*\s*\z/i
    ].freeze

    TABULAR_REQUEST_PATTERNS = [
      /\btabela\b/i,
      /\bem\s+formato\s+de\s+tabela\b/i,
      /\borganiz(e|ar)\s+em\s+colunas\b/i,
      /\bgere.*\btabela\b/i,
      /\bmostre.*\btabela\b/i,
      /\bapresente.*\btabela\b/i,
      /\bformato\s+tabular\b/i,
      /\bem\s+colunas\s+e\s+linhas\b/i,
      /\bpreciso\s+ver.*\btabela\b/i,
      /\bdados\s+em\s+tabela\b/i,
      /\bver.*\bem\s+tabela\b/i,
      /\bem\s+colunas\b/i,
      /\bgerar?\s+.*\btabela\b/i
    ].freeze

    TABULAR_FOLLOW_UP_PATTERNS = [
      /\A\s*gere?\s*[!?.]*\s*\z/i,
      /\A\s*gera(r)?\s*(de\s+)?novo\s*[!?.]*\s*\z/i,
      /\A\s*tenta(r)?\s+(de\s+)?novo\s*[!?.]*\s*\z/i,
      /\A\s*sim\s*[!?.]*\s*\z/i,
      /\A\s*ok\s*[!?.]*\s*\z/i,
      /\A\s*pode\s+gerar\s*[!?.]*\s*\z/i,
      /\A\s*gera(r)?\s*[!?.]*\s*\z/i
    ].freeze

    OUT_OF_SCOPE_PATTERNS = [
      /\bignore\s+(instruç(ões|oes)|as\s+regras|tudo|os\s+documentos)\b/i,
      /\bmodo\s+(jailbreak|developer|DAN)\b/i,
      /\bescreva\s+um\s+(poema|conto|redação|ensaio)\s+(sobre|de)\b/i,
      /\bsem\s+usar\s+(os\s+)?documentos\b/i
    ].freeze
  end
end
