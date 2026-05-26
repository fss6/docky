# frozen_string_literal: true

require "test_helper"

class BankStatementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
    @client = clients(:alpha)
    patch current_client_url, params: { client_id: @client.id }
  end

  test "index" do
    get bank_statements_path
    assert_response :success
  end

  test "index with import_id filter" do
    import = BankStatementImport.create!(
      account: accounts(:one),
      client: @client,
      institution: institutions(:nubank),
      status: :completed,
      metadata: {}
    )
    BankStatement.create!(
      account: accounts(:one),
      client: @client,
      bank_statement_import: import,
      institution: institutions(:nubank),
      occurred_on: Date.new(2026, 2, 1),
      amount: 2.0,
      transaction_type: :debit,
      description: "Y"
    )
    get bank_statements_path(import_id: import.id)
    assert_response :success
  end

  test "redirects without current client" do
    patch current_client_url, params: { client_id: "" }
    get bank_statements_path
    assert_redirected_to clients_path
  end

  test "create saves bank statement and redirects" do
    import = BankStatementImport.create!(
      account: accounts(:one),
      client: @client,
      institution: institutions(:nubank),
      status: :completed,
      metadata: {}
    )

    assert_difference("BankStatement.count", 1) do
      post bank_statements_path, params: {
        bank_statement: {
          bank_statement_import_id: import.id,
          occurred_on: Date.current,
          amount: 10,
          transaction_type: :debit,
          description: "Teste"
        }
      }
    end

    assert_redirected_to bank_statements_path
  end
end
