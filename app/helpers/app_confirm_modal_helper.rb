# frozen_string_literal: true

module AppConfirmModalHelper
  # Atributos + ação Stimulus para abrir o modal definido no mesmo ancestral com data-controller="app-confirm-modal".
  # @param url [String] URL do form de confirmação (ex.: user_path(user), folder_path(folder))
  # @param item_label [String, nil] texto exibido em destaque no corpo do modal (nome do recurso)
  # @param http_method [String, nil] "delete" (padrão), "post", "patch" ou "put"
  # @param confirm_variant [String, nil] "danger" (padrão visual ao omitir) ou "primary"
  def app_confirm_modal_open_data(url:, item_label: nil, http_method: nil, heading: nil, body_prefix: nil, body_suffix: nil, confirm_text: nil, confirm_variant: nil, turbo_stream: false, **extra)
    {
      action: "click->app-confirm-modal#open",
      app_confirm_modal_url_param: url,
      app_confirm_modal_item_label_param: item_label
    }.merge(extra).tap do |h|
      h[:app_confirm_modal_http_method_param] = http_method if http_method.present?
      h[:app_confirm_modal_heading_param] = heading if heading
      h[:app_confirm_modal_body_prefix_param] = body_prefix if body_prefix
      h[:app_confirm_modal_body_suffix_param] = body_suffix if body_suffix
      h[:app_confirm_modal_confirm_text_param] = confirm_text if confirm_text
      h[:app_confirm_modal_confirm_variant_param] = confirm_variant if confirm_variant
      h[:app_confirm_modal_turbo_stream_param] = true if turbo_stream
    end
  end
end
