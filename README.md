# infra-db

> **Arquivado.** A instância Cloud SQL compartilhada (`tech-challenge-pg`) saiu do caminho oficial.

Cada serviço PostgreSQL provisiona a própria instância no Terraform do próprio repo (`administrativo-service-pg`, `estoque-service-pg`, `ordem-servico-service-pg`).

- Decisão: [`e2e` ADR 001 — 1 Cloud SQL por serviço](https://github.com/fiap-vcosta/e2e/blob/main/docs/adrs/001-instancia-cloud-sql-por-servico.md)
- Demo: `demo-up` / `demo-down` no [`e2e`](https://github.com/fiap-vcosta/e2e) (sem este repositório)

O histórico Git e as ADRs antigas deste repo permanecem só como registro. Não use este stack em novas demos.
