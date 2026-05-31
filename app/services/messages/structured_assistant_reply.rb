# frozen_string_literal: true

module Messages
  # Resposta do assistente via JSON estruturado (componentes visuais + rich_text).
  class StructuredAssistantReply
    RESPONSE_FORMAT = {
      type: "json_schema",
      json_schema: {
        name: "assistant_structured_response",
        strict: false,
        schema: {
          type: "object",
          properties: {
            summary: { type: "string" },
            components: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  type: { type: "string" },
                  data: { type: "object" }
                },
                required: %w[type data],
                additionalProperties: false
              }
            }
          },
          required: %w[summary components],
          additionalProperties: false
        }
      }
    }.freeze

    Result = Struct.new(:summary, :components, :schema_version, keyword_init: true)

    def self.call(context:, history:, user_content:, mode: :document)
      new(context: context, history: history, user_content: user_content, mode: mode).call
    end

    def initialize(context:, history:, user_content:, mode: :document)
      @context = context
      @history = Array(history)
      @user_content = user_content.to_s.strip
      @mode = mode.to_sym
    end

    def call
      raw = Openai::Completion.call(
        messages: build_messages,
        model: chat_model,
        max_tokens: 4096,
        temperature: 0.2,
        response_format: RESPONSE_FORMAT
      )
      parse_response(raw)
    end

    private

    def chat_model
      ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini")
    end

    def build_messages
      base_prompt = LlmService.system_prompt(@context, markdown_block: MarkdownGuidelines::PROSE_ONLY_BLOCK)
      suffix = [
        AiComponents::Guidelines::PROMPT_BLOCK,
        (@mode == :tabular ? AiComponents::Guidelines::TABULAR_SUFFIX : nil)
      ].compact.join("\n\n")

      [
        { role: "system", content: "#{base_prompt}\n\n#{suffix}" },
        *@history.map { |m| { role: m[:role].to_s, content: m[:content].to_s } },
        { role: "user", content: @user_content }
      ]
    end

    def parse_response(raw)
      data = JSON.parse(raw)
      require_table = @mode == :tabular
      normalized = AiComponents::Registry.normalize_payload(data, require_table: require_table)

      Result.new(
        summary: normalized["summary"],
        components: normalized["components"],
        schema_version: normalized["schema_version"]
      )
    end
  end
end
