# frozen_string_literal: true

class BankStatementsController < ApplicationController
  before_action :require_current_client!
  before_action :authorize_policy

  def index
    load_index_data
  end

  def create
    @bank_statement_import = current_client.bank_statement_imports.build(import_params)

    if @bank_statement_import.save
      ProcessBankStatementImportJob.perform_later(@bank_statement_import.id)
      redirect_to bank_statement_import_path(@bank_statement_import),
                  notice: "Extrato enviado. O processamento pode demorar alguns instantes."
    else
      load_index_data
      render :index, status: :unprocessable_entity
    end
  end

  private

  def authorize_policy
    case action_name
    when "index"
      authorize BankStatement
    when "create"
      authorize BankStatementImport, :create?
    end
  end

  def import_params
    params.expect(bank_statement_import: %i[file institution_id])
  end

  def load_index_data
    scope = current_client.bank_statements
      .includes(:institution, bank_statement_import: { file_attachment: :blob })
      .order(occurred_on: :desc, id: :desc)
    if params[:import_id].present?
      allowed = current_client.bank_statement_imports.where(id: params[:import_id]).pick(:id)
      scope = scope.where(bank_statement_import_id: allowed) if allowed
    end
    @bank_statements = scope.to_a
    @institution_tabs =
      @bank_statements
        .group_by { |s| s.institution&.name.presence || "—" }
        .sort_by { |name, _| name.to_s.downcase }
    @bank_statement_import ||= current_client.bank_statement_imports.build
    @institutions = Institution.alphabetical
    @institutions_json = @institutions.map { |i| { id: i.id, name: i.name } }.to_json
    @recent_imports = current_client.bank_statement_imports.includes(:bank_statements, :institution).order(created_at: :desc).limit(15)
  end
end
