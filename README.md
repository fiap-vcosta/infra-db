# infra-db

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

- Cloud SQL PostgreSQL 16 (`tech-challenge-pg`, `db-f1-micro`, sem HA, só IP privado)
- Database `techchallenge`, usuário `api`
- Senha em Secret Manager (gerada no apply)
- Outputs rígidos: `connection_name`, `db_name`, `db_user`, `db_password_secret_id`
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`
- State remoto em GCS (o bucket é gerenciado pelo `infra-bootstrap`; `tf-destroy` não o apaga)

A rede não está aqui: VPC, subnet e o range/peering do Private Service Access que dá IP privado à instância pertencem ao [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap), que é persistente. Este stack lê a VPC pelo state dele ([`terraform/remote-state.tf`](terraform/remote-state.tf)) e é descartável: nasce e morre na janela de demo.

Root module: [`terraform/`](terraform/).

## State (GCS)

| Item | Valor |
|------|--------|
| Bucket | `vcosta-fiap-tech-challenge-tfstate` |
| Prefix deste repo | `infra-db` |
| Prefix lido por este repo | `infra-bootstrap` (rede) |
| Prefix do cluster | `infra-k8s` (mesmo bucket; backend no outro repo) |

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim |
| **CI** `plan` (OIDC) | PR | Sim |
| **`tf-apply` / `tf-destroy`** | Janela da demo | Só manual (`workflow_dispatch`) |

Merge em `main` **nunca** liga Cloud SQL.

## Roles da SA `github-actions` (least-privilege)

A service account, o OIDC (pool/provider + `roles/iam.workloadIdentityUser` por repositório) e as roles são código no `infra-bootstrap`. Deste conjunto, este stack usa:

- `roles/viewer` — ler a VPC referenciada pela instância
- `roles/cloudsql.admin`
- `roles/secretmanager.admin`
- no bucket de state: `roles/storage.objectAdmin` (também para ler o state do bootstrap)

`roles/servicenetworking.networksAdmin` deixou de ser necessária: o peering do PSA saiu deste stack.

Org vars: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT_EMAIL`.

## Autenticação no banco

A API se conecta pelo Cloud SQL Auth Proxy (sidecar no cluster), que resolve transporte e credencial de acesso à instância via IAM, mas o login no PostgreSQL continua usuário/senha. A senha é gerada no apply e guardada no Secret Manager como `infra-db-api-db-password`; o valor nunca aparece em output, log ou Git — o deploy da `api` a lê do Secret Manager pela org var `GCP_DB_PASSWORD_SECRET`.

A alternativa é IAM database authentication (`cloudsql.iam_authentication` na instância + `--auto-iam-authn` no proxy), que elimina a senha. Fica registrada como decisão em aberto porque exige resolver os grants do usuário IAM no banco e ajustar a connection string da aplicação.

## Comandos locais

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

Plan/apply local exigem ADC (`gcloud auth application-default login`) e backend GCS configurado (`terraform init` sem `-backend=false`).

## Ordem na demo

1. Este repo → Actions → **tf-apply**
2. `infra-k8s` → **tf-apply**
3. Deploy API / auth
4. Destroy inverso: K8s → este repo (**tf-destroy**)

O `infra-bootstrap` não entra nesse ciclo: ele é pré-requisito aplicado uma vez, e o destroy daqui não toca na rede dele. Isso também elimina a corrida entre apagar a instância e apagar o peering do PSA, que antes exigia espera no destroy.

Após destroy, o nome da instância Cloud SQL pode ficar reservado por alguns dias na GCP; se o próximo apply falhar por nome em uso, altere `db_instance_name` ou aguarde.

## Decisões (ADRs)

Ver [`docs/README.md`](docs/README.md): escolha do PostgreSQL e Cloud SQL na demo.

## Agentes

Ver [AGENTS.md](AGENTS.md).
