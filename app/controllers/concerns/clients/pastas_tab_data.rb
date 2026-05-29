# frozen_string_literal: true

module Clients
  module PastasTabData
    extend ActiveSupport::Concern

    private

    def load_folders_for_pastas_tab
      @folders = @client.folders.visible.with_documents_count.order(:name)
    end
  end
end
