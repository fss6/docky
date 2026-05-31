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
      assert_match I18n.t("settings.onboarding_templates.actions.new"), response.body
      assert_match I18n.t("settings.onboarding_templates.origin.system"), response.body
    end

    test "member can index and show but not create edit update or destroy" do
      sign_out :user
      sign_in users(:three)

      get settings_onboarding_templates_url
      assert_response :success
      assert_no_match(/Editar/, response.body)
      assert_no_match(I18n.t("settings.onboarding_templates.actions.new"), response.body)

      get settings_onboarding_template_url(@template)
      assert_response :success
      assert_no_match(/Editar/, response.body)

      get new_settings_onboarding_template_url
      assert_redirected_to authenticated_root_path
      assert_equal I18n.t("errors.not_authorized"), flash[:alert]

      assert_no_difference("@account.onboarding_templates.count") do
        post settings_onboarding_templates_url, params: {
          onboarding_template: { name: "Template não autorizado" }
        }
      end
      assert_redirected_to authenticated_root_path

      get edit_settings_onboarding_template_url(@template)
      assert_redirected_to authenticated_root_path
      assert_equal I18n.t("errors.not_authorized"), flash[:alert]

      patch settings_onboarding_template_url(@template), params: {
        onboarding_template: { name: "Tentativa não autorizada" }
      }
      assert_redirected_to authenticated_root_path
      assert_not_equal "Tentativa não autorizada", @template.reload.name

      assert_no_difference("@account.onboarding_templates.count") do
        delete settings_onboarding_template_url(@template)
      end
      assert_redirected_to authenticated_root_path
    end

    test "create redirects to edit with generated kind" do
      assert_difference("@account.onboarding_templates.count", 1) do
        post settings_onboarding_templates_url, params: {
          onboarding_template: { name: "Clínica odontológica" }
        }
      end

      created = @account.onboarding_templates.order(:id).last
      assert_redirected_to edit_settings_onboarding_template_path(created)
      assert_equal I18n.t("settings.onboarding_templates.flashes.created"), flash[:notice]
      assert_equal "Clínica odontológica", created.name
      assert_equal "clinica_odontologica", created.kind
      assert_not created.system?
    end

    test "create renders new when invalid" do
      assert_no_difference("@account.onboarding_templates.count") do
        post settings_onboarding_templates_url, params: {
          onboarding_template: { name: "" }
        }
      end

      assert_response :unprocessable_entity
      assert_match I18n.t("settings.onboarding_templates.new.title"), response.body
    end

    test "destroy removes custom template" do
      custom = @account.onboarding_templates.create!(name: "Template temporário", system: false)

      assert_difference("@account.onboarding_templates.count", -1) do
        delete settings_onboarding_template_url(custom)
      end

      assert_redirected_to settings_onboarding_templates_url
      assert_equal I18n.t("settings.onboarding_templates.flashes.destroyed"), flash[:notice]
      assert_nil @account.onboarding_templates.find_by(id: custom.id)
    end

    test "destroy removes default template" do
      assert_difference("@account.onboarding_templates.count", -1) do
        delete settings_onboarding_template_url(@template)
      end

      assert_redirected_to settings_onboarding_templates_url
      assert_nil @account.onboarding_templates.find_by(id: @template.id)
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
