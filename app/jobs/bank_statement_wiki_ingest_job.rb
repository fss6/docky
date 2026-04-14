# frozen_string_literal: true

# Gera/atualiza páginas na Base de Conhecimento (wiki) a partir do OCR do extrato.
class BankStatementWikiIngestJob < ApplicationJob
  queue_as :wiki_processing

  discard_on ActiveRecord::RecordNotFound

  def perform(bank_statement_import_id)
    import = BankStatementImport.find(bank_statement_import_id)
    ActsAsTenant.with_tenant(import.account) do
      Wiki::BankStatementIngestService.new(import, import.account).call
    end
  end
end
