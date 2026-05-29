# frozen_string_literal: true

module Onboarding
  class ReceiveDocument
    def self.call(item:, file:, client:, account:, upload_owner_user: nil)
      new(item: item, file: file, client: client, account: account, upload_owner_user: upload_owner_user).call
    end

    def initialize(item:, file:, client:, account:, upload_owner_user:)
      @item = item
      @file = file
      @client = client
      @account = account
      @upload_owner_user = upload_owner_user
    end

    def call
      folder = ensure_client_folder!

      document = folder.documents.build
      document.file.attach(@file)
      document.assign_attributes(
        account_id: @account.id,
        user_id: @upload_owner_user&.id,
        status: :pending
      )
      document.metadata = {
        "upload_source" => "onboarding_portal",
        "onboarding_item_id" => @item.id
      }

      document.save!

      AuditEvents::RecordDocumentReceived.call(
        document: document,
        user: @upload_owner_user
      )

      MarkItemReceived.call(item: @item, document: document, account: @account)
      Documents::ProcessAfterUpload.call(document: document, file_io: @file)

      document
    end

    private

    def ensure_client_folder!
      folder = @client.folders.visible.first
      return folder if folder

      Folder.create!(
        account: @account,
        client: @client,
        name: "Documentos",
        visible: true
      )
    end
  end
end
