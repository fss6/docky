# frozen_string_literal: true

require "test_helper"

module Collection
  class DailyChannelLimitTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.current_tenant = @account
      @period = Period.create!(
        account: @account,
        client: @client,
        period: Date.current.beginning_of_month,
        status: :open,
        opened_at: Time.current
      )
      @step = collection_steps(:friendly)
      @firm = collection_steps(:firm)
    end

    test "reached when same channel already sent today" do
      CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: @step,
        channel: :email,
        status: :sent,
        sent_at: Time.current
      )

      assert DailyChannelLimit.reached?(client: @client, channel: :email)
    end

    test "not reached for different channel on same day" do
      CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: @step,
        channel: :email,
        status: :sent,
        sent_at: Time.current
      )

      assert_not DailyChannelLimit.reached?(client: @client, channel: :whatsapp)
    end

    test "internal channel is never limited" do
      CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: @step,
        channel: :internal,
        status: :sent,
        sent_at: Time.current
      )

      assert_not DailyChannelLimit.reached?(client: @client, channel: :internal)
    end
  end
end
