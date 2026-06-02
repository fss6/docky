# frozen_string_literal: true

require "test_helper"

module Collection
  class UnsubscribeTokenTest < ActiveSupport::TestCase
    test "generate and verify" do
      client = clients(:alpha)
      token = UnsubscribeToken.generate(client)
      assert_equal client, UnsubscribeToken.verify(token)
    end

    test "invalid token returns nil" do
      assert_nil UnsubscribeToken.verify("invalid")
    end
  end
end
