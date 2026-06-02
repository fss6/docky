# frozen_string_literal: true

module Whatsapp
  # v1: always platform Dokivo credentials. Future: per-account channel.
  class ChannelResolver
    def self.for(_account)
      :platform
    end

    def self.client
      Client.new
    end
  end
end
