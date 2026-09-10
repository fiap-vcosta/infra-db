# ADR 002: Cloud SQL PostgreSQL na Demo GCP

**Data:** 10 de Setembro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

A aplicação já escolheu PostgreSQL ([ADR 001](001-escolha-banco-de-dados.md)). Na nuvem, precisamos de uma instância gerenciada, barata, alinhada à região `us-central1`, que nasça e morra com a janela de demo — sem misturar rede/WIF neste stack.

O problema a ser resolvido é: **Como provisionar o PostgreSQL na GCP com menor custo viável, state coerente e consumo seguro pela API no GKE?**

## 2. Decisão

- **Produto:** Cloud SQL for PostgreSQL 16, instância `tech-challenge-pg`, tier `db-f1-micro`, sem HA.
- **Rede:** somente **IP privado**, via VPC/subnet/PSA do [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap) (`terraform_remote_state`). Este repo **não** cria rede.
- **Acesso da API:** Cloud SQL Auth Proxy como sidecar no GKE + IAM (Workload Identity); senha do usuário `api` no Secret Manager (gerada no apply). Sem IP de banco em ConfigMap.
- **Ciclo de vida:** stack descartável — `tf-destroy` apaga o que este state gerencia. Bucket de state permanece no bootstrap.
- **Região / projeto:** `us-central1` / `vcosta-fiap-tech-challenge` (ver ADR 001 do [`infra-bootstrap`](https://github.com/fiap-vcosta/infra-bootstrap)).

## 3. Justificativa

* **Menor tier viável** para demo de minutos; HA e máquina maior seriam custo sem benefício acadêmico.
* **IP privado + Auth Proxy** evita expor o banco e evita embutir endpoint em manifesto; IAM do proxy casa com Workload Identity já desenhado no cluster.
* **Separação de stacks:** rede e IAM de CI no bootstrap (persistente); SQL aqui (descartável) — `tf-destroy` da demo não apaga a VPC nem o state.
* **Complementa a ADR 001:** engine na aplicação; este ADR fixa o *onde* e o *como* na GCP.

## 4. Alternativas Consideradas

* **Cloud SQL com IP público + allowlist:** mais simples de debugar; descartado por superfície de ataque e por não alinhar ao desenho VPC-native.
* **PostgreSQL em VM / GCE:** barato em teoria; operação e backup piores que Cloud SQL para a demo.
* **AlloyDB / tiers maiores / HA:** overkill de custo e complexidade.
* **Rede criada neste mesmo state:** acoplava destroy do SQL ao destroy da VPC e complicava o bootstrap; rejeitado na refatoração.
* **IAM database authentication (sem senha):** candidato futuro; exige grants IAM no banco e ajuste da connection string — deixado em aberto no README, não bloqueia a demo.

## 5. Consequências

### Positivas
* Apply/destroy manuais (`workflow_dispatch`) controlam o sangramento.
* Outputs estáveis (`connection_name`, user, secret id) para o deploy da API.
* State GCS fora do destroy da demo; próximo apply recria a instância.

### Negativas / Riscos (Mitigações)
* **`db-f1-micro` é limitado:** stress extremo pode saturar CPU/memória do SQL.
  * *Mitigação:* demo curta; HPA estressa a API, não o objetivo de saturar o banco.
* **Nome da instância reservado alguns dias após destroy.**
  * *Mitigação:* aguardar ou alterar `db_instance_name`.
* **Senha ainda existe** (além do IAM do proxy).
  * *Mitigação:* só no Secret Manager; nunca em Git/tfstate output; evoluir para IAM DB auth se couber depois.
