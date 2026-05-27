# frozen_string_literal: true

module Periods
  class LoadMonthlyContext
    Result = Struct.new(:period_record, :checklist, :documents_scope, :folder_shim, :period, keyword_init: true)

    def self.call(client:, period:, account: ActsAsTenant.current_tenant, create_if_missing: true)
      new(client: client, period: period, account: account, create_if_missing: create_if_missing).call
    end

    def initialize(client:, period:, account:, create_if_missing:)
      @client = client
      @account = account
      @period = period.to_date.beginning_of_month
      @create_if_missing = create_if_missing
    end

    def call
      period_record = resolve_period_record
      unless period_record
        return Result.new(
          period_record: nil,
          checklist: nil,
          documents_scope: Document.none,
          folder_shim: nil,
          period: @period
        )
      end

      folder_shim = EnsureFolderShim.call(account: @account, client: @client, period: @period)

      Result.new(
        period_record: period_record,
        checklist: period_record,
        documents_scope: documents_scope(period_record),
        folder_shim: folder_shim,
        period: @period
      )
    end

    private

    def resolve_period_record
      if @create_if_missing
        FindOrOpen.call(account: @account, client: @client, period: @period)
      else
        Period.find_by(account: @account, client: @client, period: @period)
      end
    end

    def documents_scope(period_record)
      Document.where(client_id: @client.id, period_id: period_record.id)
    end
  end
end
