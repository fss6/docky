# frozen_string_literal: true

module Collection
  class FlushScheduledDispatchesJob < ApplicationJob
    queue_as :default

    def perform
      Collection::FlushScheduledDispatches.call
    end
  end
end
