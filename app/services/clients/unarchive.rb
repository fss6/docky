# frozen_string_literal: true

module Clients
  class Unarchive
    def self.call(client:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, user: user, account: account).call
    end

    def initialize(client:, user:, account:)
      @client = client
      @user = user
      @account = account
    end

    def call
      raise ArgumentError, "Cliente não está arquivado" unless @client.archived?

      Client.transaction do
        @client.update!(
          archived_at: nil,
          archived_by_user: nil
        )

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.unarchived",
          subject: @client,
          metadata: {}
        )

        @client
      end
    end
  end
end
