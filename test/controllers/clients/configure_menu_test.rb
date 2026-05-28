# frozen_string_literal: true

require "test_helper"

module Clients
  class ConfigureMenuTest < ActionDispatch::IntegrationTest
    def setup_fixtures
    end

    def teardown_fixtures
    end

    setup do
      @plan = Plan.create!(name: "Teste Menu", price: 0)
      @account = Account.create!(name: "Conta Menu", plan: @plan, active: true)
      @user = User.create!(
        account: @account,
        name: "Owner Menu",
        email: "owner-menu-#{SecureRandom.hex(4)}@example.com",
        role: :owner,
        active: true,
        password: "password123",
        password_confirmation: "password123"
      )
      ActsAsTenant.with_tenant(@account) do
        @active_client = Client.create!(account: @account, name: "Cliente Ativo", status: :active)
        @period_param = Date.current.strftime("%Y-%m")
        CompetencyChecklist.create!(
          account: @account,
          client: @active_client,
          period: Date.current.beginning_of_month
        )
      end
      seed_onboarding_templates!(@account)
      ActsAsTenant.with_tenant(@account) do
        onboarding_client = Client.new(name: "Cliente Onboarding", email: "onb@example.com")
        @onboarding_client = Clients::CreateWithOnboarding.call(
          client: onboarding_client,
          onboarding_kind: "new_client",
          user: @user,
          account: @account
        )
      end
      sign_in @user
    end

    test "active client configure menu shows grouped items without settings link" do
      get client_path(@active_client, period: @period_param)

      assert_response :success
      assert_select "[data-testid='client-configure-menu']" do
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.checklist_template.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.client_data.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.checklist_template.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.onboarding_start.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.onboarding_reopen.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.delete_client.title"))}/
        assert_select "button[data-app-confirm-modal-heading-param=?]", I18n.t("clients.onboarding_start_confirm_modal.heading")
        assert_select "button[data-app-confirm-modal-heading-param=?]", I18n.t("clients.onboarding_reopen_confirm_modal.heading")
        assert_select "button[data-app-confirm-modal-heading-param=?]", I18n.t("clients.delete_confirm_modal.heading")
        assert_select "button[data-app-confirm-modal-item-label-param=?]", @active_client.name
        assert_select "a[href=?]", settings_path, count: 0
        assert_select "*", text: /Mensagens de compartilhamento/, count: 0
      end
    end

    test "onboarding client configure menu shows onboarding items only" do
      get client_path(@onboarding_client)

      assert_response :success
      assert_select "[data-testid='client-configure-menu']" do
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.onboarding_items.title"))}/
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.client_data.title"))}/
        assert_select "button[data-app-confirm-modal-heading-param=?]", I18n.t("clients.delete_confirm_modal.heading")
        assert_select "button[data-app-confirm-modal-item-label-param=?]", @onboarding_client.name
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.onboarding_start.title"))}/, count: 0
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.onboarding_reopen.title"))}/, count: 0
        assert_select "*", text: /#{Regexp.escape(I18n.t("clients.configure_menu.checklist_template.title"))}/, count: 0
        assert_select "a[href=?]", settings_path, count: 0
        assert_select "*", text: /Mensagens de onboarding/, count: 0
      end
    end
  end
end
