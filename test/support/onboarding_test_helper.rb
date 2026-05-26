# frozen_string_literal: true

module OnboardingTestHelper
  def seed_onboarding_templates!(account = accounts(:one))
    Onboarding::SeedDefaultTemplates.call(account: account)
  end

  def create_onboarding_client(name: "Onboarding Test Co", onboarding_kind: "new_client", account: accounts(:one))
    seed_onboarding_templates!(account)
    ActsAsTenant.with_tenant(account) do
      client = Client.new(name: name, email: "onboarding@example.com")
      Clients::CreateWithOnboarding.call(
        client: client,
        onboarding_kind: onboarding_kind,
        user: users(:owner),
        account: account
      )
      client
    end
  end
end
