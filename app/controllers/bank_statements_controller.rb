# frozen_string_literal: true

class BankStatementsController < ApplicationController
  before_action :require_current_client!
  before_action :set_bank_statement, only: %i[edit update destroy]
  before_action :authorize_policy

  def index
    load_index_data
  end

  def new
    @bank_statement = current_client.bank_statements.build(transaction_type: :debit, occurred_on: Date.current)
    load_form_data
  end

  def create
    @bank_statement = current_client.bank_statements.build(bank_statement_params)
    assign_import_dependencies(@bank_statement)

    if @bank_statement.save
      redirect_to bank_statements_path, notice: "Lançamento criado com sucesso."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    @bank_statement.assign_attributes(bank_statement_params)
    assign_import_dependencies(@bank_statement)

    if @bank_statement.save
      redirect_to bank_statements_path, notice: "Lançamento atualizado com sucesso."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bank_statement.destroy!
    redirect_to bank_statements_path, notice: "Lançamento removido com sucesso."
  end

  private

  def authorize_policy
    case action_name
    when "index"
      authorize BankStatement
    when "new", "create"
      authorize BankStatement, :create?
    when "edit", "update"
      authorize @bank_statement, :update?
    when "destroy"
      authorize @bank_statement, :destroy?
    end
  end

  def set_bank_statement
    @bank_statement = current_client.bank_statements.find(params.expect(:id))
  end

  def bank_statement_params
    params.expect(bank_statement: %i[bank_statement_import_id occurred_on description transaction_type amount possible_duplicate])
  end

  def assign_import_dependencies(statement)
    return if statement.bank_statement_import_id.blank?

    import = current_client.bank_statement_imports.find_by(id: statement.bank_statement_import_id)
    return unless import

    statement.bank_statement_import = import
    statement.client = current_client
    statement.institution = import.institution
  end

  def load_form_data
    @import_options = current_client.bank_statement_imports
      .includes(:institution)
      .order(created_at: :desc)
      .map do |imp|
        institution_name = imp.institution&.name.presence || "Sem instituição"
        ["##{imp.id} · #{institution_name} · #{I18n.l(imp.created_at.to_date)}", imp.id]
      end
  end

  def load_index_data
    scope = current_client.bank_statements
      .includes(:institution, bank_statement_import: { file_attachment: :blob })
      .order(occurred_on: :desc, id: :desc)
    if params[:import_id].present?
      allowed = current_client.bank_statement_imports.where(id: params[:import_id]).pick(:id)
      scope = scope.where(bank_statement_import_id: allowed) if allowed
    end

    if params[:institution_id].present?
      scope = scope.where(institution_id: params[:institution_id])
    end
    if params[:transaction_type].present?
      scope = scope.where(transaction_type: params[:transaction_type])
    end
    if params[:occurred_from].present?
      scope = scope.where("occurred_on >= ?", params[:occurred_from])
    end
    if params[:occurred_to].present?
      scope = scope.where("occurred_on <= ?", params[:occurred_to])
    end

    @pagy, @bank_statements = pagy(scope, limit: 10)
    @institution_filter_options = Institution.alphabetical.pluck(:name, :id)
    @transaction_type_filter_options = [
      [I18n.t("activerecord.enums.bank_statement.transaction_type.credit", default: "Crédito"), "credit"],
      [I18n.t("activerecord.enums.bank_statement.transaction_type.debit", default: "Débito"), "debit"]
    ]
  end
end
