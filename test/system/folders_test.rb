require "application_system_test_case"

class FoldersTest < ApplicationSystemTestCase
  setup do
    @folder = folders(:one)
  end

  test "visiting the index" do
    visit folders_url
    assert_selector "h1", text: "Pastas"
  end

  test "should create folder" do
    visit folders_url
    click_on "Nova pasta"

    select @folder.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @folder.name
    click_on "Criar pasta"

    assert_text "Pasta criada com sucesso."
    click_on "Voltar"
  end

  test "should update Folder" do
    visit folder_url(@folder)
    click_on "Editar", match: :first

    select @folder.account_id.to_s, from: "Conta"
    fill_in "Nome", with: @folder.name
    click_on "Atualizar pasta"

    assert_text "Pasta atualizada com sucesso."
    click_on "Voltar"
  end

  test "should destroy Folder" do
    visit folder_url(@folder)
    accept_confirm do
      click_on "Excluir pasta", match: :first
    end

    assert_text "Pasta excluída com sucesso."
  end
end
