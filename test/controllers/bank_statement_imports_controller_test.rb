# frozen_string_literal: true

require "test_helper"

class BankStatementImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @client = clients(:alpha)
  end

  test "show redirects to clients index" do
    import = BankStatementImport.create!(
      account: accounts(:one),
      client: @client,
      institution: institutions(:nubank),
      status: :completed,
      metadata: {}
    )

    get bank_statement_import_path(import)

    assert_redirected_to clients_path
  end

  test "original redirects to clients index" do
    import = BankStatementImport.create!(
      account: accounts(:one),
      client: @client,
      institution: institutions(:nubank),
      status: :completed,
      metadata: {}
    )

    get original_bank_statement_import_path(import)

    assert_redirected_to clients_path
  end
end
