# frozen_string_literal: true

module PublicUploads
  class BlockedMessage
    def self.for(kind:, period: nil)
      new(kind: kind, period: period).call
    end

    def initialize(kind:, period: nil)
      @kind = kind
      @period = period
    end

    def call
      case @kind
      when :period_missing
        "Sua contabilidade não tem períodos abertos no momento. Entre em contato se precisar enviar algo."
      when :period_closed
        label = PeriodFormatting.display_label(@period)
        "Este período (#{label}) não está recebendo documentos no momento. Entre em contato com sua contabilidade se precisar enviar algo."
      else
        raise ArgumentError, "Unknown blocked message kind: #{@kind}"
      end
    end
  end
end
