# frozen_string_literal: true

require "test_helper"

module Collection
  class ChannelEligibilityTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      @settings = collection_settings(:one)
      @step = collection_steps(:friendly)
      ActsAsTenant.current_tenant = @account
    end

    test "email_not_configured when MAIL_DELIVERY unset" do
      ActionMailerDelivery.stub(:enabled?, false) do
        reason = ChannelEligibility.skip_reason(
          channel: :email,
          client: @client,
          account: @account,
          step: @step,
          settings: @settings
        )
        assert_equal "email_not_configured", reason
      end
    end

    test "deliverable when email channel and smtp configured" do
      ActionMailerDelivery.stub(:enabled?, true) do
        assert ChannelEligibility.deliverable?(
          channel: :email,
          client: @client,
          account: @account,
          step: @step,
          settings: @settings
        )
      end
    end

    test "no_phone blocks whatsapp channel" do
      Whatsapp::PlatformConfig.stub(:configured?, true) do
        step = collection_steps(:firm)
        reason = ChannelEligibility.skip_reason(
          channel: :whatsapp,
          client: @client,
          account: @account,
          step: step,
          settings: @settings
        )
        assert_equal "no_phone", reason
      end
    end
  end
end
