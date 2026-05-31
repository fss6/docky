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

  test "show highlights chunk when highlight_chunk param present" do
    account = @document.account
    @document.update!(content: nil, summary: nil)
    chunk = EmbeddingRecord.create!(
      account: account,
      recordable: @document,
      document_id: @document.id,
      content: "Trecho para destacar no OCR.",
      embedding: Array.new(1536, 0.0),
      metadata: { "page" => 1, "chunk_index" => 0 }
    )

    get document_url(@document, highlight_chunk: chunk.id, page: 1)

    assert_response :success
    assert_includes response.body, %(id="chunk-#{chunk.id}")
    assert_includes response.body, "data-document-highlight-target"
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
