# frozen_string_literal: true

module Messages
  # Mensagens assistant com streaming:true abandonadas (ex.: falha de Cable) não devem
  # ficar eternamente na bolha de "thinking" ao recarregar a página.
  class FinalizeStuckStreaming
    STUCK_AFTER = 2.minutes

    def self.call(messages)
      Array(messages).each do |message|
        next unless message.assistant?
        next unless message.streaming?
        next if message.updated_at > STUCK_AFTER.ago

        metadata = message.metadata.is_a?(Hash) ? message.metadata.dup : {}
        metadata.delete("loading")
        metadata.delete("thinking")
        message.update!(streaming: false, metadata: metadata)
      end
    end
  end
end
