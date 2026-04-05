# frozen_string_literal: true

require "test_helper"

module Rag
  class RetrievalQueryTest < ActiveSupport::TestCase
    test "compose with no prior returns current only" do
      assert_equal "só isso", RetrievalQuery.compose([], "só isso")
    end

    test "compose joins prior and current under max length" do
      cur = "Quais os principais pontos deste artigo?"
      prior = ["Resuma o artigo Regulação do acesso aos serviços especializados no SUS."]
      out = RetrievalQuery.compose(prior, cur)
      assert_includes out, cur
      assert_includes out, "Regulação"
      assert_operator out.length, :<=, RetrievalQuery::MAX_TOTAL_CHARS
    end

    test "compose truncates prior to preserve current" do
      huge = "x" * 10_000
      cur = "pergunta curta"
      out = RetrievalQuery.compose([huge], cur)
      assert out.end_with?(cur)
      assert_operator out.length, :<=, RetrievalQuery::MAX_TOTAL_CHARS
    end
  end
end
