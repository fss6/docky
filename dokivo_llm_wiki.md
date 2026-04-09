# LLM Wiki no Dokivo — Guia de Implementação

> Baseado no padrão proposto por Andrej Karpathy (abril/2026), adaptado para a stack Ruby on Rails + PostgreSQL + pgvector do Dokivo.

---

## Visão Geral

O padrão LLM Wiki transforma o Dokivo de um sistema de RAG stateless em uma **base de conhecimento acumulada por empresa**. Em vez de redescobrir informações a cada consulta, o sistema constrói e mantém um wiki persistente no banco de dados, sintetizado automaticamente pela IA conforme novos documentos são adicionados.

---

## Arquitetura das Três Camadas

```
┌─────────────────────────────────────────────┐
│           FONTES BRUTAS (imutáveis)          │
│  PDFs, contratos, documentos enviados        │
│  Tabela: documents                           │
└────────────────────┬────────────────────────┘
                     │ ingestão (chunking)
                     ▼
┌─────────────────────────────────────────────┐   ┌──────────────────────────────────────┐
│              WIKI (persistente)              │   │      embedding_records (unificada)   │
│  Resumos, entidades, sínteses, conexões      │──►│  recordable_type: "Document" (chunk) │
│  Tabela: wiki_pages + wiki_links + wiki_log  │   │  recordable_type: "WikiPage" (wiki)  │
└────────────────────┬────────────────────────┘   └──────────────────┬───────────────────┘
                     │                                                │
                     └──────────────┬─────────────────────────────────┘
                                    │ busca vetorial unificada
                                    ▼
┌─────────────────────────────────────────────┐
│              SCHEMA (configuração)           │
│  Regras, entidades relevantes, convenções    │
│  Tabela: wiki_schemas (por account)          │
└─────────────────────────────────────────────┘
```

---

## Modelagem do Banco de Dados

### Tabela `embedding_records` — já existente, sem alteração

A tabela já suporta a unificação via associação polimórfica. Nenhuma migration nova é necessária.

```ruby
# Já existe — apenas passa a receber dois tipos de recordable:
# recordable_type: "Document"  → chunks dos PDFs (comportamento atual)
# recordable_type: "WikiPage"  → páginas do wiki (novo)
```

Adicione apenas um índice único para garantir um embedding por página:

```ruby
add_index :embedding_records, [:recordable_type, :recordable_id], unique: true
```

---

### Tabela `wiki_pages` — nova

```ruby
create_table :wiki_pages do |t|
  t.references :account, null: false, foreign_key: true
  t.string  :slug,               null: false   # ex: "entidades/fornecedor-abc"
  t.string  :title,              null: false
  t.text    :content                            # Markdown gerado pela IA
  t.string  :page_type,          null: false   # summary | entity | synthesis | index
  t.integer :source_document_id                # documento que originou (se houver)
  t.timestamps
end

add_index :wiki_pages, [:account_id, :slug], unique: true
add_index :wiki_pages, :page_type
```

> **Sem coluna `embedding` aqui.** O vetor fica em `embedding_records` como `recordable_type: "WikiPage"`, mantendo tudo centralizado.

**Tipos de página (`page_type`):**

| Tipo | Descrição |
|---|---|
| `summary` | Resumo de um documento específico |
| `entity` | Página de uma entidade (empresa, pessoa, cláusula) |
| `synthesis` | Síntese temática sobre um assunto |
| `index` | Índice geral do account |

---

### Tabela `wiki_links` — nova

```ruby
create_table :wiki_links do |t|
  t.references :source_page, null: false, foreign_key: { to_table: :wiki_pages }
  t.references :target_page, null: false, foreign_key: { to_table: :wiki_pages }
  t.string :link_type   # references | contradicts | extends | supersedes
  t.timestamps
end
```

---

### Tabela `wiki_logs` — nova

```ruby
# Append-only — nunca deletar registros
create_table :wiki_logs do |t|
  t.references :account,  null: false, foreign_key: true
  t.string  :operation,   null: false   # ingest | query | lint
  t.integer :document_id                # documento processado (se ingest)
  t.integer :wiki_page_id               # página criada/atualizada (se houver)
  t.text    :details                    # JSON com metadados da operação
  t.timestamps
end
```

---

### Tabela `wiki_schemas` — nova

