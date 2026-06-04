# frozen_string_literal: true

require "test_helper"

class PlatformCollectionDispatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @client = clients(:alpha)
    @step = collection_steps(:friendly)
    ActsAsTenant.current_tenant = @account
    @period = Period.create!(
      account: @account,
      client: @client,
      period: Date.current.beginning_of_month,
      status: :open,
      opened_at: Time.current
    )
    @dispatch = CollectionDispatch.create!(
      account: @account,
      client: @client,
      period: @period,
      collection_step: @step,
      channel: :email,
      status: :scheduled,
      rendered_subject: "Teste",
      rendered_body: "Corpo"
    )
  end

  test "administrator can view dispatch monitor index" do
    sign_in users(:administrator)
    get collection_dispatches_platform_settings_path
    assert_response :success
    assert_select "h1", text: /Monitor de envios/
    assert_match @client.name, response.body
  end

  test "administrator can view dispatch detail" do
    sign_in users(:administrator)
    get platform_collection_dispatch_platform_settings_path(@dispatch)
    assert_response :success
    assert_match @dispatch.rendered_subject, response.body
  end

  test "owner cannot access dispatch monitor" do
    sign_in users(:owner)
    get collection_dispatches_platform_settings_path
    assert_redirected_to authenticated_root_path
  end

  test "index filters by status" do
    sent_dispatch = CollectionDispatch.create!(
      account: @account,
      client: @client,
      period: @period,
      collection_step: collection_steps(:firm),
      channel: :whatsapp,
      status: :sent,
      sent_at: Time.current
    )

    sign_in users(:administrator)
    get collection_dispatches_platform_settings_path, params: { status: "scheduled" }
    assert_response :success
    assert_match "Lembrete amigável", response.body
    assert_no_match "Lembrete firme", response.body
    assert sent_dispatch.persisted?
  end
end
