# frozen_string_literal: true

require "test_helper"

module Collection
  class EvaluateClientPeriodTest < ActiveSupport::TestCase
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
      @item = @period_record.items.create!(name_snapshot: "Extrato", match_terms: ["extrato"], state: :pending)
    end

    test "skips whatsapp when platform not configured" do
      with_deliverable_email do
        Whatsapp::PlatformConfig.stub(:configured?, false) do
          travel_to Deadline.for(client: @client, period: @period) do
            dispatches = EvaluateClientPeriod.call(
              client: @client,
              period_record: @period_record,
              settings: @settings
            )
            wa = dispatches.find { |d| d.channel_whatsapp? }
            assert wa&.status_skipped?
            assert_equal "whatsapp_not_configured", wa.skip_reason
            email = dispatches.find { |d| d.channel_email? }
            assert email
            assert_not email.status_skipped?
          end
        end
      end
    end

    test "idempotent dispatch per channel" do
      with_deliverable_email do
        Whatsapp::PlatformConfig.stub(:configured?, false) do
          travel_to Deadline.for(client: @client, period: @period) do
            first = EvaluateClientPeriod.call(client: @client, period_record: @period_record, settings: @settings)
            second = EvaluateClientPeriod.call(client: @client, period_record: @period_record, settings: @settings)
            email_first = first.count { |d| d.channel_email? }
            email_second = second.count { |d| d.channel_email? }
            assert email_first.positive?
            assert_equal email_first, email_second
          end
        end
      end
    end

    test "email only step with smtp not configured creates no dispatches" do
      ActionMailerDelivery.stub(:enabled?, false) do
        travel_to Deadline.for(client: @client, period: @period) - 3.days do
          assert_no_difference -> { CollectionDispatch.count } do
            dispatches = EvaluateClientPeriod.call(
              client: @client,
              period_record: @period_record,
              settings: @settings
            )
            assert_empty dispatches
          end
        end
      end
    end

    test "whatsapp only step with no phone creates no dispatches" do
      @account.collection_steps.create!(
        position: 50,
        offset_days: 2,
        name: "Só WhatsApp",
        kind: :client_reminder,
        email_enabled: false,
        whatsapp_enabled: true,
        email_subject_template: "",
        email_body_template: "",
        whatsapp_body_template: "Oi {cliente}",
        whatsapp_template_name: "cobranca_teste"
      )

      with_deliverable_email do
        Whatsapp::PlatformConfig.stub(:configured?, true) do
          travel_to Deadline.for(client: @client, period: @period) + 2.days do
            assert_no_difference -> { CollectionDispatch.count } do
              dispatches = EvaluateClientPeriod.call(
                client: @client,
                period_record: @period_record,
                settings: @settings
              )
              assert_empty dispatches
            end
          end
        end
      end
    end

    test "internal alert runs without client phone" do
      @account.update!(contact_email: "gestor@escritorio.com")
      @account.collection_steps.create!(
        position: 60,
        offset_days: 5,
        name: "Alerta gestor",
        kind: :internal_alert,
        email_enabled: true,
        whatsapp_enabled: false,
        email_subject_template: "Cliente pendente",
        email_body_template: "Pendente: {documentos_faltantes}"
      )

      with_deliverable_email do
        travel_to Deadline.for(client: @client, period: @period) + 5.days do
          dispatches = EvaluateClientPeriod.call(
            client: @client,
            period_record: @period_record,
            settings: @settings
          )
          internal = dispatches.find { |d| d.channel_internal? }
          assert internal
          assert_not internal.status_skipped?
        end
      end
    end

    private

    def with_deliverable_email
      ActionMailerDelivery.stub(:enabled?, true) { yield }
    end
  end
end
