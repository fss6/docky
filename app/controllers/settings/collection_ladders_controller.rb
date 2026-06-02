# frozen_string_literal: true

module Settings
  class CollectionLaddersController < ApplicationController
    before_action :set_collection_setting
    before_action :load_steps
    before_action :authorize_policy

    def edit
      @selected_step = @steps.find { |s| s.id == params[:step_id].to_i } || @steps.first
      @email_configured = ActionMailerDelivery.enabled?
      @whatsapp_configured = Whatsapp::PlatformConfig.configured?
    end

    def update
      if update_collection!
        redirect_to edit_settings_collection_ladder_path(step_id: params[:selected_step_id]),
                    notice: "Régua de cobrança atualizada com sucesso."
      else
        @selected_step = @steps.find { |s| s.id == params[:selected_step_id].to_i } || @steps.first
        @email_configured = ActionMailerDelivery.enabled?
        @whatsapp_configured = Whatsapp::PlatformConfig.configured?
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_collection_setting
      @collection_setting = CollectionSetting.ensure_for!(current_user.account)
    end

    def load_steps
      @steps = current_user.account.collection_steps.ordered
    end

    def authorize_policy
      authorize current_user.account.setting || Setting.new(account: current_user.account)
    end

    def update_collection!
      ActiveRecord::Base.transaction do
        @collection_setting.update!(collection_setting_params)
        update_steps!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def collection_setting_params
      params.expect(collection_setting: [
        :enabled,
        :auto_confirm_receipt,
        :quiet_hours_start,
        :quiet_hours_end,
        :max_messages_per_client_per_day,
        :timezone
      ])
    end

    def update_steps!
      return unless params[:collection_steps]

      params[:collection_steps].each do |id, attrs|
        step = @steps.find { |s| s.id.to_s == id.to_s }
        next unless step

        step.update!(step_params(attrs))
      end
    end

    def step_params(attrs)
      permitted = attrs.permit(
        :email_enabled,
        :whatsapp_enabled,
        :email_subject_template,
        :email_body_template,
        :whatsapp_body_template,
        :whatsapp_template_name
      )
      if permitted[:email_enabled] == "1" && !ActionMailerDelivery.enabled?
        permitted[:email_enabled] = "0"
      end
      if permitted[:whatsapp_enabled] == "1" && !Whatsapp::PlatformConfig.configured?
        permitted[:whatsapp_enabled] = "0"
      end
      permitted
    end
  end
end
