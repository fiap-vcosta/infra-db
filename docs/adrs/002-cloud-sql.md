# ADR 002: Cloud SQL PostgreSQL na Demo GCP

**Data:** 10 de Setembro de 2026  
**Atualizado:** 29 de outubro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

A aplicação já escolheu PostgreSQL ([ADR 001](001-escolha-banco-de-dados.md)). Na nuvem, precisamos de uma instância gerenciada, barata, alinhada à região `us-central1`, que nasça e morra com a janela de demo — sem misturar rede/WIF neste stack.

Três serviços usam PostgreSQL na mesma instância (`ordem-servico-service`, `estoque-service`, `administrativo-service`), cada um com database e usuário próprios. O tier `db-f1-micro` deixa o default de `max_connections` em 25 para a instância inteira.

O problema a ser resolvido é: **Como provisionar o PostgreSQL na GCP com o menor custo que ainda caiba nas conexões dos três serviços, state coerente e sem guardar usuário ou senha neste stack?**

## 2. Decisão

- **Produto:** Cloud SQL for PostgreSQL 16, instância `tech-challenge-pg`, tier `db-g1-small`, sem HA. Sem flag `max_connections`: o default do tier vale (50).
- **Escopo deste stack:** só a instância. Database, usuário e senha nascem no Terraform de cada serviço.
- **Rede:** somente **IP privado**, via VPC/subnet/PSA do [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap) (`terraform_remote_state`). Este repo **não** cria rede.
- **Acesso:** Cloud SQL Auth Proxy como sidecar no GKE. O proxy autentica na instância via IAM; o login no PostgreSQL é o usuário do serviço. Sem IP de banco em ConfigMap.
- **Outputs:** `instance_name` e `connection_name`, para o `terraform_remote_state` dos serviços.
- **Ciclo de vida:** stack descartável — `tf-destroy` apaga a instância. Sobe antes do `tf-apply` dos serviços; desce depois do `tf-destroy` deles. Bucket de state permanece no bootstrap.
- **Região / projeto:** `us-central1` / `vcosta-fiap-tech-challenge` (ver ADR 001 do [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap)).

## 3. Justificativa

* **`db-g1-small` continua shared-core.** O default de conexões passa de 25 para 50, o bastante para três serviços na mesma instância durante a demo. O compute sobe de US$ 0,0105/h para US$ 0,035/h (lista shared-core, sem HA, `us-central1`). Disco, backup desligado e IP privado não mudam.
* **IP privado + Auth Proxy** evita expor o banco e evita embutir endpoint em manifesto; IAM do proxy casa com Workload Identity já desenhado no cluster.
* **Separação de stacks:** rede e IAM de CI no bootstrap (persistente); a instância aqui (descartável); database, usuário e secret no repo de cada serviço. O `tf-destroy` da demo não apaga a VPC nem o state.
* **Complementa a ADR 001:** engine na aplicação; este ADR fixa o *onde* e o *como* na GCP.

## 4. Alternativas Consideradas

* **Permanecer em `db-f1-micro` e limitar o pool Npgsql em cada serviço:** menor custo de compute, com teto de 25 conexões na instância inteira. Rejeitado: três serviços e HPA dividem esse teto.
* **Núcleo dedicado (cobrança por vCPU e memória):** mais conexões e SLA; custa mais por hora do que o próximo shared-core. Fora do orçamento da demo.
* **Cloud SQL com IP público + allowlist:** mais simples de debugar; descartado por superfície de ataque e por não alinhar ao desenho VPC-native.
* **PostgreSQL em VM / GCE:** barato em teoria; operação e backup piores que Cloud SQL para a demo.
* **AlloyDB / HA:** overkill de custo e complexidade.
* **Rede criada neste mesmo state:** acoplava destroy do SQL ao destroy da VPC e complicava o bootstrap; rejeitado na refatoração.
* **Database, usuário e secret neste stack:** um único database `techchallenge` e usuário `api` não isolam os três serviços. Cada serviço passa a ser dono do seu database e da sua senha.
* **IAM database authentication (sem senha):** candidato futuro; exige grants IAM no banco e ajuste da connection string. Não bloqueia a demo.

## 5. Consequências

### Positivas
* Apply/destroy manuais (`workflow_dispatch`) controlam o sangramento.
* Outputs estáveis (`instance_name`, `connection_name`) para os serviços.
* State GCS fora do destroy da demo; próximo apply recria a instância.
* A senha de cada serviço não entra neste state.

### Negativas / Riscos (Mitigações)
* **`db-g1-small` continua pequeno** em CPU e memória, e o default de 50 conexões é da instância inteira.
  * *Mitigação:* demo curta; o pool de cada serviço precisa caber nesse teto.
* **Nome da instância reservado alguns dias após destroy.**
  * *Mitigação:* aguardar ou alterar `db_instance_name`.
* **Esquecer a instância ligada custa US$ 0,035/h de compute.**
  * *Mitigação:* `tf-destroy` ao fim da janela.
