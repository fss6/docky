require "application_system_test_case"

class GroupsTest < ApplicationSystemTestCase
  setup do
    @group = groups(:one)
  end

  test "visiting the index" do
    visit groups_url
    assert_selector "h1", text: "Grupos"
  end

  test "should create group" do
    visit groups_url
    click_on "Novo grupo"

    select @group.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @group.name
    click_on "Criar grupo"

    assert_text "Grupo criado com sucesso."
    click_on "Voltar"
  end

  test "should update Group" do
    visit group_url(@group)
    click_on "Editar", match: :first

    select @group.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @group.name
    click_on "Atualizar grupo"

    assert_text "Grupo atualizado com sucesso."
    click_on "Voltar"
  end

  test "should destroy Group" do
    visit group_url(@group)
    accept_confirm do
      click_on "Excluir grupo", match: :first
    end

    assert_text "Grupo excluído com sucesso."
  end
end