```ruby
create_table :wiki_schemas do |t|
  t.references :account, null: false, foreign_key: true
  t.text :instructions   # Instruções do sistema para o LLM (ex-CLAUDE.md)
  t.timestamps
end
```

**Exemplo de `instructions` padrão:**

```
Você é o assistente de base de conhecimento desta empresa.
Ao processar documentos, sempre:
1. Identifique as partes envolvidas (pessoas, empresas, departamentos)
2. Extraia datas críticas e prazos
3. Destaque cláusulas de penalidade, rescisão e obrigações
4. Relacione com documentos anteriores quando houver conexão
5. Sinalize contradições com documentos já processados

Convenções de nomenclatura de slug:
- Entidades: entidades/{tipo}-{nome-normalizado}
- Resumos: documentos/{id}-{titulo-normalizado}
- Sínteses: temas/{assunto}
```

---

## Integração com `embedding_records`

### Model `WikiPage`

```ruby
# app/models/wiki_page.rb
class WikiPage < ApplicationRecord
  belongs_to :account
  has_many :embedding_records, as: :recordable, dependent: :destroy

  # Gera embedding automaticamente após criar/atualizar conteúdo
  after_save :embed_async, if: :saved_change_to_content?

  private

  def embed_async
    WikiEmbedJob.perform_later(id)
  end
end
```

---

### Job de Embedding das Páginas Wiki

```ruby
# app/jobs/wiki_embed_job.rb
class WikiEmbedJob < ApplicationJob
  queue_as :embeddings

  def perform(wiki_page_id)
    page   = WikiPage.find(wiki_page_id)
    vector = EmbeddingService.generate(page.content)

    EmbeddingRecord.upsert(
      {
        account_id:      page.account_id,
        recordable_type: "WikiPage",
        recordable_id:   page.id,
        content:         page.content,
        embedding:       vector,
        metadata:        {
          slug:      page.slug,
          page_type: page.page_type,
          title:     page.title
        }
      },
      unique_by: [:recordable_type, :recordable_id]
    )
  end
end
```

---

### Busca Unificada — `RagSearchService`

A busca passa a rodar em **um único query no `embedding_records`**, filtrando por `recordable_type` quando necessário.

```ruby
# app/services/rag_search_service.rb
class RagSearchService
  def initialize(question, account, options = {})
    @question = question
    @account  = account
    @mode     = options[:mode] || :unified # :unified | :wiki_only | :docs_only
  end

  def call
    query_vector = EmbeddingService.generate(@question)

    results = EmbeddingRecord
      .where(account_id: @account.id)
      .then { |q| filter_by_mode(q) }
      .nearest_neighbors(:embedding, query_vector, distance: :cosine)
      .limit(10)
      .includes(:recordable)

    format_results(results)
  end

  private

  def filter_by_mode(query)
    case @mode
    when :wiki_only  then query.where(recordable_type: "WikiPage")
    when :docs_only  then query.where(recordable_type: "Document")
    else query
    end
  end

  def format_results(results)
    results.map do |r|
      {
        content:  r.content,
        source:   r.recordable_type,
        metadata: r.metadata,
        label:    r.recordable_type == "WikiPage" ? "[WIKI SINTETIZADO]" : "[DOCUMENTO ORIGINAL]"
      }
    end
  end
end
```

---

### Contexto diferenciado no prompt do chat

```ruby
def build_context(results)
  wiki_chunks = results.select { |r| r[:source] == "WikiPage" }
  doc_chunks  = results.select { |r| r[:source] == "Document" }

  <<~CONTEXT
    === CONHECIMENTO ACUMULADO (Wiki) ===
    #{wiki_chunks.map { |r| r[:content] }.join("\n\n")}

    === TRECHOS DOS DOCUMENTOS ORIGINAIS ===
    #{doc_chunks.map { |r| r[:content] }.join("\n\n")}
  CONTEXT
end
```

> Separar no prompt é importante: o LLM trata o wiki como conhecimento já validado e os chunks como evidência bruta.

---



## As Três Operações Principais

### 1. Ingest — ao fazer upload de um documento

