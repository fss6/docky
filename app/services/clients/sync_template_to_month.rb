# frozen_string_literal: true

module Clients
  class SyncTemplateToMonth
    def self.call(client:, checklist:, account: ActsAsTenant.current_tenant)
      new(client: client, checklist: checklist, account: account).call
    end

    def initialize(client:, checklist:, account:)
      @client = client
      @checklist = checklist
      @account = account
    end

    def call
      templates = @client.client_checklist_items.active_only
      existing_template_ids = @checklist.items.where.not(client_checklist_item_id: nil).pluck(:client_checklist_item_id)

      templates.each do |template|
        next if existing_template_ids.include?(template.id)

        @checklist.items.create!(
          client_checklist_item: template,
          name_snapshot: template.name,
          match_terms: template.match_terms,
          state: :pending
        )
      end
    end
  end
end
