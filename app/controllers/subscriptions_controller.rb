class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: %i[ show edit update destroy ]
  before_action :authorize_policy

  # GET /subscriptions or /subscriptions.json
  def index
    @subscriptions = policy_scope(Subscription).includes(:account, :plan).order(created_at: :desc)
  end

  # GET /subscriptions/1 or /subscriptions/1.json
  def show
  end

  # GET /subscriptions/new
  def new
    @subscription = Subscription.new(status: :active)
  end

  # GET /subscriptions/1/edit
  def edit
  end

  # POST /subscriptions or /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to @subscription, notice: "Assinatura criada com sucesso." }
        format.json { render :show, status: :created, location: @subscription }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriptions/1 or /subscriptions/1.json
  def update
    respond_to do |format|
      if @subscription.update(subscription_params)
        format.html { redirect_to @subscription, notice: "Assinatura atualizada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @subscription }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1 or /subscriptions/1.json
  def destroy
    @subscription.destroy!

    respond_to do |format|
      format.html { redirect_to subscriptions_path, notice: "Assinatura excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def authorize_policy
      authorize Subscription
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.includes(:account, :plan).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.expect(subscription: [ :account_id, :plan_id, :status, :current_period_end, :trial_ends_at, :canceled_at ])
    end
end
