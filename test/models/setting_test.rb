# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @setting = ActsAsTenant.with_tenant(@account) { @account.setting || @account.create_setting! }
  end

  test "requires link placeholder in whatsapp and email body templates" do
    @setting.upload_share_whatsapp_template = "Sem link"
    @setting.upload_share_email_body_template = "Também sem link"

    assert_not @setting.valid?
    assert_includes @setting.errors[:upload_share_whatsapp_template], "deve incluir {{link}}"
    assert_includes @setting.errors[:upload_share_email_body_template], "deve incluir {{link}}"
  end

  test "allows email subject without link placeholder" do
    @setting.upload_share_email_subject_template = "Assunto para {{nome_cliente}}"

    assert @setting.valid?
  end
end
