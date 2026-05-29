require "test_helper"

class AuditTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @user = users(:one)
  end

  test "stores user and account for folder updates" do
    folder = folders(:one)

    Audited.audit_class.as_user(@user) do
      ActsAsTenant.with_tenant(@account) do
        folder.update!(name: "Folder atualizado")
      end
    end

    audit = folder.audits.order(:created_at).last

    assert_equal "update", audit.action
    assert_equal @user, audit.user
    assert_equal @account.id, audit.account_id
  end
end
