# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "requires name" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "   ")
      assert_not c.valid?
    end
  end

  test "filtered_by_index_params searches name email and tax_id digits" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      beta = clients(:beta)

      results = Client.filtered_by_index_params(q: "Alpha")
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params(tax_id: "11222333000181")
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params(email: "alpha@example.com")
      assert_includes results, alpha
      assert_not_includes results, beta
    end
  end
end
