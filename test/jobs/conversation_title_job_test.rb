# frozen_string_literal: true

require "test_helper"

class ConversationTitleJobTest < ActiveSupport::TestCase
  test "sets title from generator on first user message" do
    conv = conversations(:one)
    conv.update!(title: Conversation::DEFAULT_TITLE)
    msg = messages(:one)

    Conversations::TitleGenerator.stub(:generate, "Título gerado pela IA") do
      ConversationTitleJob.perform_now(conv.id, msg.id)
    end

    assert_equal "Título gerado pela IA", conv.reload.title
  end

  test "does nothing when title was already customized" do
    conv = conversations(:one)
    conv.update!(title: "Meu título manual")
    msg = messages(:one)

    Conversations::TitleGenerator.stub(:generate, "Não deve usar") do
      ConversationTitleJob.perform_now(conv.id, msg.id)
    end

    assert_equal "Meu título manual", conv.reload.title
  end

  test "does not set title for meta questions like name" do
    conv = conversations(:one)
    conv.update!(title: Conversation::DEFAULT_TITLE)
    conv.messages.destroy_all
    msg = conv.messages.create!(role: "user", content: "Qual é seu nome?", streaming: false)

    Conversations::TitleGenerator.stub(:generate, "Não deve usar") do
      ConversationTitleJob.perform_now(conv.id, msg.id)
    end

    assert_equal Conversation::DEFAULT_TITLE, conv.reload.title
  end

  test "does not set title when message is greeting-only" do
    conv = conversations(:one)
    conv.update!(title: Conversation::DEFAULT_TITLE)
    conv.messages.destroy_all
    msg = conv.messages.create!(role: "user", content: "Olá", streaming: false)

    Conversations::TitleGenerator.stub(:generate, "Não deve usar") do
      ConversationTitleJob.perform_now(conv.id, msg.id)
    end

    assert_equal Conversation::DEFAULT_TITLE, conv.reload.title
  end

  test "sets title from a later message when first was only a greeting" do
    account = accounts(:one)
    user = users(:one)
    conv = Conversation.create!(account: account, user: user, title: Conversation::DEFAULT_TITLE)
    conv.messages.create!(role: "user", content: "Olá", streaming: false)
    m2 = conv.messages.create!(role: "user", content: "Prazo de rescisão no contrato", streaming: false)

    Conversations::TitleGenerator.stub(:generate, "Rescisão contratual") do
      ConversationTitleJob.perform_now(conv.id, m2.id)
    end

    assert_equal "Rescisão contratual", conv.reload.title
  end
end
