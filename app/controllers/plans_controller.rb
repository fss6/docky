class PlansController < ApplicationController
  before_action :set_plan, only: %i[ show edit update destroy ]
  before_action :authorize_policy

  # GET /plans or /plans.json
  def index
    authorize Plan
    @plans = Plan.all
  end

  # GET /plans/1 or /plans/1.json
  def show
  end

  # GET /plans/new
  def new
    @plan = Plan.new
  end

  # GET /plans/1/edit
  def edit
  end

  # POST /plans or /plans.json
  def create
    @plan = Plan.new(plan_params)

    respond_to do |format|
      if @plan.save
        format.html { redirect_to @plan, notice: "Plano criado com sucesso." }
        format.json { render :show, status: :created, location: @plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plans/1 or /plans/1.json
  def update
    respond_to do |format|
      if @plan.update(plan_params)
        format.html { redirect_to @plan, notice: "Plano atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plans/1 or /plans/1.json
  def destroy
    @plan.destroy!

    respond_to do |format|
      format.html { redirect_to plans_path, notice: "Plano excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def authorize_policy
      authorize Plan
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def plan_params
      params.expect(plan: [ :name, :price, :status ])
    end
end
