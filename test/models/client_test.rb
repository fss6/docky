# frozen_string_literal: true

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "requires name" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      c = Client.new(name: "   ")
      assert_not c.valid?
    end
  end

  test "with_visibility scopes active archived and all" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      assert_includes Client.with_visibility("active"), clients(:beta)
      assert_not_includes Client.with_visibility("active"), alpha
      assert_includes Client.with_visibility("archived"), alpha
      assert_not_includes Client.with_visibility("archived"), clients(:beta)
      assert_includes Client.with_visibility("all"), alpha
      assert_includes Client.with_visibility("all"), clients(:beta)
      assert_includes Client.with_visibility(nil), clients(:beta)
      assert_not_includes Client.with_visibility(nil), alpha
    end
  end

  test "kept and archived_records scopes" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      alpha = clients(:alpha)
      alpha.update!(archived_at: Time.current, archived_by_user: users(:owner))

      assert_includes Client.kept, clients(:beta)
      assert_not_includes Client.kept, alpha
      assert_includes Client.archived_records, alpha
      assert_not_includes Client.archived_records, clients(:beta)
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
end
