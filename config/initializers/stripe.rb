# frozen_string_literal: true

Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

module Billing
  module StripeConfig
    module_function

    def publishable_key
      ENV["STRIPE_PUBLISHABLE_KEY"]
    end

    def default_price_id
      ENV["STRIPE_PRICE_ID_PRO"]
    end

    def webhook_secret
      ENV["STRIPE_WEBHOOK_SECRET"]
    end
  end
end
