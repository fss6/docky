# frozen_string_literal: true

module Billing
  class CreateCheckoutSession
    def initialize(stripe_client: StripeClient.new)
      @stripe_client = stripe_client
    end

    def call!(account:, subscription:, customer_email:, return_url:, price_id:)
      customer_id = account.stripe_customer_id

      if customer_id.blank?
        customer = @stripe_client.create_customer!(
          email: customer_email,
          account_id: account.id
        )

        customer_id = customer.id
        account.update!(stripe_customer_id: customer_id)
      end

      session = @stripe_client.create_checkout_session!(
        customer_id: customer_id,
        price_id: price_id,
        return_url: return_url
      )

      subscription.update!(
        stripe_checkout_session_id: session.id,
        stripe_price_id: price_id
      )

      session
    end
  end
end
