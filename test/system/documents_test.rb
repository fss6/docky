require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  setup do
    @document = documents(:one)
    @folder = @document.folder
  end

  test "visiting folder documents index" do
    visit folder_documents_url(@folder)
    assert_selector "h1", text: "Documentos"
  end

  test "upload from documents list" do
    visit folder_documents_url(@folder)

    find('input[name="document[file]"]', visible: :all).attach_file(
      Rails.root.join("test/fixtures/files/sample.txt")
    )

    assert_text "Arquivo enviado com sucesso", wait: 5
  end

  test "should destroy document" do
    visit document_url(@document)
    click_on "Excluir documento", match: :first

    within "dialog[open]" do
      click_on "Excluir documento"
    end

    assert_text "Documento excluído com sucesso"
  end
end
