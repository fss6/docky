# frozen_string_literal: true

module Collection
  # Envia um dispatch de cobrança (email ou WhatsApp).
  class SendDispatchJob < ApplicationJob
    queue_as :mailers

    discard_on ActiveRecord::RecordNotFound

    retry_on Whatsapp::Client::Error, wait: :polynomially_longer, attempts: 3

    def perform(dispatch_id)
      dispatch = CollectionDispatch.find(dispatch_id)
      ActsAsTenant.with_tenant(dispatch.account) do
        Collection::SendDispatch.call(dispatch)
      end
    end
  end
end
