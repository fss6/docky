# Auditing

## Escopo inicial

- Auditoria de dados com `audited` no modelo `Folder`.
- Auditoria de eventos de negócio em `audit_events` para ações sem CRUD direto.

## Consultas recomendadas

- Por entidade: `Audit.where(auditable: record).order(created_at: :desc)`
- Por conta: `Audit.where(account_id: account_id).order(created_at: :desc)`
- Por usuário: `Audit.where(user: user).order(created_at: :desc)`
- Por eventos de negócio: `AuditEvent.where(account_id: account_id).order(created_at: :desc)`

## Retenção sugerida

- Manter dados online por 18 meses.
- Arquivar registros mais antigos para storage frio.
- Revisar crescimento mensal da tabela `audits` e `audit_events`.

## Campos sensíveis

- Não registrar conteúdos volumosos/sensíveis em trilha de alteração sem necessidade.
