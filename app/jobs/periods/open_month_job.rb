# frozen_string_literal: true

module Periods
  # Abre o período do mês para clientes ativos que ainda não o possuem.
  class OpenMonthJob < ApplicationJob
    queue_as :default

    def perform(reference_date = nil)
      month = (reference_date || Time.zone.today).to_date.beginning_of_month

      Client.kept.find_each do |client|
        ActsAsTenant.with_tenant(client.account) do
          next if client.archived?
          next if Period.exists?(account: client.account, client: client, period: month)

          Periods::OpenForClient.call(
            client: client,
            period: month,
            account: client.account
          )
        end
      end
    end
  end
end