```ruby
# app/services/wiki/ingest_service.rb
class Wiki::IngestService
  def initialize(document, account)
    @document = document
    @account  = account
  end

  def call
    schema    = @account.wiki_schema&.instructions || default_instructions
    full_text = extract_text(@document)

    prompt = <<~PROMPT
      #{schema}

      Novo documento recebido:
      ---
      #{full_text}
      ---

      Wiki atual do account (páginas existentes):
      #{existing_wiki_summary}

      Responda SOMENTE em JSON com esta estrutura:
      {
        "new_pages": [
          { "slug": "...", "title": "...", "content": "...", "page_type": "..." }
        ],
        "updated_pages": [
          { "slug": "...", "content_patch": "..." }
        ],
        "links": [
          { "source_slug": "...", "target_slug": "...", "link_type": "..." }
        ],
        "contradictions": [
          { "description": "...", "page_slug": "..." }
        ]
      }
    PROMPT

    result = call_llm(prompt)
    persist_wiki_changes(result)
    # WikiEmbedJob é disparado automaticamente via after_save no model WikiPage
    log_operation(:ingest, document_id: @document.id, details: result.to_json)
  end
end
```

**O que acontece a cada ingestão:**
- Cria página de resumo do documento
- Atualiza páginas de entidades mencionadas
- Registra links entre páginas relacionadas
- Sinaliza contradições com o conhecimento existente
- Atualiza o índice geral (`index`)
- `WikiEmbedJob` embeda automaticamente as páginas novas/atualizadas em `embedding_records`

---

### 2. Query — ao fazer uma pergunta no chat

Usa o `RagSearchService` unificado (definido na seção anterior) em vez de dois serviços separados.

```ruby
# app/services/wiki/query_service.rb
class Wiki::QueryService
  def initialize(question, account)
    @question = question
    @account  = account
  end

  def call
    results = RagSearchService.new(@question, @account, mode: :unified).call
    context = build_context(results)

    prompt = <<~PROMPT
      Você é o assistente do Dokivo. Use o contexto abaixo para responder.

      #{context}

      Pergunta: #{@question}

      Responda com base no contexto. Cite as fontes (página do wiki ou documento).
      Se relevante, indique se há contradições conhecidas.
    PROMPT

    response = call_llm(prompt)
    wiki_pages_used = results.select { |r| r[:source] == "WikiPage" }.map { |r| r.dig(:metadata, :slug) }
    log_operation(:query, details: { question: @question, wiki_pages_used: }.to_json)
    response
  end

  private

  def build_context(results)
    wiki_chunks = results.select { |r| r[:source] == "WikiPage" }
    doc_chunks  = results.select { |r| r[:source] == "Document" }

    <<~CONTEXT
      === CONHECIMENTO ACUMULADO (Wiki) ===
      #{wiki_chunks.map { |r| r[:content] }.join("\n\n")}

      === TRECHOS DOS DOCUMENTOS ORIGINAIS ===
      #{doc_chunks.map { |r| r[:content] }.join("\n\n")}
    CONTEXT
  end
end
```

---

### 3. Lint — verificação periódica de saúde

```ruby
# app/services/wiki/lint_service.rb
# Executado via Sidekiq::Cron — ex: toda segunda-feira de manhã
class Wiki::LintService
  def initialize(account)
    @account = account
  end

  def call
    pages = @account.wiki_pages.all
    
    prompt = <<~PROMPT
      Analise as páginas desta base de conhecimento e identifique:

      1. Contradições entre fontes
      2. Claims possivelmente desatualizados
      3. Páginas órfãs sem referências
      4. Lacunas de cobertura óbvias
      5. Entidades mencionadas mas sem página própria

      Páginas do wiki:
      #{pages.map { |p| "### #{p.title}\n#{p.content}" }.join("\n\n")}

      Responda em JSON:
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

    result = call_llm(prompt)
    store_lint_results(result)
    log_operation(:lint, details: result.to_json)
    result
  end
end
```

---

## Pipeline de Ingestão Assíncrona

```ruby
# app/jobs/wiki_ingest_job.rb
class WikiIngestJob < ApplicationJob
  queue_as :wiki_processing

  def perform(document_id)
    document = Document.find(document_id)
    account  = document.account

    Wiki::IngestService.new(document, account).call
    # WikiEmbedJob já é disparado automaticamente via after_save em WikiPage
  end
end

# Disparado após upload do documento
# app/controllers/documents_controller.rb
def create
  @document = current_account.documents.create!(document_params)
  WikiIngestJob.perform_later(@document.id)
  render json: @document, status: :created
end
```

---

## API para a Página de Knowledge Base

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :wiki_pages, only: [:index, :show]
    get 'wiki/log',         to: 'wiki_pages#log'
    get 'wiki/lint_report', to: 'wiki_pages#lint_report'
  end
