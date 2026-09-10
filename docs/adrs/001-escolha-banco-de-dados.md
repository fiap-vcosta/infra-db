# ADR 001: Escolha do Banco de Dados Relacional Principal

**Data:** 12 de Maio de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

> Migrado do repo [`api`](https://github.com/fiap-vcosta/api) em Setembro/2026. A decisão de **engine** (PostgreSQL) permanece; o provisionamento gerenciado na GCP está na [ADR 002](002-cloud-sql.md).

## 1. Contexto e Problema

O nosso sistema gerencia Ordens de Serviço (OS) e Estoque. Trata-se de um domínio altamente transacional, onde a concorrência é um fator crítico. Durante a execução ou aprovação de uma OS, o sistema precisa verificar o saldo de peças, alocar os itens e registrar a baixa física do estoque. 

Se duas requisições tentarem utilizar a mesma peça simultaneamente, precisamos de mecanismos robustos para garantir que não haja "furos" de estoque (vender o que não se tem). Além disso, a arquitetura foi desenhada utilizando **Domain-Driven Design (DDD)**, **CQRS (via MediatR)** e **Entity Framework Core**, com operações que exigem transações atômicas (tudo ou nada) e bloqueios de concorrência na leitura (Pessimistic Locking / `Read-Modify-Write`).

O problema a ser resolvido é: **Qual banco de dados nos fornece a melhor sinergia com o Entity Framework Core, garantindo integridade transacional rigorosa, suporte nativo a bloqueios de linha e bom custo-benefício?**

## 2. Decisão

Nós decidimos utilizar o **PostgreSQL** como o banco de dados relacional principal da aplicação.

## 3. Justificativa

A escolha do PostgreSQL se baseia nos seguintes pilares:

* **Integridade ACID Rigorosa:** O PostgreSQL é reconhecido por sua extrema confiabilidade e conformidade com as propriedades ACID (Atomicidade, Consistência, Isolamento e Durabilidade), essenciais para o nosso contexto financeiro e de estoque.
* **Suporte a Pessimistic Locking:** O banco suporta nativamente a instrução `FOR UPDATE`, que se integra perfeitamente ao Entity Framework Core (via `FromSqlRaw`), permitindo travar linhas específicas da tabela de estoque durante o ciclo de vida de uma transação da Ordem de Serviço, evitando *Race Conditions*.
* **Custo e Escalabilidade (Open-Source):** Diferente de soluções proprietárias (como SQL Server ou Oracle), o PostgreSQL é de código aberto e livre de custos de licenciamento comercial. Ele pode ser escalado horizontalmente e verticalmente com extrema facilidade em qualquer provedor de nuvem (AWS RDS, Azure Database for PostgreSQL, Google Cloud SQL).

## 4. Alternativas Consideradas

* **Microsoft SQL Server:** Excelente sinergia com .NET e suporta `WITH (UPDLOCK)`. Foi descartado puramente pelo alto custo de licenciamento em ambientes de produção de larga escala, dado que o PostgreSQL atende aos mesmos requisitos de forma gratuita.
* **MySQL:** Embora seja open-source e muito popular, o PostgreSQL oferece uma governança mais robusta para transações complexas, melhor conformidade com o padrão SQL e recursos mais avançados de tipos de dados (como JSONB), que podem ser úteis para a evolução do sistema.
* **Bancos de Dados NoSQL (ex: MongoDB):** Descartados porque o nosso domínio é intrinsecamente relacional. Uma Ordem de Serviço possui Serviços, que por sua vez necessitam de Peças que estão no Estoque. Garantir bloqueios pessimistas e transações atômicas entre múltiplos "documentos" no NoSQL traria uma complexidade acidental desnecessária ao código.

## 5. Consequências

### Positivas
* O sistema não terá furos de estoque, pois as linhas bloqueadas com `FOR UPDATE` obrigarão requisições concorrentes a entrarem em fila.
* Economia significativa em infraestrutura por não haver custos de licenciamento.
* Flexibilidade para armazenar dados não-estruturados no futuro usando colunas `JSONB`, sem precisar adicionar um banco NoSQL à stack.

### Negativas / Riscos (Mitigações)
* **Deadlocks:** Ao usar travas pessimistas, há o risco de *Deadlocks* (dois processos esperando um pelo outro). 
  * *Mitigação:* O time de desenvolvimento deve sempre ordenar os IDs (`OrderBy`) antes de aplicar o lock no repositório, garantindo que as requisições concorrentes sempre tentem bloquear os recursos na mesma ordem.
* **Sintaxe Específica:** Consultas cruas (`FromSqlRaw`) usando `FOR UPDATE` acoplam levemente o repositório à sintaxe do PostgreSQL.
  * *Mitigação:* O uso dessas consultas é estritamente isolado nas classes de Repositório (`Infrastructure`), nunca vazando para o Domínio ou para a camada de Aplicação.
