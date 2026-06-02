# frozen_string_literal: true

module CollectionPanelHelper
  def collection_panel_path_with_filters(overrides = {})
    collection_panel_path(collection_panel_filter_params.merge(overrides))
  end

  def collection_panel_filter_params
    {
      status: @status_filter,
      q: @search_query.presence
    }.compact
  end

  def collection_panel_status_chip(label, status_value)
    active = @status_filter == status_value || (@status_filter.blank? && status_value.blank?)
    base = "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold no-underline transition"
    classes = if active
                "#{base} bg-accent text-white"
              else
                "#{base} bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
              end
    link_to label, collection_panel_path_with_filters(status: status_value), class: classes
  end
end
