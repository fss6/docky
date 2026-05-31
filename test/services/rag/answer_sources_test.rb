# frozen_string_literal: true

require "test_helper"

class Rag::AnswerSourcesTest < ActiveSupport::TestCase
  def record_with(file:, page: 0, chunk_id: 1, document_id: 1)
    Object.new.tap do |r|
      r.define_singleton_method(:source_info) do
        { "file" => file, "page" => page, "chunk_id" => chunk_id, "document_id" => document_id }
      end
      r.define_singleton_method(:document_id) { document_id }
    end
  end

  test "keeps only sources matching Fonte citation" do
    r1 = record_with(file: "alpha.pdf", chunk_id: 1, document_id: 1)
    r2 = record_with(file: "beta.pdf", page: 2, chunk_id: 2, document_id: 2)

    answer = "Resumo.\n\n(Fonte: alpha.pdf · p. 1)"
    out = Rag::AnswerSources.source_infos_for_answer(records: [r1, r2], answer_text: answer)

    assert_equal 1, out.size
    assert_equal "alpha.pdf", out.first["file"]
  end

  test "falls back to first record when nothing matches answer or question" do
    r1 = record_with(file: "only.pdf", chunk_id: 9, document_id: 9)
    r2 = record_with(file: "other.pdf", page: 2, chunk_id: 10, document_id: 10)

    out = Rag::AnswerSources.source_infos_for_answer(
      records: [r1, r2],
      answer_text: "Sem citação.",
      question_text: "Qual o resumo geral?"
    )

    assert_equal 1, out.size
    assert_equal "only.pdf", out.first["file"]
  end

  test "filters by question token matching filename when answer has no citation" do
    compesa = record_with(
      file: "Compesa_60479810_2026-05.pdf",
      chunk_id: 11,
      document_id: 11
    )
    resumo_p0 = record_with(file: "RelatorioResumo.pdf", page: 0, chunk_id: 21, document_id: 21)
    resumo_p1 = record_with(file: "RelatorioResumo.pdf", page: 1, chunk_id: 22, document_id: 21)
    canada = record_with(file: "Copia de Canada - Display.docx", chunk_id: 31, document_id: 31)

    out = Rag::AnswerSources.source_infos_for_answer(
      records: [resumo_p0, resumo_p1, compesa, canada],
      answer_text: "Identificamos 25 faturas pendentes.",
      question_text: "Temos alguma pendência na compesa?"
    )

    assert_equal 1, out.size
    assert_equal "Compesa_60479810_2026-05.pdf", out.first["file"]
  end

  test "keeps filename match in answer when present" do
    compesa = record_with(file: "Compesa_60479810_2026-05.pdf", chunk_id: 11, document_id: 11)
    resumo = record_with(file: "RelatorioResumo.pdf", chunk_id: 21, document_id: 21)

    answer = "Sim, há uma conta da Compesa. Consulte Compesa_60479810_2026-05.pdf para detalhes."
    out = Rag::AnswerSources.source_infos_for_answer(
      records: [resumo, compesa],
      answer_text: answer,
      question_text: "Temos contas da compesa?"
    )

    assert_equal 1, out.size
    assert_equal "Compesa_60479810_2026-05.pdf", out.first["file"]
  end

  test "source_infos_from_records returns all deduped infos" do
    r1 = record_with(file: "alpha.pdf", chunk_id: 1, document_id: 1)
    r2 = record_with(file: "beta.pdf", page: 2, chunk_id: 2, document_id: 2)

    out = Rag::AnswerSources.source_infos_from_records([r1, r2])

    assert_equal 2, out.size
    assert_includes out.map { |h| h["file"] }, "alpha.pdf"
    assert_includes out.map { |h| h["file"] }, "beta.pdf"
  end
end
