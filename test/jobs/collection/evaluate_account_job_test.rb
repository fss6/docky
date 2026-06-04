# frozen_string_literal: true

require "test_helper"

module Collection
  class EvaluateAccountJobTest < ActiveJob::TestCase
    include ActiveJob::TestHelper

    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.current_tenant = @account
      settings = CollectionSetting.ensure_for!(@account)
      settings.update!(enabled: true)
    end

    test "uses reference_date_iso for step offset on retroactive period" do
      @client.update!(monthly_deadline_day: 10)
      retro = Period.create!(
        account: @account,
        client: @client,
        period: Date.new(2026, 4, 1),
        status: :open,
        opened_at: Time.current
      )
      retro.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)

      travel_to Time.zone.local(2026, 6, 1, 10, 0, 0) do
        ActionMailerDelivery.stub(:enabled?, true) do
          Whatsapp::PlatformConfig.stub(:configured?, false) do
            EvaluateAccountJob.perform_now(@account.id, Date.new(2026, 6, 1).iso8601)
          end
        end

        assert_nil CollectionDispatch.find_by(period: retro, channel: :email),
                   "April period should not match when reference_date is June"
      end
    end

    test "evaluates retroactive open period with pending items not only current month" do
      @client.update!(monthly_deadline_day: 10)
      retro = Period.create!(
        account: @account,
        client: @client,
        period: Date.new(2026, 4, 1),
        status: :open,
        opened_at: Time.current
      )
      retro.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)

      # Prazo 10/04; no dia do prazo (etapa 0d do fixture "firm") dispara e-mail
      travel_to Time.zone.local(2026, 4, 10, 10, 0, 0) do
        ActionMailerDelivery.stub(:enabled?, true) do
          Whatsapp::PlatformConfig.stub(:configured?, false) do
            EvaluateAccountJob.perform_now(@account.id, Date.new(2026, 4, 10).iso8601)
          end
        end

        dispatch = CollectionDispatch.find_by(period: retro, channel: :email)
        assert dispatch.present?, "expected email dispatch for retro period on due date"
        assert dispatch.status_scheduled? || dispatch.status_sent?
      end
    end
  end
end
