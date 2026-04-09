# frozen_string_literal: true

module Onboarding
  class SignupWithSubscription
    class Error < StandardError; end

    def initialize(checkout_creator: Billing::CreateCheckoutSession.new)
      @checkout_creator = checkout_creator
    end

    def call!(email:, password:, password_confirmation:, plan:, return_url:)
      raise Error, "Price ID do Stripe nao configurado" if Billing::StripeConfig.default_price_id.blank?

      ActiveRecord::Base.transaction do
        account = Account.create!(
          plan: plan,
          name: email.split("@").first,
          active: false,
          billing_status: :pending
        )

        user = User.new(
          account: account,
          email: email,
          password: password,
          password_confirmation: password_confirmation,
          role: :owner,
          active: false
        )
        user.save!

        subscription = Subscription.create!(
          account: account,
          plan: plan,
          status: :pending
        )

        checkout_session = @checkout_creator.call!(
          account: account,
          subscription: subscription,
          customer_email: user.email,
          return_url: return_url,
          price_id: Billing::StripeConfig.default_price_id
        )

        {
          account: account,
          user: user,
          subscription: subscription,
          checkout_session: checkout_session
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.join(", ")
    rescue Billing::StripeClient::Error => e
      raise Error, e.message
    end
  end
end
