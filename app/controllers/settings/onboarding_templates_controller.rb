# frozen_string_literal: true

module Settings
  class OnboardingTemplatesController < ApplicationController
    before_action :set_template, only: %i[show edit update destroy]

    def index
      authorize OnboardingTemplate
      @templates = policy_scope(current_user.account.onboarding_templates)
        .includes(:items)
        .ordered
    end

    def show
      authorize @template
    end

    def new
      @template = current_user.account.onboarding_templates.build
      authorize @template
    end

    def create
      @template = current_user.account.onboarding_templates.build(create_template_params.merge(system: false))
      authorize @template

      if @template.save
        redirect_to edit_settings_onboarding_template_path(@template),
                    notice: t("settings.onboarding_templates.flashes.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @template
    end

    def update
      authorize @template

      if @template.update(template_params)
        redirect_to settings_onboarding_template_path(@template),
                    notice: t("settings.onboarding_templates.flashes.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @template
      @template.destroy!

      redirect_to settings_onboarding_templates_path,
                  notice: t("settings.onboarding_templates.flashes.destroyed")
    end

    private

    def set_template
      @template = policy_scope(current_user.account.onboarding_templates)
        .includes(:items)
        .find(params.expect(:id))
      @items = @template.items.ordered
    end

    def create_template_params
      params.require(:onboarding_template).permit(:name, :description)
    end

    def template_params
      params
        .require(:onboarding_template)
        .permit(
          :name,
          :description,
          items_attributes: %i[id name help_text position _destroy]
        )
    end
  end
end
