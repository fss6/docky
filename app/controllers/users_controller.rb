class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy enable ]
  before_action :authorize_policy

  # GET /users or /users.json
  def index
    @users = policy_scope(User).includes(:account).order(:name)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new(active: true)
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params.merge(account: current_tenant))
    @user.assign_initial_random_password! if @user.password.blank?

    respond_to do |format|
      if @user.save
        @user.send_reset_password_instructions
        format.html { redirect_to @user, notice: t("users.flashes.created") }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    @user.updated_by = current_user

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: t("users.flashes.updated"), status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.update!(active: false)

    respond_to do |format|
      format.html do
        redirect_back fallback_location: user_path(@user),
                      notice: t("users.flashes.disabled"),
                      status: :see_other
      end
      format.json { head :no_content }
    end
  end

  # POST /users/1/enable
  def enable
    @user.update!(active: true)

    respond_to do |format|
      format.html do
        redirect_back fallback_location: user_path(@user),
                      notice: t("users.flashes.enabled"),
                      status: :see_other
      end
      format.json { render :show, status: :ok, location: @user }
    end
  end

  private
    def authorize_policy
      if @user
        authorize @user
      else
        authorize User
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.includes(:account).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def user_params
      permitted_params = params.require(:user).permit(:email, :name, :active, :role)

      return permitted_params if permitted_params[:role].blank?

      permitted_roles.include?(permitted_params[:role]) ? permitted_params : permitted_params.except(:role)
    end

    def permitted_roles
      return User.roles.keys if current_user.role_administrator?

      User.roles.keys - [ "administrator" ]
    end
end
