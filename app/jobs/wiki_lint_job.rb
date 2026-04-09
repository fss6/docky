# frozen_string_literal: true

class WikiLintJob < ApplicationJob
  queue_as :wiki_processing

  discard_on ActiveRecord::RecordNotFound

  def perform(account_id)
    account = Account.find(account_id)
    Wiki::LintService.new(account).call
  end
end
