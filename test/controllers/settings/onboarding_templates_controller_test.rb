# frozen_string_literal: true

require "test_helper"

module Settings
  class OnboardingTemplatesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @account = accounts(:one)
      @user = users(:owner)
      sign_in @user
      seed_onboarding_templates!(@account)
      @template = @account.onboarding_templates.find_by!(kind: "new_company")
    end

    test "index renders templates page" do
      get settings_onboarding_templates_url

      assert_response :success
      assert_match "Templates de onboarding", response.body
      assert_match @template.name, response.body
      assert_match "Ver", response.body
      assert_match "Editar", response.body
    end

    test "show renders template items" do
      item = @template.items.ordered.first

      get settings_onboarding_template_url(@template)

      assert_response :success
      assert_match @template.name, response.body
      assert_match item.name, response.body
    end

    test "edit renders nested items form" do
      get edit_settings_onboarding_template_url(@template)

      assert_response :success
      assert_match "Editar template", response.body
      assert_match "items_attributes", response.body
    end

    test "update persists template and multiple nested item fields" do
      first = @template.items.ordered.first
      second = @template.items.ordered.second

      patch settings_onboarding_template_url(@template), params: {
        onboarding_template: {
          name: "Empresa em abertura",
          items_attributes: {
            "0" => {
              id: first.id,
              name: "Contrato social atualizado",
              help_text: "Versão assinada",
              position: 1
            },
            "1" => {
              id: second.id,
              name: "CNPJ atualizado",
              help_text: "Cartão atualizado",
              position: 0
            }
          }
        }
      }

      assert_redirected_to settings_onboarding_template_url(@template)
      @template.reload
      assert_equal "Empresa em abertura", @template.name
      assert_equal "Contrato social atualizado", first.reload.name
      assert_equal "Versão assinada", first.help_text
      assert_equal 1, first.position
      assert_equal "CNPJ atualizado", second.reload.name
      assert_equal "Cartão atualizado", second.help_text
      assert_equal 0, second.position
    end

    test "update creates a nested item" do
      assert_difference("@template.items.count", 1) do
        patch settings_onboarding_template_url(@template), params: {
          onboarding_template: {
            name: @template.name,
            items_attributes: {
              "0" => {
                name: "Inscrição municipal",
                help_text: "Se disponível",
                position: 20
              }
            }
          }
        }
      end

      created = @template.items.order(:id).last
      assert_redirected_to settings_onboarding_template_url(@template)
      assert_equal "Inscrição municipal", created.name
      assert_equal "Se disponível", created.help_text
      assert_equal 20, created.position
    end

    test "update destroys a nested item" do
      item = @template.items.first

      assert_difference("@template.items.count", -1) do
        patch settings_onboarding_template_url(@template), params: {
          onboarding_template: {
            name: @template.name,
            items_attributes: {
              "0" => {
                id: item.id,
                name: item.name,
                help_text: item.help_text,
                position: item.position,
                _destroy: "1"
              }
            }
          }
        }
      end

      assert_redirected_to settings_onboarding_template_url(@template)
      assert_nil @template.items.find_by(id: item.id)
    end

    test "update renders index when invalid" do
      patch settings_onboarding_template_url(@template), params: {
        onboarding_template: {
          name: ""
        }
      }

      assert_response :unprocessable_entity
      assert_match "Editar template", response.body
      @template.reload
      assert_not_equal "", @template.name
    end
  end
end
