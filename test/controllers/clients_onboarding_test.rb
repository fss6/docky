# frozen_string_literal: true

require "test_helper"

class ClientsOnboardingTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    seed_onboarding_templates!
  end

  test "creates client in onboarding with checklist" do
    assert_difference("Client.count") do
      post clients_url, params: {
        onboarding_kind: "new_client",
        client: { name: "Padaria Nova", email: "padaria@example.com" }
      }
    end

    client = Client.find_by!(name: "Padaria Nova")
    assert client.onboarding?
    assert client.onboarding_checklist.present?
    assert client.onboarding_checklist.items.count.positive?
    assert_nil client.competency_checklists.find_by(period: Date.current.beginning_of_month)
    assert_redirected_to client_url(client)
  end

  test "creates active client when skipping onboarding" do
    post clients_url, params: {
      onboarding_kind: "skipped",
      client: { name: "Cliente Pronto" }
    }

    client = Client.find_by!(name: "Cliente Pronto")
    assert client.active?
    assert client.competency_checklists.where(period: Date.current.beginning_of_month).exists?
  end

  test "shows onboarding layout for onboarding client" do
    client = create_onboarding_client
    get client_url(client)
    assert_response :success
    assert_match "Em onboarding", response.body
    assert_match "Checklist de onboarding", response.body
    assert_no_match "Status do mês", response.body
  end

  test "manual activation marks client active and opens period" do
    client = create_onboarding_client
    post client_onboarding_activation_url(client)

    client.reload
    assert client.active?
    assert client.competency_checklists.where(period: Date.current.beginning_of_month).exists?
  end

  test "automatic activation when all items received" do
    client = create_onboarding_client
    ActsAsTenant.with_tenant(client.account) do
      client.onboarding_checklist.items.each do |item|
        Onboarding::MarkItemReceived.call(item: item, user: users(:owner), account: client.account)
      end
      assert client.reload.active?
    end
  end

  test "creates onboarding upload invite" do
    client = create_onboarding_client
    assert_difference("UploadInvite.purpose_onboarding.count") do
      post client_onboarding_upload_invites_url(client), headers: { Accept: "application/json" }
    end
    assert_response :success
  end

  test "monthly upload blocked for onboarding client" do
    client = create_onboarding_client
    period = Date.current.beginning_of_month
    ActsAsTenant.with_tenant(client.account) do
      Periods::OpenForClient.call(client: client, period: period, account: client.account)
      invite = Clients::CreateUploadInvite.call(client: client, period: period, user: users(:owner), account: client.account)
      get public_folder_upload_url(token: invite.token)
    end
    assert_response :forbidden
    assert_match "configuração", response.body
  end

  test "public onboarding portal renders" do
    client = create_onboarding_client
    invite = ActsAsTenant.with_tenant(client.account) do
      Clients::CreateOnboardingUploadInvite.call(client: client, user: users(:owner), account: client.account)
    end
    get public_onboarding_upload_url(token: invite.token)
    assert_response :success
    assert_match "Vamos configurar sua conta?", response.body
  end
end
