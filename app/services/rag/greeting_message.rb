# frozen_string_literal: true

require "set"

module Rag
  # Mensagens curtas só de saudação/despedida/cortesia — sem pergunta sobre documentos.
  module GreetingMessage
    PHRASES = Set.new(%w[
      olá ola oi oie
      hello hi hey
      bom dia boa tarde boa noite
      obrigado obrigada valeu
      thanks ty
      thank you thankyou
      tchau adeus bye
    ].freeze)

    def self.only?(text)
      normalized = normalize(text)
      return false if normalized.blank?
      return false if normalized.length > 80

      PHRASES.include?(normalized)
    end

    def self.normalize(text)
      s = text.to_s.unicode_normalize(:nfc).downcase.strip
      s = s.gsub(/[!.?…,:;]+$/u, "").strip
      s.gsub(/\s+/, " ")
    end
  end
end
