require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:administrator)
    @plan = plans(:one)
  end

  test "should get index" do
    get plans_url
    assert_response :success
  end

  test "should get new" do
    get new_plan_url
    assert_response :success
  end

  test "should create plan" do
    assert_difference("Plan.count") do
      post plans_url, params: { plan: { name: @plan.name, price: @plan.price, status: @plan.status } }
    end

    assert_redirected_to plan_url(Plan.last)
  end

  test "should show plan" do
    get plan_url(@plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_plan_url(@plan)
    assert_response :success
  end

  test "should update plan" do
    patch plan_url(@plan), params: { plan: { name: @plan.name, price: @plan.price, status: @plan.status } }
    assert_redirected_to plan_url(@plan)
  end

  test "should destroy plan" do
    disposable_plan = Plan.create!(name: "Plano descartável", price: 0)

    assert_difference("Plan.count", -1) do
      delete plan_url(disposable_plan)
    end

    assert_redirected_to plans_url
  end
end
