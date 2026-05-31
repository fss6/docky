# frozen_string_literal: true

module OnboardingTestHelper
  VALID_TEST_CPF = "39053344705"
  VALID_TEST_CNPJ = "19131243000197"
  # CNPJ alfanumérico (DV módulo 11, base 12ABC34501DE — Receita Federal)
  VALID_TEST_ALPHANUMERIC_CNPJ = "12ABC34501DE35"

  def seed_onboarding_templates!(account = accounts(:one))
    Onboarding::SeedDefaultTemplates.call(account: account)
  end

  def create_onboarding_client(name: "Onboarding Test Co", tax_id: nil, onboarding_template: nil, account: accounts(:one))
    seed_onboarding_templates!(account)
    template = onboarding_template || account.onboarding_templates.find_by!(kind: "new_company")
    tax_id ||= unique_valid_test_tax_id(account: account)

    ActsAsTenant.with_tenant(account) do
      client = Client.new(name: name, email: "onboarding@example.com", tax_id: tax_id)
      Clients::CreateWithOnboarding.call(
        client: client,
        onboarding_template_id: template.id,
        user: users(:owner),
        account: account
      )
      client
    end
  end
end
