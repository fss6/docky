# frozen_string_literal: true

require "test_helper"

class OnboardingServicesTest < ActiveSupport::TestCase
  setup do
    seed_onboarding_templates!
  end

  test "build from template copies items" do
    client = create_onboarding_client
    assert_equal 7, client.onboarding_checklist.items.count
  end

  test "migration template has more items" do
    client = create_onboarding_client(onboarding_kind: "migration")
    assert_equal 12, client.onboarding_checklist.items.count
  end

  test "progress calculates counts" do
    client = create_onboarding_client
    checklist = client.onboarding_checklist
    progress = Onboarding::Progress.call(checklist: checklist)
    assert_equal 0, progress.received_count
    assert_equal 7, progress.total_count

    item = checklist.items.first
    Onboarding::MarkItemReceived.call(item: item, user: users(:owner))
    progress = Onboarding::Progress.call(checklist: checklist.reload)
    assert_equal 1, progress.received_count
  end

  test "reopen onboarding resets client status" do
    client = create_onboarding_client
    ActsAsTenant.with_tenant(client.account) do
      Clients::ActivateFromOnboarding.call(client: client, user: users(:owner), account: client.account)
      assert client.reload.active?

      Clients::ReopenOnboarding.call(client: client, user: users(:owner), account: client.account)
      assert client.reload.onboarding?
      assert client.onboarding_checklist.in_progress?
    end
  end

  test "seed preserves customized templates and items" do
    account = accounts(:one)
    template = account.onboarding_templates.find_by!(kind: "new_company")
    item = template.items.first

    template.update!(name: "Template customizado", position: 99)
    item.update!(name: "Documento customizado", help_text: "Texto customizado", position: 42)

    Onboarding::SeedDefaultTemplates.call(account: account)

    assert_equal "Template customizado", template.reload.name
    assert_equal 99, template.position
    assert_equal "Documento customizado", item.reload.name
    assert_equal "Texto customizado", item.help_text
    assert_equal 42, item.position
  end
end
