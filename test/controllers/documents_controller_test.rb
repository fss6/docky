require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:one)
    @folder = @document.folder
  end

  test "should get index" do
    get folder_documents_url(@folder)
    assert_response :success
  end

  test "should create document with file only" do
    file = fixture_file_upload("files/sample.txt", "text/plain")
    assert_difference("Document.count") do
      assert_enqueued_jobs 1, only: DocumentOcrJob do
        post folder_documents_url(@folder), params: { document: { file: file } }
      end
    end

    assert_redirected_to folder_documents_url(@folder)
    doc = Document.order(:created_at).last
    assert_equal @folder.id, doc.folder_id
    assert_equal @folder.account_id, doc.account_id
    assert_equal @folder.account.users.order(:id).first.id, doc.user_id
    assert_equal "pending", doc.status
    assert doc.file.attached?
  end

  test "should create document and redirect to folder when upload_context is folder" do
    file = fixture_file_upload("files/sample.txt", "text/plain")
    assert_difference("Document.count") do
      assert_enqueued_jobs 1, only: DocumentOcrJob do
        post folder_documents_url(@folder), params: {
          upload_context: "folder",
          document: { file: file }
        }
      end
    end

    assert_redirected_to folder_url(@folder)
  end

  test "should show document" do
    get document_url(@document)
    assert_response :success
  end

  test "should destroy document" do
    assert_difference("Document.count", -1) do
      delete document_url(@document)
    end

    assert_redirected_to folder_documents_url(@folder)
  end
end
