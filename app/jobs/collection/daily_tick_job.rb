# frozen_string_literal: true

module Collection
  class DailyTickJob < ApplicationJob
    queue_as :default

    def perform(reference_date_iso = nil)
      Account.find_each do |account|
        settings = account.collection_setting
        next unless settings&.enabled?

        EvaluateAccountJob.perform_later(account.id, reference_date_iso)
      end
    end
  end
end
