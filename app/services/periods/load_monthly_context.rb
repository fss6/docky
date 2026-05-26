# frozen_string_literal: true

module Periods
  class LoadMonthlyContext
    Result = Struct.new(:period_record, :checklist, :documents_scope, :folder_shim, :period, keyword_init: true)

    def self.call(client:, period:, account: ActsAsTenant.current_tenant)
      new(client: client, period: period, account: account).call
    end

    def initialize(client:, period:, account:)
      @client = client
      @account = account
      @period = period.to_date.beginning_of_month
    end

    def call
      period_record = FindOrOpen.call(
        account: @account,
        client: @client,
        period: @period
      )

      folder_shim = ensure_folder_shim!

      Result.new(
        period_record: period_record,
        checklist: period_record,
        documents_scope: documents_scope(period_record),
        folder_shim: folder_shim,
        period: @period
      )
    end

    private

    def ensure_folder_shim!
      Folder.find_or_create_by!(
        account: @account,
        client: @client,
        name: @period.strftime("%Y-%m"),
        visible: false
      )
    end

    def documents_scope(period_record)
      Document.where(client_id: @client.id, period_id: period_record.id)
    end
  end
end
