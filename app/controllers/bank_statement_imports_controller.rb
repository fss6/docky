# frozen_string_literal: true

class BankStatementImportsController < ApplicationController
  before_action :redirect_to_clients_index
  before_action :set_import
  before_action :authorize_policy

  def show
  end

  def original
    unless @bank_statement_import.file.attached?
      redirect_to bank_statement_import_path(@bank_statement_import),
                  alert: "Ficheiro PDF não disponível."
      return
    end

    redirect_to rails_blob_path(@bank_statement_import.file, disposition: "inline")
  end

  private

  def set_import
    @bank_statement_import = current_client.bank_statement_imports
      .includes(:institution, bank_statements: :institution)
      .find(params.expect(:id))
  end

  def authorize_policy
    authorize @bank_statement_import, :show?
  end
end
