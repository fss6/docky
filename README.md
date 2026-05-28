# Dokivo

Rails app run via Docker Compose (`web` + `worker` services).

## E-mail e background jobs

Active Job uses **Sidekiq** (Redis). The `web` container enqueues jobs; the `worker` container processes them (including SMTP delivery).

1. Copy [`.env.example`](.env.example) to `.env`.
2. Set `REDIS_URL` (same value for `web` and `worker` — `docker-compose.yml` uses `redis://redis:6379/0`).
3. Set `MAIL_DELIVERY=gmail` or `smtp` with credentials (must be present in `.env` so **worker** can send mail).
4. Start: `docker compose up web worker`

### Test upload invite e-mail

Open a client share link modal → **Enviar e-mail**. The UI shows **Envio em andamento…** immediately. After the worker runs, check logs and `AuditEvent` for `upload_invite.email_sent` or `upload_invite.email_failed`.

Monthly period opening is scheduled via **sidekiq-cron** in the worker (`Periods::OpenMonthJob`).

### Production deploy notes

- Deploy `web` and `worker` with the same `REDIS_URL`.
- If migrating from Solid Queue, drain pending `solid_queue_jobs` before relying only on Sidekiq.
