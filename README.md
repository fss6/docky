# Dokivo

Rails app run via Docker Compose (`web` + `worker` services).

## Configuração de e-mail (SMTP)

A entrega de e-mail é controlada por [`config/initializers/action_mailer_delivery.rb`](config/initializers/action_mailer_delivery.rb). Copie [`.env.example`](.env.example) para `.env` e preencha as variáveis abaixo.

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
