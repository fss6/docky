# frozen_string_literal: true

require "test_helper"

class UploadInviteTest < ActiveSupport::TestCase
  setup do
    seed_onboarding_templates!
  end

  test "monthly invite requires period" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      invite = UploadInvite.new(
        account: accounts(:one),
        client: clients(:alpha),
        purpose: :monthly,
        token: UploadInvite.generate_token
      )
      assert_not invite.valid?
      assert invite.errors[:period].present?
    end
  end

  test "onboarding invite allows nil period" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      invite = UploadInvite.new(
        account: accounts(:one),
        client: clients(:alpha),
        purpose: :onboarding,
        token: UploadInvite.generate_token
      )
      assert invite.valid?
    end
  end
end
