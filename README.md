# infra-db

Terraform da instância compartilhada de **Cloud SQL / PostgreSQL** na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

- Cloud SQL PostgreSQL 16 (`tech-challenge-pg`, `db-g1-small`, sem HA, só IP privado)
- Uma instância para `ordem-servico-service`, `estoque-service` e `administrativo-service`
- Outputs: `instance_name`, `connection_name`
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`
- State remoto em GCS (o bucket é gerenciado pelo `infra-bootstrap`; `tf-destroy` não o apaga)

Database, usuário e senha de cada serviço ficam no Terraform do próprio serviço. Este stack não cria secret.

A rede não está aqui: VPC, subnet e o range/peering do Private Service Access que dá IP privado à instância pertencem ao [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap), que é persistente. Este stack lê a VPC pelo state dele ([`terraform/remote-state.tf`](terraform/remote-state.tf)) e é descartável: nasce e morre na janela de demo.

Root module: [`terraform/`](terraform/).

## State (GCS)

| Item | Valor |
|------|--------|
| Bucket | `vcosta-fiap-tech-challenge-tfstate` |
| Prefix deste repo | `infra-db` |
| Prefix lido por este repo | `infra-bootstrap` (rede) |
| Quem lê este prefix | Terraform de cada serviço PostgreSQL (`instance_name`, `connection_name`) |
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
- no bucket de state: `roles/storage.objectAdmin` (também para ler o state do bootstrap)

`roles/secretmanager.admin` continua na mesma SA, no `infra-bootstrap`: quem cria a senha é o Terraform de cada serviço. `roles/servicenetworking.networksAdmin` deixou de ser necessária: o peering do PSA saiu deste stack.

Org vars: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT_EMAIL`. Não há org var para o nome da instância: os serviços leem `instance_name` e `connection_name` deste state.

## Conexão

Os serviços conectam pelo Cloud SQL Auth Proxy (sidecar no cluster). O proxy autentica na instância via IAM. O login no PostgreSQL é o usuário e a senha criados no Terraform de cada serviço. O connection name sai do output `connection_name` (`project:region:instance`).

O tier `db-g1-small` deixa o default de `max_connections` em 50 para a instância inteira (o `db-f1-micro` fica em 25). O pool de cada serviço precisa caber nesse teto. A justificativa está na [ADR 003](docs/adrs/003-instancia-compartilhada.md).

## Comandos locais

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

Plan/apply local exigem ADC (`gcloud auth application-default login`) e backend GCS configurado (`terraform init` sem `-backend=false`).

## Ordem na demo

O `infra-bootstrap` já está aplicado e não entra neste ciclo. O destroy daqui não toca na rede dele.

Subida:

1. Este repo → Actions → **tf-apply** (a instância existe antes do Terraform dos serviços). Pode correr em paralelo com o `infra-k8s` → **tf-apply**.
2. `infra-events` → **tf-apply**
3. **tf-apply** de cada serviço (database, usuário e secret no repo do serviço)
4. Deploy dos serviços

Descida:

1. **tf-destroy** de cada serviço
2. `infra-events` → **tf-destroy**
3. `infra-k8s` → **tf-destroy**
4. Este repo → **tf-destroy**

A exclusão da instância remove os databases que estavam nela. Por isso os serviços descem antes.

Após destroy, o nome da instância Cloud SQL pode ficar reservado por alguns dias na GCP; se o próximo apply falhar por nome em uso, altere `db_instance_name` ou aguarde.

## Decisões (ADRs)

Ver [`docs/README.md`](docs/README.md): escolha do PostgreSQL e Cloud SQL na demo.

Diagrama de componentes da nuvem: README do [`infra-k8s`](https://github.com/fiap-vcosta/infra-k8s#componentes-nuvem). Modelo de dados (ER) da ordem de serviço: [`ordem-servico-service/docs/08_modelo-de-dados.md`](https://github.com/fiap-vcosta/ordem-servico-service/blob/main/docs/08_modelo-de-dados.md).

## Repos da org

| Repo | Papel | Diagrama / doc-chave |
|------|--------|----------------------|
| [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap) | Rede, WIF, AR, zona DNS | Persistente |
| [`infra-db`](https://github.com/fiap-vcosta/infra-db) | Instância Cloud SQL | ADRs (acima) |
| [`infra-events`](https://github.com/fiap-vcosta/infra-events) | Tópicos Pub/Sub | README |
| [`infra-k8s`](https://github.com/fiap-vcosta/infra-k8s) | GKE + Gateway + Cloud Run auth | [Componentes](https://github.com/fiap-vcosta/infra-k8s#componentes-nuvem) |
| [`ordem-servico-service`](https://github.com/fiap-vcosta/ordem-servico-service) | Ordens de serviço | [ER](https://github.com/fiap-vcosta/ordem-servico-service/blob/main/docs/08_modelo-de-dados.md) |
| [`estoque-service`](https://github.com/fiap-vcosta/estoque-service) | Estoque | README |
| [`orcamento-service`](https://github.com/fiap-vcosta/orcamento-service) | Orçamento | README |
| [`administrativo-service`](https://github.com/fiap-vcosta/administrativo-service) | Cadastros | README |
| [`autenticacao-service`](https://github.com/fiap-vcosta/autenticacao-service) | Login e JWT | README |
| [`building-blocks`](https://github.com/fiap-vcosta/building-blocks) | Pacote compartilhado | README |
| [`e2e`](https://github.com/fiap-vcosta/e2e) | Compose, BDD e contratos | README |

## Agentes

Ver [AGENTS.md](AGENTS.md).
