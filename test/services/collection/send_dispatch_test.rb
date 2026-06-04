# frozen_string_literal: true

require "test_helper"

module Collection
  class SendDispatchTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      @settings = collection_settings(:one)
      @step = collection_steps(:friendly)
      ActsAsTenant.current_tenant = @account
      @period = Period.create!(
        account: @account,
        client: @client,
        period: Date.current.beginning_of_month,
        status: :open,
        opened_at: Time.current
      )
      @period.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)
    end

    test "skips scheduled dispatch when daily channel limit reached at send time" do
      firm = collection_steps(:firm)

      CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: @step,
        channel: :email,
        status: :sent,
        sent_at: Time.current
      )

      dispatch = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: firm,
        channel: :email,
        status: :scheduled
      )

      ActionMailerDelivery.stub(:enabled?, true) do
        assert_no_emails do
          SendDispatch.call(dispatch)
        end
      end

      dispatch.reload
      assert dispatch.status_skipped?
      assert_equal "daily_limit", dispatch.skip_reason
    end

    test "only one email dispatch sends when two scheduled for same client same day" do
      firm = collection_steps(:firm)

      first = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: @step,
        channel: :email,
        status: :scheduled,
        rendered_subject: "Assunto",
        rendered_body: "Corpo"
      )
      second = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period,
        collection_step: firm,
        channel: :email,
        status: :scheduled,
        rendered_subject: "Assunto 2",
        rendered_body: "Corpo 2"
      )

      ActionMailerDelivery.stub(:enabled?, true) do
        AuditEvents::Recorder.stub(:call, true) do
          assert_emails 1 do
            SendDispatch.call(first)
            SendDispatch.call(second)
          end
        end
      end

      first.reload
      second.reload
      assert first.status_sent?
      assert second.status_skipped?
      assert_equal "daily_limit", second.skip_reason
    end
  end
end
