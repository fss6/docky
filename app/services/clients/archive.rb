# frozen_string_literal: true

module Clients
  class Archive
    def self.call(client:, user:, account: ActsAsTenant.current_tenant, clear_session: nil)
      new(client: client, user: user, account: account, clear_session: clear_session).call
    end

    def initialize(client:, user:, account:, clear_session:)
      @client = client
      @user = user
      @account = account
      @clear_session = clear_session
    end

    def call
      raise ArgumentError, "Cliente já está arquivado" if @client.archived?

      Client.transaction do
        @client.update!(
          archived_at: Time.current,
          archived_by_user: @user
        )

        revoke_active_invites!

        AuditEvents::Recorder.call(
          account: @account,
          user: @user,
          event_type: "client.archived",
          subject: @client,
          metadata: {}
        )

        @client
      end.tap do
        @clear_session&.call(@client)
      end
    end

    private

    def revoke_active_invites!
      @client.upload_invites.where(revoked_at: nil).find_each(&:revoke!)
    end
  end
end
