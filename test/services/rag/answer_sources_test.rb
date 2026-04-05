# frozen_string_literal: true

require "test_helper"

class Rag::AnswerSourcesTest < ActiveSupport::TestCase
  test "keeps only sources matching Fonte citation" do
    r1 = Object.new
    def r1.source_info
      { "file" => "alpha.pdf", "page" => 1, "chunk_id" => 1, "document_id" => 1 }
    end
    r2 = Object.new
    def r2.source_info
      { "file" => "beta.pdf", "page" => 2, "chunk_id" => 2, "document_id" => 2 }
    end

    answer = "Resumo.\n\n(Fonte: alpha.pdf · p. 1)"
    out = Rag::AnswerSources.source_infos_for_answer(records: [r1, r2], answer_text: answer)

    assert_equal 1, out.size
    assert_equal "alpha.pdf", out.first["file"]
  end

  test "falls back to first record when nothing matches" do
    r1 = Object.new
    def r1.source_info
      { "file" => "only.pdf", "page" => 1, "chunk_id" => 9 }
    end

    out = Rag::AnswerSources.source_infos_for_answer(records: [r1], answer_text: "Sem citação.")

    assert_equal 1, out.size
    assert_equal "only.pdf", out.first["file"]
  end
end
