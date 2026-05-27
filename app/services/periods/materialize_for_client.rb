# frozen_string_literal: true

module Periods
  class MaterializeForClient
    Result = Struct.new(:period_record, :created, :error, keyword_init: true)

    def self.call(client:, period:, user:, account: client.account)
      new(client: client, period: period, user: user, account: account).call
    end

    def initialize(client:, period:, user:, account:)
      @client = client
      @user = user
      @account = account
      @period = period.to_date.beginning_of_month
    end

    def call
      existing = Period.find_by(account: @account, client: @client, period: @period)
      return Result.new(period_record: existing, created: false) if existing

      period_record = if @period < Date.current.beginning_of_month
                        create_retroactive_closed!
                      else
                        OpenForClient.call(client: @client, period: @period, account: @account)
                      end

      EnsureFolderShim.call(account: @account, client: @client, period: @period)
      Result.new(period_record: period_record, created: true)
    end

    private

    def create_retroactive_closed!
      now = Time.current
      period_record = Period.create!(
        account: @account,
        client: @client,
        period: @period,
        status: :closed,
        opened_at: now,
        closed_at: now,
        closed_by_user: @user
      )

      AuditEvents::Recorder.call(
        account: @account,
        user: @user,
        event_type: "period.created_retroactive",
        subject: period_record,
        metadata: {
          client_id: @client.id,
          period: period_record.period_param,
          reason: "retroactive_seed"
        }
      )

      period_record
    end
  end
end
