# frozen_string_literal: true

require "test_helper"

module Clients
  class ArchiveTest < ActiveSupport::TestCase
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Archive Test", price: 0)
      @account = Account.create!(name: "Archive Account", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner Archive",
        email: "owner-archive-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @client = Client.create!(account: @account, name: "Cliente Archive", status: :active, tax_id: unique_valid_test_tax_id(account: @account), email: valid_test_client_email)
        @invite = UploadInvite.create!(
          account: @account,
          client: @client,
          period: Date.current.beginning_of_month,
          token: UploadInvite.generate_token
        )
      end
    end

    test "archives client and revokes active invites" do
      ActsAsTenant.with_tenant(@account) do
        assert_difference -> { AuditEvent.where(event_type: "client.archived").count }, 1 do
          Clients::Archive.call(client: @client, user: @user)
        end

        @client.reload
        assert @client.archived?
        assert_equal @user, @client.archived_by_user
        assert_not @invite.reload.active?
      end
    end

    test "raises when client already archived" do
      ActsAsTenant.with_tenant(@account) do
        Clients::Archive.call(client: @client, user: @user)
        assert_raises(ArgumentError) { Clients::Archive.call(client: @client.reload, user: @user) }
      end
    end
  end
end
