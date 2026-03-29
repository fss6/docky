# README

## Account
 ├── id<br/>
 ├── name<br/>
 ├── plan_id<br/>
 ├── status<br/>
 └── has_many Users, Documents, Queries, Folders, Groups (TODO)

## User
 ├── id<br/>
 ├── account_id<br/>
 ├── email<br/>
 ├── name<br/>
 ├── role<br/>
 └── has_many Queries, GroupMemberships

## Plan
 ├── id<br/>
 ├── name<br/>
 ├── price<br/>
 ├── max_documents (TODO)<br/>
 ├── max_queries (TODO)<br/>
 ├── storage_limit_mb (TODO)<br/>
 └── has_many Accounts (TODO)

## Subscription
 ├── id<br/>
 ├── account_id<br/>
 ├── plan_id<br/>
 ├── status<br/>
 ├── current_period_end<br/>
 └── belongs_to Account, Plan (TODO)

 ### Statuses
 - trialing (Ex: 7 dias grátis)
    - cliente ainda não paga
    - acesso liberado (às vezes com limite)
- active
    - pagamento ok
    - acesso total conforme plano
- past_due (pagamento falhou)
    - cartão recusado
    - tentativa de cobrança falhou
- unpaid (dívida confirmada)
    - várias tentativas falharam
    - cliente não pagou
- canceled (cancelado pelo usuário)
    - não renova mais
    - ainda pode usar até current_period_en
- expired (acabou o período)
    - trial terminou OU assinatura venceu
    - sem pagamento ativo

## Folder
 ├── id<br/>
 ├── account_id<br/>
 ├── name<br/>
 └── has_many Documents, FolderPermissions (TODO)

 ## Group
 ├── id<br/>
 ├── account_id<br/>
 ├── name<br/>
 └── has_many GroupMemberships, FolderPermissions

## GroupMembership
 ├── id<br/>
 ├── group_id<br/>
 ├── user_id<br/>
 └── belongs_to Group, User