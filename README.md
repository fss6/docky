# README

## Account
```
- id
- name
- plan_id
- status
- has_many Users, Documents, Queries, Folders, Groups (TODO)
```

## User
```
- id
- account_id
- email
- name
- role
- has_many Queries, GroupMemberships
```

## Plan
```
- id
- name
- price
- max_documents (TODO)
- max_queries (TODO)
- storage_limit_mb (TODO)
- has_many Accounts (TODO)
```

## Subscription
```
- id
- account_id
- plan_id
- status
- current_period_end
- belongs_to Account, Plan (TODO)
```

> [!IMPORTANT]
> Subscription status
> - trialing (Ex: 7 dias grátis)
>   - cliente ainda não paga
>   - acesso liberado (às vezes com limite)
> - active
>    - pagamento ok
>    - acesso total conforme plano
> - past_due (pagamento falhou)
>    - cartão recusado
>    - tentativa de cobrança falhou
> - unpaid (dívida confirmada)
>    - várias tentativas falharam
>    - cliente não pagou
> - canceled (cancelado pelo usuário)
>    - não renova mais
>    - ainda pode usar até current_period_en
> - expired (acabou o período)
>    - trial terminou OU assinatura venceu
>    - sem pagamento ativo

## Folder
```
- id
- account_id
- name
- has_many Documents, FolderPermissions (TODO)
```

## Group
```
- id
- account_id
- name
- has_many GroupMemberships, FolderPermissions
```

## GroupMembership
```
- id
- group_id
- user_id
- belongs_to Group, User
```

> This Readme using [GitHub syntax](https://docs.github.com/pt/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).
