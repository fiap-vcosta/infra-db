# infra-db

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

- VPC `techchallenge-vpc` + Private Service Access (IP privado do SQL)
- Cloud SQL PostgreSQL 16 (`techchallenge-pg`, `db-f1-micro`, sem HA)
- Database `techchallenge`, usuário `api`
- Senha em Secret Manager (gerada no apply)
- Outputs rígidos: `network_id`, `subnet_id`, `connection_name`, `db_name`, `db_user`, `db_password_secret_id`
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`
- State remoto em GCS (bootstrap fora deste stack; `tf-destroy` não apaga o bucket)

Root module: [`terraform/`](terraform/).

## State (GCS)

| Item | Valor |
|------|--------|
| Bucket | `vcosta-fiap-tech-challenge-tfstate` |
| Prefix deste repo | `infra-db` |
| Prefix do cluster | `infra-k8s` (mesmo bucket; backend no outro repo) |

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim |
| **CI** `plan` (OIDC) | PR | Sim |
| **`tf-apply` / `tf-destroy`** | Janela da demo | Só manual (`workflow_dispatch`) |

Merge em `main` **nunca** liga Cloud SQL.

## Roles da SA `github-actions` (least-privilege)

Bootstrap fora do Terraform. Roles usadas por este stack:

- `roles/viewer`
- `roles/cloudsql.admin`
- `roles/compute.networkAdmin`
- `roles/servicenetworking.networksAdmin`
- `roles/secretmanager.admin`
- no bucket de state: `roles/storage.objectAdmin`

OIDC (Workload Identity): Pool/Provider + bind `roles/iam.workloadIdentityUser` na SA — fora deste state.

Org vars: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT_EMAIL`.

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

Após destroy, o nome da instância Cloud SQL pode ficar reservado por alguns dias na GCP; se o próximo apply falhar por nome em uso, altere `db_instance_name` ou aguarde.

## Agentes

Ver [AGENTS.md](AGENTS.md).
