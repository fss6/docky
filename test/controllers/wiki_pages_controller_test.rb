# frozen_string_literal: true

require "test_helper"

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    sign_in @user
  end

  test "index loads successfully" do
    get wiki_path

    assert_response :success
    assert_includes response.body, "Sobre a Base de Conhecimento"
  end

  test "should remove wiki page by slug" do
    wiki_page = WikiPage.create!(
      account: @user.account,
      slug: "base/remover-esta-pagina",
      title: "Remover esta página",
      page_type: "summary",
      content: "Conteúdo temporário"
    )

    assert_difference("WikiPage.count", -1) do
      delete wiki_page_path(slug: wiki_page.slug)
    end

    assert_redirected_to wiki_path
    follow_redirect!
    assert_includes response.body, "Página removida da base de conhecimento."
    assert_not WikiPage.exists?(wiki_page.id)
  end
end
