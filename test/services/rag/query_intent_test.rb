# frozen_string_literal: true

require "test_helper"

class Rag::QueryIntentTest < ActiveSupport::TestCase
  test "classifies identity and capability questions" do
    assert_equal :meta_identity, Rag::QueryIntent.kind("Qual é seu nome?")
    assert_equal :meta_identity, Rag::QueryIntent.kind("Quem é você?")
    assert_equal :meta_capabilities, Rag::QueryIntent.kind("O que você pode fazer?")
    assert_equal :meta_capabilities, Rag::QueryIntent.kind("No que você pode ajudar?")
  end

  test "document questions stay as document" do
    assert_equal :document, Rag::QueryIntent.kind("Qual o prazo de rescisão no contrato?")
    assert_equal :document, Rag::QueryIntent.kind("Como funciona o reajuste no acordo?")
  end

  test "tabular requests are classified as tabular" do
    assert Rag::QueryIntent.tabular_request?("Gere os dados em uma tabela")
    assert_equal :tabular, Rag::QueryIntent.kind("Mostre em formato de tabela")
    assert Rag::QueryIntent.tabular_request?("preciso ver os dados em formato de tabela")
    assert_equal :tabular, Rag::QueryIntent.kind("preciso ver os dados em formato de tabela")
    assert Rag::QueryIntent.tabular_request?("mostre os dados em tabela")
    assert Rag::QueryIntent.tabular_request?("organize em colunas")
  end

  test "short follow-up after tabular error is tabular with context" do
    conv = conversations(:one)
    conv.messages.destroy_all
    conv.messages.create!(role: "user", content: "Mostre em formato de tabela", streaming: false)
    conv.messages.create!(
      role: "assistant",
      content: Rag::QueryIntent::TABULAR_ERROR_SNIPPET,
      streaming: false
    )
    follow_up = conv.messages.create!(role: "user", content: "gere", streaming: false)

    assert Rag::QueryIntent.tabular_follow_up?("gere")
    assert Rag::QueryIntent.tabular_request?(
      "gere",
      conversation: conv,
      user_message: follow_up
    )
    assert_equal "Mostre em formato de tabela\n\n(Continuação: gere)",
                 Rag::QueryIntent.tabular_effective_question(follow_up, conv)
  end

  test "gere without tabular context stays document" do
    conv = conversations(:one)
    conv.messages.destroy_all
    msg = conv.messages.create!(role: "user", content: "gere", streaming: false)

    assert_not Rag::QueryIntent.tabular_request?("gere", conversation: conv, user_message: msg)
    assert_equal :document, Rag::QueryIntent.kind("gere", conversation: conv, user_message: msg)
  end

  test "skip_title_generation for non-document intents" do
    assert Rag::QueryIntent.skip_title_generation?("Olá")
    assert Rag::QueryIntent.skip_title_generation?("Qual é seu nome?")
    assert_not Rag::QueryIntent.skip_title_generation?("Resumo das multas contratuais")
  end
end
