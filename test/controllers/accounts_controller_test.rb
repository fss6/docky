require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:administrator)
    @account = accounts(:one)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_account_url
    assert_response :success
  end

  test "should create account" do
    assert_difference("Account.count") do
      post accounts_url, params: { account: { active: @account.active, description: @account.description, name: @account.name, plan_id: @account.plan_id } }
    end

    assert_redirected_to account_url(Account.last)
  end

  test "should show account" do
    get account_url(@account)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "should update account" do
    patch account_url(@account), params: { account: { active: @account.active, description: @account.description, name: @account.name, plan_id: @account.plan_id } }
    assert_redirected_to account_url(@account)
  end

  test "should destroy account" do
    disposable_plan = Plan.create!(name: "Plano descartável", price: 0)
    disposable_account = Account.create!(name: "Conta descartável", plan: disposable_plan, active: false)

    assert_difference("Account.count", -1) do
      delete account_url(disposable_account)
    end

    assert_redirected_to accounts_url
  end
end
