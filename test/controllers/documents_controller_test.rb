require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:one)
    @folder = @document.folder
  end

  test "should show document" do
    get document_url(@document)
    assert_response :success
  end

  test "should destroy document" do
    assert_difference("Document.count", -1) do
      delete document_url(@document)
    end

    assert_redirected_to client_path(
      @folder.client,
      aba: "pastas",
      period: Date.current.strftime("%Y-%m"),
      folder_id: @folder.id
    )
  end
end
