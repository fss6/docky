# frozen_string_literal: true

require "test_helper"

module Settings
  class PermissionsControllerTest < ActionDispatch::IntegrationTest
    test "owner can view and update permissions" do
      sign_in users(:owner)

      get settings_permissions_path
      assert_response :success

      patch settings_permissions_path, params: {
        grants: {
          "users_manage" => "1",
          "audit_read" => "1"
        }
      }

      assert_redirected_to settings_permissions_path
      grant = accounts(:one).permission_grants.find_by!(capability_key: "users.manage")
      assert grant.granted?
    end

    test "member cannot access permissions" do
      sign_in users(:three)

      get settings_permissions_path
      assert_redirected_to authenticated_root_path
      assert_equal I18n.t("errors.not_authorized"), flash[:alert]
    end
  end
end
