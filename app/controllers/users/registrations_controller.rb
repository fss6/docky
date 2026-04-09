# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout "devise"
  before_action :configure_sign_up_params, only: [:create]

  def new
    super do
      @selected_plan = selected_plan
    end
  end

  def create
    plan = selected_plan
    signup_payload = sign_up_params

    result = Onboarding::SignupWithSubscription.new.call!(
      email: signup_payload[:email],
      password: signup_payload[:password],
      password_confirmation: signup_payload[:password_confirmation],
      plan: plan,
      return_url: "#{request.base_url}#{after_checkout_users_registrations_path}?session_id={CHECKOUT_SESSION_ID}"
    )

    @checkout_client_secret = result[:checkout_session].client_secret
    @stripe_publishable_key = Billing::StripeConfig.publishable_key
    @selected_plan = plan
    flash.now[:notice] = "Conta criada. Finalize o pagamento para liberar seu acesso."

    render :checkout, status: :created
  rescue Onboarding::SignupWithSubscription::Error => e
    build_resource(signup_payload)
    clean_up_passwords(resource)
    set_minimum_password_length
    @selected_plan = plan
    resource.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def after_checkout
    session_id = params[:session_id]
    redirect_to new_user_session_path, alert: "Checkout nao encontrado." and return if session_id.blank?

    subscription = Subscription.find_by(stripe_checkout_session_id: session_id)
    redirect_to new_user_session_path, alert: "Assinatura nao encontrada." and return if subscription.blank?

    if subscription.active?
      redirect_to new_user_session_path, notice: "Pagamento confirmado. Voce ja pode entrar."
    else
      redirect_to new_user_session_path, alert: "Pagamento ainda em processamento. Tente novamente em instantes."
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:plan])
  end

  private

  def selected_plan
    plan_slug = params[:plan].presence || params.dig(:user, :plan).presence
    return Plan.find_by(name: "Pro") || Plan.first! if plan_slug.blank?

    Plan.where("LOWER(name) = ?", plan_slug.to_s.downcase).first || Plan.find_by(name: "Pro") || Plan.first!
  end
end
