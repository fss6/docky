# frozen_string_literal: true

module Clients
  class EnsureMonthlyCollection
    Result = Struct.new(:checklist, :documents_scope, :folder_shim, :period, keyword_init: true)

    def self.call(client:, period:, account: ActsAsTenant.current_tenant)
      new(client: client, period: period, account: account).call
    end

    def initialize(client:, period:, account:)
      @client = client
      @account = account
      @period = period.to_date.beginning_of_month
    end

    def call
      checklist = Checklist::BuildForCompetency.new(
        account: @account,
        client: @client,
        period: @period
      ).call

      folder_shim = ensure_folder_shim!

      Result.new(
        checklist: checklist,
        documents_scope: documents_scope,
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

    def documents_scope
      Document.where(client_id: @client.id, collection_period: @period)
    end
  end
end
