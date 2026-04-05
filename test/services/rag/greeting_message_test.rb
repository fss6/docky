# frozen_string_literal: true

require "test_helper"

class Rag::GreetingMessageTest < ActiveSupport::TestCase
  test "detects common greetings" do
    assert Rag::GreetingMessage.only?("Olá")
    assert Rag::GreetingMessage.only?("oi")
    assert Rag::GreetingMessage.only?("Bom dia!")
    assert Rag::GreetingMessage.only?("  hello  ")
  end

  test "rejects substantive messages" do
    assert_not Rag::GreetingMessage.only?("Qual o valor do contrato?")
    assert_not Rag::GreetingMessage.only?("Olá, preciso do PDF do acordo")
  end
end
