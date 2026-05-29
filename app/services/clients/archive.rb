# frozen_string_literal: true

module Clients
  class Archive
    def self.call(client:, user:, account: ActsAsTenant.current_tenant)
      new(client: client, user: user, account: account).call
    end

    def initialize(client:, user:, account:)
      @client = client
      @user = user
      @account = account
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
      end
    end

    private

    def revoke_active_invites!
      @client.upload_invites.where(revoked_at: nil).find_each(&:revoke!)
    end
  end
end
