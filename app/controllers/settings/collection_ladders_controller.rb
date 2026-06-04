# frozen_string_literal: true

module Settings
  class CollectionLaddersController < ApplicationController
    before_action :set_collection_setting
    before_action :load_steps
    before_action :authorize_policy
    before_action :assign_channel_config, only: %i[edit update preview_email send_test_email]
    before_action :load_sample_clients, only: %i[edit update preview_email send_test_email]

    def edit
      @open_email_step_id = params[:open_email].presence&.to_i
      @open_whatsapp_step_id = params[:open_whatsapp].presence&.to_i
    end

    def preview_email
      step, client, templates = playground_context!
      return if performed?

      @preview = Collection::EmailPlayground.preview(
        step: step,
        client: client,
        account: current_user.account,
        subject_template: templates[:email_subject_template],
        body_template: templates[:email_body_template],
        recipient: current_user.email
      )
      render partial: "settings/collection_ladders/email_playground_preview",
             locals: { preview: @preview, step: step, error: nil },
             layout: false
    rescue StandardError => e
      step ||= @steps.find { |s| s.id == params[:step_id].to_i }
      render partial: "settings/collection_ladders/email_playground_preview",
             locals: { preview: nil, step: step, error: e.message },
             layout: false
    end

    def send_test_email
      step, client, templates = playground_context!
      return if performed?

      result = Collection::EmailPlayground.send_test!(
        step: step,
        client: client,
        account: current_user.account,
        subject_template: templates[:email_subject_template],
        body_template: templates[:email_body_template],
        recipient: current_user.email
      )

      if result.success
        redirect_to edit_settings_collection_ladder_path(open_email: step.id),
                    notice: "E-mail de teste enviado para #{current_user.email}."
      else
        redirect_to edit_settings_collection_ladder_path(open_email: step.id),
                    alert: result.error
      end
    end

    def update
      case params[:section]
      when "behavior"
        update_behavior
      when "step_email"
        update_step_email
      when "step_whatsapp"
        update_step_whatsapp
      else
        head :bad_request
      end
    end

    private

    def set_collection_setting
      @collection_setting = CollectionSetting.ensure_for!(current_user.account)
    end

    def load_steps
      @steps = current_user.account.collection_steps.ordered
    end

    def load_sample_clients
      @sample_clients = current_user.account.clients.kept.where(status: :active).order(:name).limit(50)
    end

    def playground_context!
      step = find_step_for_update!
      return [ nil, nil, nil ] if performed?

      client = @sample_clients.find { |c| c.id == params[:client_id].to_i }
      unless client
        head :unprocessable_entity
        return [ nil, nil, nil ]
      end

      attrs = step_attrs_for(step.id)
      if attrs.nil?
        head :bad_request
        return [ nil, nil, nil ]
      end

      templates = email_step_params(attrs)
      [ step, client, templates ]
    end

    def authorize_policy
      authorize(current_user.account.setting || Setting.new(account: current_user.account), :update?)
    end

    def assign_channel_config
      @email_configured = ActionMailerDelivery.enabled?
      @whatsapp_configured = Whatsapp::PlatformConfig.configured?
    end

    def update_behavior
      if @collection_setting.update(collection_setting_params)
        redirect_to edit_settings_collection_ladder_path, notice: "Comportamento atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def update_step_email
      step = find_step_for_update!
      return if performed?

      attrs = step_attrs_for(step.id)
      return render_step_failure(:email, step) if attrs.nil?

      permitted = apply_email_channel_guards(email_step_params(attrs), step: step)
      permitted[:email_enabled] = true if step.kind_internal_alert?

      if step.update(permitted)
        redirect_to edit_settings_collection_ladder_path(open_email: step.id),
                    notice: "E-mail da etapa atualizado."
      else
        render_step_failure(:email, step)
      end
    end

    def update_step_whatsapp
      step = find_step_for_update!
      return if performed?

      if step.kind_internal_alert?
        head :not_found
        return
      end

      attrs = step_attrs_for(step.id)
      return render_step_failure(:whatsapp, step) if attrs.nil?

      permitted = apply_whatsapp_channel_guards(whatsapp_step_params(attrs))

      if step.update(permitted)
        redirect_to edit_settings_collection_ladder_path(open_whatsapp: step.id),
                    notice: "WhatsApp da etapa atualizado."
      else
        render_step_failure(:whatsapp, step)
      end
    end

    def find_step_for_update!
      step = @steps.find { |s| s.id == params[:step_id].to_i }
      unless step
        head :not_found
        return nil
      end
      step
    end

    def step_attrs_for(step_id)
      params[:collection_steps]&.[](step_id.to_s) || params[:collection_steps]&.[](step_id)
    end

    def render_step_failure(channel, step)
      if channel == :email
        @open_email_step_id = step.id
      else
        @open_whatsapp_step_id = step.id
      end
      render :edit, status: :unprocessable_entity
    end

    def collection_setting_params
      params.expect(collection_setting: [
        :enabled,
        :quiet_hours_start,
        :quiet_hours_end,
        :timezone
      ])
    end

    def email_step_params(attrs)
      attrs.permit(:email_enabled, :email_subject_template, :email_body_template)
    end

    def whatsapp_step_params(attrs)
      attrs.permit(:whatsapp_enabled, :whatsapp_template_name, :whatsapp_body_template)
    end

    def apply_email_channel_guards(permitted, step:)
      if permitted[:email_enabled] == "1" && !ActionMailerDelivery.enabled? && !step.kind_internal_alert?
        permitted[:email_enabled] = "0"
      end
      permitted
    end

    def apply_whatsapp_channel_guards(permitted)
      if permitted[:whatsapp_enabled] == "1" && !Whatsapp::PlatformConfig.configured?
        permitted[:whatsapp_enabled] = "0"
      end
      permitted
    end
  end
end
