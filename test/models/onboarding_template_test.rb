# frozen_string_literal: true

require "test_helper"

class OnboardingTemplateTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    ActsAsTenant.current_tenant = @account
  end

  test "assigns kind slug from name on create" do
    template = @account.onboarding_templates.create!(name: "Clínica Médica")

    assert_equal "clinica_medica", template.kind
    assert_not template.system?
  end

  test "assigns unique kind slug when name collides" do
    @account.onboarding_templates.create!(name: "Clínica Médica")
    duplicate = @account.onboarding_templates.create!(name: "Clínica Médica")

    assert_equal "clinica_medica_2", duplicate.kind
  end

  test "assigns incremental position on create" do
    seed_onboarding_templates!(@account)
    max_position = @account.onboarding_templates.maximum(:position)

    template = @account.onboarding_templates.create!(name: "Template extra")

    assert_equal max_position + 1, template.position
  end

  test "cannot destroy template linked to clients" do
    seed_onboarding_templates!(@account)
    template = @account.onboarding_templates.find_by!(kind: "new_company")
    create_onboarding_client(onboarding_template: template, account: @account)

    assert_not template.destroy
    assert template.persisted?
  end
end
