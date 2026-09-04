# infra-db

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

| Inclui | Não inclui |
|--------|------------|
| Cloud SQL PostgreSQL (na §4) | GKE, API Gateway, Function auth |
| Outputs para a API consumir | Código da API |

- Região: **`us-central1`**
- Projeto: `vcosta-fiap-tech-challenge`
- State remoto GCS: bootstrap **fora** deste stack (§4) — `tf-destroy` da demo não apaga o bucket de state

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) |
| **`tf-apply` / `tf-destroy`** | Janela da demo | Só manual (`workflow_dispatch`) — §4 |

Merge em `main` **nunca** liga Cloud SQL.

## Layout atual (§3)

Scaffold Terraform vazio (válido para `validate`). Recursos e backend GCS entram na **§4**.

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
```

## Ordem na demo

1. Este repo → `tf-apply` (quando existir)
2. `infra-k8s` → `tf-apply`
3. Deploy API / auth
4. Destroy inverso: K8s → DB

Ver processo em `local/FASE03-PROCESSO-DEMO.md` (workspace local).

## Agentes

Ver [AGENTS.md](AGENTS.md).
