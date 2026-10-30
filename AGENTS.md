# Tech Challenge — Guia para agentes (`infra-db`)

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP. Org [fiap-vcosta](https://github.com/fiap-vcosta). Rede e WIF ficam em `infra-bootstrap`; cluster/Gateway em `infra-k8s`.

## Antes de mudar código

1. Ler ADRs em [`docs/adrs/`](docs/adrs/) e decisões de custo/demo já tomadas
2. Espelhar módulos/pastas vizinhas; não inventar layout paralelo
3. Não rodar `apply`/`destroy` sem confirmação explícita do usuário
4. **Git:** nunca commit/push direto em `main` — branch → PR → merge (ver [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc))

## Responsabilidade

| Peça | Papel |
|------|--------|
| Terraform | Instância Cloud SQL compartilhada; outputs `instance_name` e `connection_name` |
| Rede | **Consumida** do `infra-bootstrap` via `terraform_remote_state` |
| State | Backend remoto (bucket) **persistente** entre demos |
| Fora de escopo | Database, usuário e secret de cada serviço; VPC/subnet/PSA, WIF e roles, GKE, API Gateway, código dos serviços |

## Regras canônicas (resumo)

- Apply/destroy manuais; CI só valida
- Este stack é descartável: nasce e morre na janela de demo
- Rede não se cria aqui; se falta algo na VPC, o PR é no `infra-bootstrap`
- State não morre no destroy da demo
- Sem secrets no Git

## Comandos

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
# plan/apply: só com backend configurado e confirmação humana
```
