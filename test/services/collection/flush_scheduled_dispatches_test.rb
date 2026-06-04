# frozen_string_literal: true

require "test_helper"

module Collection
  class FlushScheduledDispatchesTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      @settings = collection_settings(:one)
      ActsAsTenant.current_tenant = @account
      @period = Date.current.beginning_of_month
      @period_record = Period.create!(
        account: @account,
        client: @client,
        period: @period,
        status: :open,
        opened_at: Time.current
      )
      @period_record.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)
      @step = collection_steps(:friendly)
    end

    test "enqueues send for scheduled dispatch inside sending window" do
      @settings.update!(
        enabled: true,
        timezone: "America/Sao_Paulo",
        quiet_hours_start: Time.zone.parse("2000-01-01 06:00:00"),
        quiet_hours_end: Time.zone.parse("2000-01-01 22:00:00")
      )

      dispatch = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period_record,
        collection_step: @step,
        channel: :email,
        status: :scheduled
      )

      with_deliverable_email do
        at = Time.zone.local(2026, 6, 3, 10, 0, 0)
        travel_to at do
          assert_enqueued_jobs 1, only: Collection::SendDispatchJob do
            assert_equal 1, FlushScheduledDispatches.call
          end
        end
      end
    end

    test "does not enqueue outside sending window" do
      @settings.update!(
        enabled: true,
        timezone: "America/Sao_Paulo",
        quiet_hours_start: Time.zone.parse("2000-01-01 08:00:00"),
        quiet_hours_end: Time.zone.parse("2000-01-01 19:00:00")
      )

      CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period_record,
        collection_step: @step,
        channel: :email,
        status: :scheduled
      )

      with_deliverable_email do
        at = Time.zone.local(2026, 6, 3, 22, 0, 0)
        travel_to at do
          assert_no_enqueued_jobs only: Collection::SendDispatchJob do
            assert_equal 0, FlushScheduledDispatches.call
          end
        end
      end
    end

    test "marks skipped when client opted out of email" do
      @settings.update!(enabled: true)
      ClientCollectionPreference.ensure_for!(@client).update!(email_opted_out_at: Time.current)

      dispatch = CollectionDispatch.create!(
        account: @account,
        client: @client,
        period: @period_record,
        collection_step: @step,
        channel: :email,
        status: :scheduled
      )

      with_deliverable_email do
        travel_to Time.zone.local(2026, 6, 3, 10, 0, 0) do
          assert_no_enqueued_jobs only: Collection::SendDispatchJob do
            assert_equal 0, FlushScheduledDispatches.call
          end
          dispatch.reload
          assert dispatch.status_skipped?
          assert_equal "email_opt_out", dispatch.skip_reason
        end
      end
    end

    private

    def with_deliverable_email
      ActionMailerDelivery.stub(:enabled?, true) { yield }
    end
  end
end
