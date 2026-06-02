# Dokivo

Rails app run via Docker Compose (`web` + `worker` services).

## Configurações da plataforma (administrator)

Usuários com papel **`administrator`** acessam **Sistema → Plataforma** (`/sistema/plataforma`) para definir SMTP e WhatsApp da Dokivo. Os valores salvos na tabela `platform_settings` têm **prioridade** sobre variáveis de ambiente e `credentials`; ENV/credentials servem como **fallback** quando o banco estiver vazio. Senhas e tokens são armazenados criptografados (chaves derivadas do `secret_key_base` em dev, ou `active_record_encryption` em `credentials` em produção); o registro é cacheado no Redis por 1 minuto.

---

## Configuração de e-mail (SMTP)

A entrega de e-mail é controlada por [`PlatformSettings::SmtpConfig`](app/services/platform_settings/smtp_config.rb) e [`config/initializers/action_mailer_delivery.rb`](config/initializers/action_mailer_delivery.rb). Em produção, prefira configurar em **Plataforma**; copie [`.env.example`](.env.example) para `.env` apenas como fallback ou bootstrap.

### Variáveis

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `MAIL_DELIVERY` | Não | Modo de envio: vazio (sem SMTP explícito), `gmail` ou `smtp`. Valores inválidos impedem o boot. |
| `SMTP_USERNAME` | Sim, se `MAIL_DELIVERY` estiver definido | Usuário SMTP (login). No Gmail, o e-mail da conta Google. |
| `SMTP_PASSWORD` | Sim, se `MAIL_DELIVERY` estiver definido | Senha SMTP. No Gmail, use uma [senha de app](https://support.google.com/accounts/answer/185833). |
| `SMTP_ADDRESS` | Sim, se `MAIL_DELIVERY=smtp` | Host do provedor (ex.: `smtp.sendgrid.net`). Ignorado em `gmail` (usa `smtp.gmail.com`). |
| `SMTP_PORT` | Não | Porta SMTP. Padrão: `587` (STARTTLS). |
| `SMTP_DOMAIN` | Não | HELO/EHLO domain. Padrão: `gmail.com` no modo gmail; host SMTP no modo smtp. |
| `SMTP_AUTHENTICATION` | Não | Mecanismo de auth. Padrão: `plain`. |
| `MAILER_FROM` | Não | Remetente exibido (`From:`). Padrão: `SMTP_USERNAME`. Ex.: `Dokivo <no-reply@seudominio.com.br>`. |
| `MAILER_DEFAULT_HOST` | Não | Host em links gerados pelo Rails (Devise, rotas de mailer). Dev: `localhost`. Prod: domínio público. |
| `MAILER_DEFAULT_PORT` | Não | Porta nos links em **development** (padrão `3000`). |
| `PUBLIC_APP_HOST` | Não | Host dos links do portal nos e-mails de convite. Se omitido, usa `MAILER_DEFAULT_HOST` (sem prefixo `portal.`). |

### Links do portal de upload

Convites de upload (e-mail e modal de compartilhamento) geram URLs no formato:

```
/portal/:token/upload          # envio mensal
/portal/:token/onboarding      # onboarding
```

O **path** é o mesmo em todos os ambientes; o **host** e o **protocolo** variam:

| Contexto | Development | Production |
|----------|-------------|------------|
| E-mail de convite | `http://localhost/portal/...` | `https://app.seudominio.com.br/portal/...` |
| Modal (copiar link) | host do browser (`localhost`) | host do browser (`app.seudominio.com.br`) |

**E-mails** — montados por [`Clients::PublicUploadUrl`](app/services/clients/public_upload_url.rb): usa `PUBLIC_APP_HOST` (se definido) ou `MAILER_DEFAULT_HOST`; em development o protocolo é `http`, em production é `https`.

**Modal na UI** — montado por `client_public_upload_url` no helper: usa `PUBLIC_APP_HOST` (se definido) ou o host da requisição atual (`request.host`).

Se o host configurado tiver prefixo `portal.` (ex.: `portal.seudominio.com.br`), ele é removido automaticamente — o path `/portal/...` já identifica a área pública.

Em produção, configure pelo menos `MAILER_DEFAULT_HOST` (e opcionalmente `PUBLIC_APP_HOST` para forçar o mesmo host nos e-mails):

```env
MAILER_DEFAULT_HOST=app.seudominio.com.br
PUBLIC_APP_HOST=app.seudominio.com.br
```

### Modos

**Sem envio real** — deixe `MAIL_DELIVERY` vazio (ou comente). O Rails não aplica SMTP; útil se você não for testar e-mail.

**Gmail (dev / testes)** — `MAIL_DELIVERY=gmail` + credenciais Google:

```env
MAIL_DELIVERY=gmail
SMTP_USERNAME=seu-email@gmail.com
SMTP_PASSWORD=senha-de-app-de-16-caracteres
MAILER_FROM="Dokivo <no-reply@seudominio.com.br>"
MAILER_DEFAULT_HOST=localhost
MAILER_DEFAULT_PORT=3000
```

**SMTP genérico (prod)** — SendGrid, SES, Postmark, etc.:

```env
MAIL_DELIVERY=smtp
SMTP_ADDRESS=smtp.seuprovedor.com
SMTP_PORT=587
SMTP_DOMAIN=seudominio.com.br
SMTP_USERNAME=apikey
SMTP_PASSWORD=...
SMTP_AUTHENTICATION=plain
MAILER_FROM="Dokivo <no-reply@seudominio.com.br>"
MAILER_DEFAULT_HOST=app.seudominio.com.br
PUBLIC_APP_HOST=app.seudominio.com.br
```

Em **development**, com `MAIL_DELIVERY` definido, erros de entrega sobem (`raise_delivery_errors`). Sem `MAIL_DELIVERY`, falhas de SMTP não quebram a requisição.

---

## Background jobs (Sidekiq)

Active Job usa **Sidekiq** (Redis). O container `web` enfileira; o `worker` processa (incluindo envio SMTP).

| Variável | Descrição |
|----------|-----------|
| `REDIS_URL` | Mesmo valor em `web` e `worker` (ex.: `redis://redis:6379/0`). |

```bash
docker compose up web worker
```

As variáveis `MAIL_DELIVERY` / SMTP precisam estar no `.env` carregado pelo **worker** — é ele quem chama `deliver_now` nos jobs de e-mail.

### Testar convite por e-mail

No modal de link de upload → **Enviar e-mail**. A UI mostra **Envio em andamento…**; após o worker processar, confira logs e `AuditEvent` (`upload_invite.email_sent` ou `upload_invite.email_failed`).

O job mensal `Periods::OpenMonthJob` roda via **sidekiq-cron** no worker.

### Deploy em produção

- Subir `web` e `worker` com o mesmo `REDIS_URL` e as mesmas vars SMTP.
- Se migrou de Solid Queue, esvaziar jobs pendentes em `solid_queue_jobs` antes de depender só do Sidekiq.

---

## Permissões da equipe (ACL)

O que **members** podem fazer em cada conta é configurável pelo **owner**. A autorização em runtime passa por **Pundit** → `Permissions.allow?` → tabela `account_permission_grants`. O catálogo de capabilities é **fixo no código** (não é cadastro dinâmico pelo usuário).

### Papéis (`User#role`)

| Papel | Comportamento |
|-------|----------------|
| `owner` | Bypass da matriz para recursos do tenant; gerencia usuários e permissões |
| `member` | Obedece os grants em `account_permission_grants` (role `member`) |
| `administrator` | Operações de **plataforma** (`Account`, `Plan`, `Subscription`) via policy; fora da matriz por conta e sem UI dedicada de SaaS |

### Onde editar na UI

| O quê | Caminho | Quem acessa |
|-------|---------|-------------|
| **Permissões da equipe** (toggles por capability) | **Configurações** → card **Permissões da equipe** → `/settings/permissions` | Somente `owner` |
| **Usuários** (criar/editar pessoas, role, ativo) | Menu **Usuários** → `/users` | `owner` ou member com `users.manage` |

Owners sempre têm acesso total; a tela de permissões define o que **members** podem fazer.

### Fluxo técnico

```text
Permissions::Catalog (DEFINITIONS + GROUPS)   ← fonte da verdade no código
        ↓
/settings/permissions (view gera toggles por grupo)
        ↓
account_permission_grants (por account_id, role member)
        ↓
Permissions.allow?(user, capability_key)
        ↓
ApplicationPolicy#allow_capability?  →  policies e menu (policy(...).action?)
```

Arquivos principais:

- Catálogo: [`app/lib/permissions/catalog.rb`](app/lib/permissions/catalog.rb)
- Serviço: [`app/services/permissions.rb`](app/services/permissions.rb)
- Seed por conta: [`app/services/permissions/seed_defaults.rb`](app/services/permissions/seed_defaults.rb)
- Atualização na UI: [`app/services/permissions/update_grants.rb`](app/services/permissions/update_grants.rb)
- Policy da tela: [`app/policies/account_permissions_policy.rb`](app/policies/account_permissions_policy.rb)

### Adicionar um módulo novo

Ao introduzir uma área nova (ex.: Relatórios), a rota `/settings/permissions` **não precisa mudar** — novos toggles aparecem quando o catálogo e as traduções existirem.

1. **Catálogo** — em `Permissions::Catalog::DEFINITIONS`, incluir keys no padrão `modulo.acao` (ex.: `reports.read`, `reports.manage`) com `default_member:` e `group:`. Se for área nova, acrescentar o grupo em `GROUPS`.
2. **Pundit** — na policy do recurso, usar `allow_capability?("reports.read")` (e não duplicar `role_member?` / `role_owner?` manualmente).
3. **Menu / views** — gates com `policy(Recurso).index?` (ou action equivalente).
4. **i18n** — em `config/locales/pt-BR.yml`, sob `settings.permissions.groups.*` e `settings.permissions.capabilities.*` (na chave i18n, `.` vira `_`, ex.: `reports.read` → `reports_read`).
5. **Contas já existentes** — `Permissions::SeedDefaults.call(account: account)` cria linhas só para keys **novas** (não altera grants antigos). Rode em data migration/rake após deploy, ou ao salvar em `/settings/permissions` (`UpdateGrants` chama `SeedDefaults` antes do PATCH). Contas novas recebem seed no `after_create` de `Account`.

Convenção: poucas capabilities por domínio (`read`, `write`, `manage`, `use`), agrupadas por produto — não um toggle por cada método do Pundit.

### Limitações (v1)

- Catálogo versionado com o app (deploy para novas capabilities).
- Grants apenas para role `member` (sem matriz por grupo ou por usuário).
- `administrator` e recursos de plataforma ficam fora de `account_permission_grants`.
- `DashboardPolicy` e políticas de `Account` / `Plan` / `Subscription` não usam a matriz.

### Usuário fundador (`founding_user`)

Cada conta tem **exatamente um** usuário marcado como fundador na coluna `users.founding_user` (índice único parcial por `account_id`). Isso é independente do papel `role`: o fundador é sempre o **primeiro usuário** da conta, identificado de forma estável no banco (não depende só de `created_at` na UI).

| Aspecto | Detalhe |
|---------|---------|
| Coluna | `founding_user` (`boolean`, default `false`, `NOT NULL`) |
| Índice | Único: uma linha `founding_user = true` por conta |
| Atribuição no create | `User#assign_founding_user` — `true` se ainda não existir outro usuário na conta |
| Defaults no create | `enforce_founding_user_defaults` força `role: owner` e `active: true` |
| Backfill (deploy) | Migration [`db/migrate/20260529194406_add_founding_user_to_users.rb`](db/migrate/20260529194406_add_founding_user_to_users.rb): menor `(created_at, id)` por conta vira fundador, `owner` e ativo |

```text
Conta nova                    Conta existente (após migrate)
     │                              │
     ▼                              ▼
Primeiro User#create          backfill founding_user
founding_user = true          no usuário mais antigo
role = owner                  da conta
active = true
```

### Regras de usuários (owners e fundador)

Regras aplicadas em [`app/models/user.rb`](app/models/user.rb), [`app/policies/user_policy.rb`](app/policies/user_policy.rb) e formulário em [`app/views/users/_form.html.erb`](app/views/users/_form.html.erb).

| Regra | Comportamento |
|-------|----------------|
| Fundador | `founding_user?` → não pode sair de `owner`, não pode ser desativado; função e ativo travados na UI |
| Conta com owner ativo | Sempre ≥ 1 usuário com `role: owner` e `active: true` (`account_owner_invariants`) |
| Último owner ativo | Não pode rebaixar (`owner` → `member`) nem desativar se for o único owner ativo restante (`would_remove_last_active_owner?`) |
| Editar a si mesmo | Não pode mudar a própria função (`updated_by` + `updater_cannot_change_own_role`; `UserPolicy#edit_role?` false para self) |
| Desativar (DELETE /users) | Bloqueado para self, fundador e último owner ativo (`UserPolicy#destroy?`) |
| Outros owners | Podem ser rebaixados ou desativados se outro `owner` ativo permanecer (em geral o fundador) |

Tentativas inválidas via PATCH em `/users/:id` retornam **422** com erros de validação (não há alteração silenciosa de `role`/`active` no controller).

Métodos úteis no model:

- `User#founding_user?` — coluna persistida
- `User#would_remove_last_active_owner?` — este registro é owner ativo e não há outro owner ativo na conta
- `User#locked_role?` / `User#locked_active?` — usados indiretamente pela policy/UI

### Papéis vs fundador

| Conceito | O que é |
|----------|---------|
| `role: owner` | Administrador da conta; pode haver vários; bypass da matriz de permissões |
| `founding_user: true` | Primeiro usuário da conta; no máximo um; imutável como owner ativo |
| `role: member` + grants | Acesso configurável em `/settings/permissions` |

Um usuário pode ser `owner` sem ser fundador (co-admin convidado depois). O fundador é sempre `owner`, mas nem todo `owner` é fundador.

## Cobrança automática e WhatsApp (Meta Cloud)

A régua de cobrança (`/settings/collection_ladder`) dispara lembretes para pendências de checklist conforme o prazo (`monthly_deadline_day` do cliente). O painel operacional fica em `/collection`.

### WhatsApp — plataforma Dokivo (v1)

Todos os escritórios usam o **mesmo número** configurado na plataforma. Credenciais em **Sistema → Plataforma** (recomendado) ou via ENV / `rails credentials:edit` (`whatsapp:`) como fallback. Exemplo em [`config/whatsapp.yml.example`](config/whatsapp.yml.example). A tela exibe a URL do webhook e o verify token (estilo Chatwoot inbox configuration).

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| `WHATSAPP_ACCESS_TOKEN` | Sim | Token permanente da Graph API |
| `WHATSAPP_PHONE_NUMBER_ID` | Sim | ID do número de envio |
| `WHATSAPP_APP_SECRET` | Sim | Validação do webhook (`X-Hub-Signature-256`) |
| `WHATSAPP_VERIFY_TOKEN` | Sim | Token do handshake GET do webhook |
| `WHATSAPP_WABA_ID` | Não | ID da conta Business (gestão de templates) |
| `WHATSAPP_API_VERSION` | Não | Padrão `v21.0` |

**Webhook Meta:** `GET/POST https://seu-dominio/webhooks/whatsapp`

Mensagens proativas exigem **templates aprovados** na WABA; informe o nome em cada degrau da régua (`whatsapp_template_name`).

Verificar configuração:

```bash
docker compose run web rails whatsapp:test
```

### Jobs

- `Collection::DailyTickJob` — cron Sidekiq às 08:00 (`America/Sao_Paulo`)
- Manual: `docker compose run web rails collection:tick`

### Opt-out

- E-mail: link «Cancelar lembretes» (`/collection/unsubscribe?token=...`)
- WhatsApp: cliente responde `PARAR` (ou `STOP`) — obrigatório antes de produção
