# frozen_string_literal: true

class InstitutionsController < ApplicationController
  before_action :set_institution, only: %i[show edit update destroy]
  before_action :authorize_policy

  def index
    @pagy, @institutions = pagy(Institution.alphabetical, limit: 10)
  end

  def show
  end

  def new
    @institution = Institution.new
  end

  def edit
  end

  def create
    @institution = Institution.new(institution_params.merge(system: false))

    respond_to do |format|
      if @institution.save
        format.html { redirect_to @institution, notice: "Instituição criada com sucesso." }
        format.json { render :show, status: :created, location: @institution }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @institution.update(institution_params)
        format.html { redirect_to @institution, notice: "Instituição actualizada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @institution }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @institution.bank_statement_imports.exists? || @institution.bank_statements.exists?
      redirect_to @institution,
                  alert: "Esta instituição está em uso em importações e não pode ser excluída.",
                  status: :see_other
      return
    end

    @institution.destroy!

    respond_to do |format|
      format.html { redirect_to institutions_path, notice: "Instituição excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def authorize_policy
    authorize(@institution || Institution)
  end

  def set_institution
    @institution = Institution.find(params.expect(:id))
  end

  def institution_params
    params.expect(institution: [:name])
  end
end
