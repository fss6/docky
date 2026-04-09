# frozen_string_literal: true

module Webhooks
  class StripeController < ActionController::Base
    protect_from_forgery with: :null_session

    def create
      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers["HTTP_STRIPE_SIGNATURE"],
        Billing::StripeConfig.webhook_secret
      )

      return head :ok if ProcessedStripeEvent.exists?(event_id: event.id)

      ActiveRecord::Base.transaction do
        process_event(event)
        ProcessedStripeEvent.create!(event_id: event.id)
      end

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.warn("Stripe webhook rejeitado: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("Stripe webhook falhou: #{e.message}")
      head :unprocessable_entity
    end

    private

    def process_event(event)
      case event.type
      when "checkout.session.completed"
        handle_checkout_session_completed(event.data.object)
      when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
        handle_subscription_update(event.data.object)
      when "invoice.paid"
        handle_invoice_paid(event.data.object)
      when "invoice.payment_failed"
        handle_invoice_failed(event.data.object)
      end
    end

    def handle_checkout_session_completed(session)
      subscription = Subscription.find_by(stripe_checkout_session_id: session.id)
      return if subscription.blank?

      subscription.update!(
        stripe_subscription_id: session.subscription,
        status: "trialing"
      )
      subscription.account.update!(billing_status: "trialing", active: true)
      enable_account_users!(subscription.account)
    end

    def handle_subscription_update(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return if subscription.blank?

      mapped_status = map_status(stripe_subscription.status)
      subscription.update!(
        status: mapped_status,
        current_period_end: Time.zone.at(stripe_subscription.current_period_end),
        trial_ends_at: stripe_subscription.trial_end ? Time.zone.at(stripe_subscription.trial_end) : nil,
        canceled_at: stripe_subscription.canceled_at ? Time.zone.at(stripe_subscription.canceled_at) : nil
      )
      subscription.account.update!(billing_status: mapped_status, active: %w[trialing active].include?(mapped_status))
      enable_account_users!(subscription.account) if %w[trialing active].include?(mapped_status)
    end

    def handle_invoice_paid(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return if subscription.blank?

      subscription.update!(status: "active")
      subscription.account.update!(billing_status: "active", active: true)
      enable_account_users!(subscription.account)
    end

    def handle_invoice_failed(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return if subscription.blank?

      subscription.update!(status: "past_due")
      subscription.account.update!(billing_status: "past_due")
    end

    def map_status(stripe_status)
      case stripe_status
      when "trialing" then "trialing"
      when "active" then "active"
      when "past_due" then "past_due"
      when "incomplete" then "incomplete"
      when "canceled", "unpaid", "incomplete_expired"
        "canceled"
      else
        "pending"
      end
    end

    def enable_account_users!(account)
      account.users.update_all(active: true) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
