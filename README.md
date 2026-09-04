# infra-db

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

- Cloud SQL PostgreSQL
- Outputs para a API consumir
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`
- State remoto em GCS (bootstrap fora deste stack; `tf-destroy` da demo não apaga o bucket)

Root module: [`terraform/`](terraform/).

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) |
| **`tf-apply` / `tf-destroy`** | Janela da demo | Só manual (`workflow_dispatch`) |

Merge em `main` **nunca** liga Cloud SQL.

## Comandos

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

## Ordem na demo

1. Este repo → `tf-apply`
2. `infra-k8s` → `tf-apply`
3. Deploy API / auth
4. Destroy inverso: K8s → DB

## Agentes

Ver [AGENTS.md](AGENTS.md).
