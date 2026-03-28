require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
  end

  test "visiting the index" do
    visit accounts_url
    assert_selector "h1", text: "Contas"
  end

  test "should create account" do
    visit accounts_url
    click_on "Nova conta"

    fill_in "Nome", with: @account.name
    select @account.plan_id.to_s, from: "Plano"
    check "Conta ativa" if @account.active
    fill_in "Descrição", with: @account.description
    click_on "Criar conta"

    assert_text "Conta criada com sucesso."
    click_on "Voltar"
  end

  test "should update Account" do
    visit account_url(@account)
    click_on "Editar", match: :first

    fill_in "Nome", with: @account.name
    select @account.plan_id.to_s, from: "Plano"
    check "Conta ativa" if @account.active
    fill_in "Descrição", with: @account.description
    click_on "Atualizar conta"

    assert_text "Conta atualizada com sucesso."
    click_on "Voltar"
  end

  test "should destroy Account" do
    visit account_url(@account)
    accept_confirm do
      click_on "Excluir conta", match: :first
    end

    assert_text "Conta excluída com sucesso."
  end
end
