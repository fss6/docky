# frozen_string_literal: true

module Documents
  class AssignToPeriod
    def self.call(document:, period_record:, folder:, user_id:, metadata: {})
      new(
        document: document,
        period_record: period_record,
        folder: folder,
        user_id: user_id,
        metadata: metadata
      ).call
    end

    def initialize(document:, period_record:, folder:, user_id:, metadata: {})
      @document = document
      @period_record = period_record
      @folder = folder
      @user_id = user_id
      @metadata = metadata
    end

    def call
      @document.assign_attributes(
        account_id: @folder.account_id,
        user_id: @user_id,
        status: :pending,
        client_id: @period_record.client_id,
        period: @period_record,
        collection_period: @period_record.period,
        folder: @folder,
        metadata: @metadata
      )
      @document
    end
  end
end
