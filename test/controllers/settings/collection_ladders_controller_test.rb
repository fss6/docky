# frozen_string_literal: true

require "test_helper"

class Settings::CollectionLaddersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
    ActsAsTenant.with_tenant(accounts(:one)) do
      @setting = CollectionSetting.ensure_for!(accounts(:one))
      Collection::SeedDefaultSteps.call(account: accounts(:one)) unless accounts(:one).collection_steps.exists?
    end
  end

  test "edit renders" do
    get edit_settings_collection_ladder_path
    assert_response :success
    assert_select "h1", text: /Régua de cobrança/
  end

  test "update collection settings" do
    patch settings_collection_ladder_path, params: {
      collection_setting: {
        enabled: true,
        auto_confirm_receipt: true,
        quiet_hours_start: "08:00",
        quiet_hours_end: "19:00",
        max_messages_per_client_per_day: 2,
        timezone: "America/Sao_Paulo"
      }
    }
    assert_redirected_to edit_settings_collection_ladder_path
    assert collection_settings(:one).reload.enabled?
  end

  test "does not enable email on step when smtp not configured" do
    step = collection_steps(:friendly)
    ActionMailerDelivery.stub(:enabled?, false) do
      patch settings_collection_ladder_path, params: {
        collection_setting: {
          enabled: true,
          auto_confirm_receipt: true,
          quiet_hours_start: "08:00",
          quiet_hours_end: "19:00",
          max_messages_per_client_per_day: 1,
          timezone: "America/Sao_Paulo"
        },
        collection_steps: {
          step.id => {
            email_enabled: "1",
            whatsapp_enabled: "0",
            email_subject_template: step.email_subject_template,
            email_body_template: step.email_body_template
          }
        }
      }
    end
    assert_redirected_to edit_settings_collection_ladder_path
    assert_not step.reload.email_enabled?
  end
end
