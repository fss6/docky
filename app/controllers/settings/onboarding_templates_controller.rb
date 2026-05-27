# frozen_string_literal: true

module Settings
  class OnboardingTemplatesController < ApplicationController
    before_action :set_template, only: %i[show edit update]

    def index
      authorize OnboardingTemplate
      @templates = policy_scope(current_user.account.onboarding_templates)
        .includes(:items)
        .ordered
    end

    def show
      authorize @template
    end

    def edit
      authorize @template
    end

    def update
      authorize @template

      if @template.update(template_params)
        redirect_to settings_onboarding_template_path(@template), notice: "Template de onboarding atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_template
      @template = policy_scope(current_user.account.onboarding_templates)
        .includes(:items)
        .find(params.expect(:id))
      @items = @template.items.ordered
    end

    def template_params
      params
        .require(:onboarding_template)
        .permit(
          :name,
          items_attributes: %i[id name help_text position _destroy]
        )
    end
  end
end
