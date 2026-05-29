# frozen_string_literal: true

require "test_helper"

class BankStatementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:owner)
  end

  test "index redirects to clients index" do
    get bank_statements_path

    assert_redirected_to clients_path
  end

  test "new redirects to clients index" do
    get new_bank_statement_path

    assert_redirected_to clients_path
  end

  test "create redirects to clients index" do
    post bank_statements_path, params: {
      bank_statement: {
        occurred_on: Date.current,
        amount: 10,
        transaction_type: :debit,
        description: "Teste"
      }
    }

    assert_redirected_to clients_path
  end
end