end

# app/controllers/api/v1/wiki_pages_controller.rb
class Api::V1::WikiPagesController < ApplicationController
  def index
    pages = current_account.wiki_pages
              .order(:page_type, :title)
              .select(:id, :slug, :title, :page_type, :updated_at)
    render json: pages
  end

  def show
    page = current_account.wiki_pages.find_by!(slug: params[:slug])
    render json: page
  end

  def log
    logs = current_account.wiki_logs
             .order(created_at: :desc)
             .limit(50)
    render json: logs
  end
end
```

---

## Página de Knowledge Base (Frontend)

A página exibe o wiki de forma legível, organizada por tipo:

```
┌──────────────────────────────────────────────────┐
│  📚 Base de Conhecimento                          │
│  Workspace: Empresa XYZ · 47 páginas              │
│                                 [Última lint: seg] │
├───────────────┬──────────────────────────────────┤
│  CATEGORIAS   │  CONTEÚDO DA PÁGINA               │
│               │                                   │
│  📋 Índice    │  ## Fornecedor ABC                │
│               │  Atualizado em: 08/04/2026        │
│  🏢 Entidades │  Fonte: Contrato_2024.pdf         │
│    Fornecedores│                                  │
│    Clientes   │  Empresa de logística contratada  │
│    Pessoas    │  desde março/2024. Valor mensal:  │
│               │  R$ 45.000. Cláusula de rescisão: │
│  📄 Resumos   │  30 dias de aviso prévio.         │
│               │                                   │
│  🔍 Sínteses  │  **Relacionado:** Aditivo_01.pdf  │
│               │  **Contradição:** valor diverge   │
│  ⚠️ Alertas   │  do Contrato_2023.pdf (R$38.000)  │
└───────────────┴──────────────────────────────────┘
```

---

## Fluxo Final Unificado

```
Upload PDF
   │
   ├─► chunkar + embedar → embedding_records (recordable: "Document")   [já existe]
   │
   └─► WikiIngestJob
          │
          └─► Wiki::IngestService → cria/atualiza WikiPages
                    │
                    └─► after_save → WikiEmbedJob
                              │
                              └─► embedding_records (recordable: "WikiPage")


Pergunta no chat
   │
   └─► RagSearchService (busca unificada em embedding_records)
          │
          ├─► resultados WikiPage   → [WIKI SINTETIZADO]
          └─► resultados Document  → [DOCUMENTO ORIGINAL]
                    │
                    └─► Wiki::QueryService → LLM → resposta com citações
```



| Plano | Páginas wiki | Lint automático | Edição manual |
|---|---|---|---|
| Starter | 50 páginas | — | — |
| Pro | 500 páginas | Mensal | — |
| Enterprise | Ilimitado | Semanal | ✓ |

---

## Checklist de Implementação

- [ ] Adicionar índice único em `embedding_records` (`recordable_type` + `recordable_id`)
- [ ] Criar migrations: `wiki_pages`, `wiki_links`, `wiki_logs`, `wiki_schemas`
- [ ] Implementar model `WikiPage` com `after_save :embed_async`
- [ ] Implementar `WikiEmbedJob` (upsert em `embedding_records`)
- [ ] Implementar `RagSearchService` com filtro por `recordable_type`
- [ ] Implementar `Wiki::IngestService`
- [ ] Implementar `Wiki::QueryService` usando `RagSearchService`
- [ ] Implementar `Wiki::LintService`
- [ ] Criar `WikiIngestJob` e configurar fila no Sidekiq
- [ ] Adicionar endpoints REST para a Knowledge Base
- [ ] Construir página de KB no frontend com render de Markdown
- [ ] Configurar Sidekiq Cron para lint periódico
- [ ] Definir `instructions` padrão em `wiki_schemas`
- [ ] Definir limites de páginas wiki por plano

---

## Observações Importantes

1. **As fontes brutas são imutáveis** — o LLM lê, mas nunca altera documentos originais.
2. **Deixe claro no UI** que o conteúdo do wiki é gerado pela IA com base nos documentos enviados, não uma verdade absoluta.
3. **Comece simples** — listagem de páginas + visualização de Markdown. Edição manual pelo usuário pode vir em iteração futura.
4. **O wiki cresce com o uso** — cada consulta bem respondida pode gerar novas páginas via operação Query.

---

*Dokivo — Documentação Interna · Gerado em abril/2026*
