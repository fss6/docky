# frozen_string_literal: true

module Wiki
  # Analisa periodicamente as páginas do wiki e identifica problemas de qualidade.
  # Executado via WikiLintJob (Solid Queue cron / Sidekiq Cron).
  class LintService
    LLM_MAX_TOKENS = 2048
    MAX_WIKI_CHARS = 30_000

    def initialize(account)
      @account = account
    end

    def call
      pages = @account.wiki_pages.ordered.to_a
      return { "issues" => [] } if pages.empty?

      prompt = build_prompt(pages)
      raw    = call_llm(prompt)
      result = parse_json(raw)
      return { "issues" => [] } if result.blank?

      store_lint_results(result)
      log_operation(result)
      result
    rescue StandardError => e
      Rails.logger.error("[Wiki::LintService] #{e.class}: #{e.message}")
      { "issues" => [] }
    end

    private

    def build_prompt(pages)
      pages_text = pages.map { |p| "### #{p.title} (#{p.slug})\n#{p.content.to_s.truncate(1000)}" }
                        .join("\n\n")
                        .truncate(MAX_WIKI_CHARS)

      <<~PROMPT
        Analise as páginas desta base de conhecimento e identifique:

        1. Contradições entre fontes
        2. Claims possivelmente desatualizados
        3. Páginas órfãs sem referências
        4. Lacunas de cobertura óbvias
        5. Entidades mencionadas mas sem página própria

        Páginas do wiki:
        #{pages_text}

        Responda SOMENTE em JSON válido (sem markdown, sem ```json):
        {
          "issues": [
            {
              "type": "contradiction|outdated|orphan|gap|missing_entity",
              "severity": "high|medium|low",
              "description": "...",
              "affected_pages": ["slug1", "slug2"]
            }
          ]
        }
      PROMPT
    end

    def call_llm(prompt)
      messages = [
        { role: "system", content: "Você é um auditor de base de conhecimento. Responda sempre em JSON válido." },
        { role: "user",   content: prompt }
      ]
      Openai::Completion.call(
        messages: messages,
        model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini"),
        max_tokens: LLM_MAX_TOKENS,
        temperature: 0.1
      )
    end

    def parse_json(raw)
      cleaned = raw.to_s.strip.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
      JSON.parse(cleaned)
    rescue JSON::ParserError => e
      Rails.logger.error("[Wiki::LintService] JSON inválido: #{e.message}")
      nil
    end

    def store_lint_results(result)
      issues = result["issues"] || []
      return if issues.empty?

      issues.select { |i| i["severity"] == "high" }.each do |issue|
        slugs = Array(issue["affected_pages"])
        slugs.each do |slug|
          page = @account.wiki_pages.find_by(slug: slug)
          next unless page

          note = "\n\n**⚠ Lint (#{issue['type']}):** #{issue['description']}"
          page.update_columns(content: page.content.to_s + note, updated_at: Time.current)
        end
      end
    end

    def log_operation(result)
      WikiLog.create!(
        account: @account,
        operation: "lint",
        details: result.to_json
      )
    end
  end
end
