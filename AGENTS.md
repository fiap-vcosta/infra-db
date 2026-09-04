# Tech Challenge — Guia para agentes (`infra-db`)

Terraform da camada de **banco** (Cloud SQL / PostgreSQL) na GCP. Org [fiap-vcosta](https://github.com/fiap-vcosta). Cluster/Gateway ficam em `infra-k8s`.

## Antes de mudar código

1. Ler ADRs deste repo (quando existirem) e decisões de custo/demo da Fase 03
2. Espelhar módulos/pastas vizinhas; não inventar layout paralelo
3. Não rodar `apply`/`destroy` sem confirmação explícita do usuário
4. **Git:** nunca commit/push direto em `main` — branch → PR → merge (ver [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc))

## Responsabilidade

| Peça | Papel |
|------|--------|
| Terraform | Instância Cloud SQL, rede mínima necessária ao SQL, outputs para a API |
| State | Backend remoto (bucket) **persistente** entre demos |
| Fora de escopo | GKE, API Gateway, Function auth, código da API |

## Regras canônicas (resumo)

- Apply/destroy manuais; CI só valida
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
