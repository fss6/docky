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

  test "skip_title_generation for non-document intents" do
    assert Rag::QueryIntent.skip_title_generation?("Olá")
    assert Rag::QueryIntent.skip_title_generation?("Qual é seu nome?")
    assert_not Rag::QueryIntent.skip_title_generation?("Resumo das multas contratuais")
  end
end
