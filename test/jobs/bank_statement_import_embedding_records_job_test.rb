# frozen_string_literal: true

require "test_helper"

class BankStatementImportEmbeddingRecordsJobTest < ActiveJob::TestCase
  setup do
    @import = BankStatementImport.create!(
      account: accounts(:one),
      client: clients(:alpha),
      institution: institutions(:nubank),
      status: :completed,
      metadata: {},
      ocr_text: "Linha um do extrato.\n\nLinha dois com mais texto para o chunk."
    )
    @import.file.attach(
      io: StringIO.new(Rails.root.join("test/fixtures/files/minimal.pdf").read),
      filename: "extrato.pdf",
      content_type: "application/pdf"
    )
  end

  test "cria chunks e invoca Embed" do
    EmbeddingRecords::Embed.stub :call, ->(_records) { } do
      BankStatementImportEmbeddingRecordsJob.perform_now(@import.id)
    end

    @import.reload
    assert_predicate @import.embedding_records, :any?
    assert @import.embedding_records.first.content.present?
  end
end
