# frozen_string_literal: true

module Periods
  class Close
    def self.call(period:, user:, ip: nil)
      new(period: period, user: user, ip: ip).call
    end

    def initialize(period:, user:, ip: nil)
      @period = period
      @user = user
      @ip = ip # reserved for metadata
    end

    def call
      return false if @period.closed?

      @period.update!(
        status: :closed,
        closed_at: Time.current,
        closed_by_user: @user
      )

      invalidate_cache
      record_audit!
      true
    end

    private

    def invalidate_cache
      Clients::InvalidateSummaryCache.call(client: @period.client, period: @period.period)
    end

    def record_audit!
      AuditEvents::Recorder.call(
        account: @period.account,
        user: @user,
        event_type: "period.closed",
        subject: @period,
        metadata: {
          client_id: @period.client_id,
          period: @period.period_param,
          ip: @ip
        }.compact
      )
    end
  end
end
