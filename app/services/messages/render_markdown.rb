# frozen_string_literal: true

module Messages
  # Converte Markdown GFM em HTML via CommonMarker (sem pré-processamento por regex).
  class RenderMarkdown
    PARSE_OPTIONS = {
      smart: true,
      gfm_opts: %i[table strikethrough tagfilter]
    }.freeze

    RENDER_OPTIONS = {
      hardbreaks: true,
      unsafe: false
    }.freeze

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text
    end

    def call
      return "" if @text.blank?

      source = @text.to_s.gsub("\r\n", "\n").strip
      Commonmarker.to_html(source, options: {
        parse: PARSE_OPTIONS,
        render: RENDER_OPTIONS
      })
    end
  end
end
