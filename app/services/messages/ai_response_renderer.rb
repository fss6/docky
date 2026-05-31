# frozen_string_literal: true

module Messages
  # Renderiza componentes estruturados da IA em HTML seguro (partials + Markdown).
  class AiResponseRenderer
    def self.render(components)
      new(components).render
    end

    def initialize(components)
      @components = Array(components)
    end

    def render
      return "".html_safe if @components.blank?

      html = @components.filter_map { |component| render_component(component) }.join
      html.html_safe
    end

    private

    def render_component(component)
      type = component["type"]
      data = component["data"] || {}
      case type
      when "rich_text", "fallback"
        render_partial("rich_text", content_html: markdown_html(data["content"]))
      when "table"
        render_partial(
          "table",
          title: data["title"],
          headers: data["headers"],
          rows: data["rows"]
        )
      when "alert"
        render_partial(
          "alert",
          severity: data["severity"],
          title: data["title"],
          description: data["description"]
        )
      when "action_list"
        render_partial(
          "action_list",
          title: data["title"],
          actions: data["actions"]
        )
      end
    end

    def render_partial(name, locals)
      ApplicationController.render(
        partial: "ai/components/#{name}",
        locals: locals
      )
    end

    def markdown_html(content)
      return "" if content.blank?

      ApplicationController.helpers.markdown_html(content)
    end
  end
end
