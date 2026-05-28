# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "requires name" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "   ")
      assert_not c.valid?
    end
  end

  test "kept scope excludes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      assert_includes Client.kept, clients(:beta)
      assert_not_includes Client.kept, alpha
    end
  end

  test "filtered_by_index_params searches name email and tax_id digits" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      beta = clients(:beta)

      results = Client.filtered_by_index_params({ q: "Alpha" })
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params({ q: "11222333000181" })
      assert_includes results, alpha
      assert_not_includes results, beta

      results = Client.filtered_by_index_params({ q: "alpha@example.com" })
      assert_includes results, alpha
      assert_not_includes results, beta
    end
  end

  test "filtered_by_index_params includes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      results = Client.filtered_by_index_params({})
      assert_includes results, alpha
      assert_includes results, clients(:beta)
    end
  end

  test "filtered_by_index_params status active excludes archived clients" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner), status: :active)

      results = Client.filtered_by_index_params({ status: "active" })
      assert_not_includes results, alpha
      assert_includes results, clients(:beta)
    end
  end
end
