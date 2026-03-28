require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Usuários"
  end

  test "should create user" do
    visit users_url
    click_on "Novo usuário"

    select @user.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @user.name
    fill_in "E-mail", with: @user.email
    fill_in "Função", with: @user.role
    check "Usuário ativo" if @user.active
    click_on "Criar usuário"

    assert_text "Usuário criado com sucesso."
    click_on "Voltar"
  end

  test "should update User" do
    visit user_url(@user)
    click_on "Editar", match: :first

    select @user.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @user.name
    fill_in "E-mail", with: @user.email
    fill_in "Função", with: @user.role
    check "Usuário ativo" if @user.active
    click_on "Atualizar usuário"

    assert_text "Usuário atualizado com sucesso."
    click_on "Voltar"
  end

  test "should destroy User" do
    visit user_url(@user)
    accept_confirm do
      click_on "Excluir usuário", match: :first
    end

    assert_text "Usuário excluído com sucesso."
  end
end
