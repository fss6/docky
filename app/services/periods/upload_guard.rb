# frozen_string_literal: true

module Periods
  class UploadGuard
    Result = Struct.new(:allowed, :reason, keyword_init: true)

    def self.call(period:)
      new(period: period).call
    end

    def initialize(period:)
      @period = period
    end

    def call
      if @period.blank?
        return Result.new(allowed: true, reason: nil)
      end

      client = @period.client
      if client&.onboarding?
        return Result.new(
          allowed: false,
          reason: "Esta conta ainda está em configuração. Conclua o onboarding antes de enviar documentos mensais."
        )
      end

      if @period.closed?
        return Result.new(
          allowed: false,
          reason: "Esta competência está encerrada e não aceita novos envios."
        )
      end

      Result.new(allowed: true, reason: nil)
    end
  end
end
