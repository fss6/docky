# frozen_string_literal: true

require "test_helper"

module Collection
  class MessageRendererTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @client = clients(:alpha)
      ActsAsTenant.current_tenant = @account
    end

    test "replaces placeholders" do
      period = Date.current.beginning_of_month
      renderer = MessageRenderer.new(
        client: @client,
        period: period,
        period_record: nil,
        pending_items: [],
        upload_url: "https://example.com/upload",
        account: @account
      )

      result = renderer.render_template(
        "Oi {cliente}, faltam:\n{documentos_faltantes}\n{link_upload}",
        step: nil
      )

      assert_includes result, @client.name
      assert_includes result, "https://example.com/upload"
    end
  end
end
