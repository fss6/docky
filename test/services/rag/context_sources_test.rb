# frozen_string_literal: true

require "test_helper"

class Rag::ContextSourcesTest < ActiveSupport::TestCase
  test "build_from_records groups document chunks with pages and excerpts" do
    account = accounts(:one)
    document = documents(:one)
    record = EmbeddingRecord.create!(
      account: account,
      recordable: document,
      document_id: document.id,
      content: "Saldo acumulado de créditos de energia referente ao mês de abril.",
      embedding: Array.new(1536, 0.0),
      metadata: { "page" => 0, "chunk_index" => 0 }
    )

    groups = Rag::ContextSources.build_from_records([record])

    assert_equal 1, groups.size
    group = groups.first
    assert_equal document.id, group["document_id"]
    assert_includes group["pages"], 0
    assert_equal 1, group["chunks"].size
    assert_includes group["chunks"].first["excerpt"], "Saldo acumulado"
  end
end
