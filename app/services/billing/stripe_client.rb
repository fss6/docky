# frozen_string_literal: true

module Billing
  class StripeClient
    class Error < StandardError; end

    def create_customer!(email:, account_id:)
      Stripe::Customer.create(
        email: email,
        metadata: {
          account_id: account_id
        }
      )
    rescue Stripe::StripeError => e
      raise Error, e.message
    end

    def create_checkout_session!(customer_id:, price_id:, return_url:)
      Stripe::Checkout::Session.create(
        mode: "subscription",
        ui_mode: "elements",
        customer: customer_id,
        line_items: [
          {
            price: price_id,
            quantity: 1
          }
        ],
        return_url: return_url
      )
    rescue Stripe::StripeError => e
      raise Error, e.message
    end
  end
end
