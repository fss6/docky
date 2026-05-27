# frozen_string_literal: true

module Clients
  class EnsureMonthlyCollection
    Result = Struct.new(:period_record, :checklist, :documents_scope, :folder_shim, :period, keyword_init: true)

    def self.call(client:, period:, account: ActsAsTenant.current_tenant, create_if_missing: true)
      context = Periods::LoadMonthlyContext.call(
        client: client,
        period: period,
        account: account,
        create_if_missing: create_if_missing
      )

      Result.new(
        period_record: context.period_record,
        checklist: context.checklist,
        documents_scope: context.documents_scope,
        folder_shim: context.folder_shim,
        period: context.period
      )
    end
  end
end
