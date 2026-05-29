# frozen_string_literal: true

require "test_helper"

class FolderTest < ActiveSupport::TestCase
  test "empty_for_destroy? is true without documents" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      folder = Folder.create!(
        account: accounts(:one),
        client: clients(:alpha),
        name: "Pasta sem arquivos",
        visible: true
      )
      assert folder.empty_for_destroy?
    end
  end

  test "visible folder with documents cannot be destroyed" do
    ActsAsTenant.with_tenant(accounts(:one)) do
      folder = Folder.create!(
        account: accounts(:one),
        client: clients(:alpha),
        name: "Pasta com arquivos",
        visible: true
      )
      folder.documents.create!(
        account: accounts(:one),
        user: users(:owner),
        client: clients(:alpha),
        content: "teste",
        status: :pending
      )

      folder.destroy
      assert folder.persisted?
      assert_includes folder.errors[:base], I18n.t("folders.destroy_blocked_with_documents")
    end
  end
end
