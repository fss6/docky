# frozen_string_literal: true

module Onboarding
  class EnsureClientFolder
    def self.call(client:, account: client.account)
      new(client: client, account: account).call
    end

    def initialize(client:, account:)
      @client = client
      @account = account
    end

    def call
      folder = Folder.find_or_initialize_by(
        account: @account,
        client: @client,
        name: I18n.t("folders.onboarding.name")
      )
      folder.visible = true
      folder.save!
      folder
    end
  end
end
