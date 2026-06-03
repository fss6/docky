# frozen_string_literal: true

require "test_helper"

class CollectionSettingTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:two)
    ActsAsTenant.with_tenant(@account) do
      @setting = CollectionSetting.ensure_for!(@account)
    end
  end

  test "rejects max messages below 1" do
    @setting.max_messages_per_client_per_day = 0
    assert_not @setting.valid?
    assert_includes @setting.errors[:max_messages_per_client_per_day], "must be greater than 0"
  end

  test "rejects max messages above 10" do
    @setting.max_messages_per_client_per_day = 11
    assert_not @setting.valid?
    assert_includes @setting.errors[:max_messages_per_client_per_day], "must be less than or equal to 10"
  end

  test "accepts max messages within range" do
    @setting.max_messages_per_client_per_day = 3
    assert @setting.valid?
    assert @setting.save
  end

  test "requires timezone" do
    @setting.timezone = ""
    assert_not @setting.valid?
    assert @setting.errors[:timezone].present?
  end
end
