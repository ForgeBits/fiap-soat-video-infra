# FIAP-SOAT Video Infrastructure

Este repositório contém toda a infraestrutura e configuração de deploy para o ecossistema de processamento de vídeos da FIAP-X. O projeto utiliza Kubernetes para orquestração de containers, Terraform para provisionamento de recursos em nuvem e Locust para testes de carga.

## 🚀 Arquitetura do Sistema

A solução é composta pelos seguintes serviços:

*   **Auth Service (`auth.fiapx`):** Gerencia autenticação de usuários e emissão de tokens JWT.
*   **API Service (`api.fiapx`):** Interface principal para recebimento de vídeos e consulta de status de processamento.
*   **Worker Service (`worker.fiapx`):** Processador assíncrono que extrai frames de vídeos e realiza o processamento pesado.
*   **Kibana (`kibana.fiapx`):** Interface de visualização de logs e métricas.
*   **Infrastructure:** Componentes de suporte como PostgreSQL, Redis, RabbitMQ e Elasticsearch.
*   **Ingress Controller (NGINX):** Ponto único de entrada que roteia requisições baseadas em domínios para os serviços internos.

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter instalado:

*   **Kubernetes Cluster:** (Minikube, Docker Desktop ou Cloud Provider)
*   **kubectl:** Configurado para o seu cluster.
*   **NGINX Ingress Controller:** Ativado no seu cluster.
    *   *Minikube:* `minikube addons enable ingress`
*   **Docker:** Para build de imagens.

---

## 💻 Configuração Local

### 1. DNS Local
Para acessar os serviços pelos nomes de domínio customizados, adicione as seguintes entradas ao seu arquivo `/etc/hosts` (Linux/Mac) ou `C:\Windows\System32\drivers\etc\hosts` (Windows):

```text
# Substitua 127.0.0.1 pelo IP do seu Ingress Controller se necessário (ex: minikube ip)
127.0.0.1 auth.fiapx
127.0.0.1 api.fiapx
127.0.0.1 worker.fiapx
127.0.0.1 kibana.fiapx
```

### 2. Subir o Ambiente
Utilize o script de automação para realizar o deploy completo de toda a infraestrutura e serviços:

```bash
./commands/up.sh
```
Este comando criará o namespace `fiapx`, aplicará todos os manifestos de infraestrutura, bancos de dados, serviços, ingress e executará as migrações necessárias.

---

## 📊 Testes de Carga (Locust)

O ambiente inclui uma instância do Locust pré-configurada para testar a escalabilidade do sistema.

*   **Acesso:** [http://localhost:8089](http://localhost:8089) (ou via Ingress se configurado)
*   **Comportamento:** O script simula usuários registrando, logando e enviando vídeos para processamento.
*   **Dashboard:** As métricas estão separadas por prefixos: `AUTH:`, `API:` e `WORKER:`.

Para recarregar o script do Locust após alterações:
```bash
./commands/reload.sh locust-auth
```

---

## 📂 Estrutura do Projeto

*   `k8s/`: Manifestos Kubernetes organizados por serviço.
    *   `infrastructure/`: Bancos de dados (Postgres, Redis) e logs (Elasticsearch).
    *   `rabbitmq/`: Mensageria assíncrona.
    *   `ingress.yaml`: Configuração central de roteamento NGINX.
*   `terraform/`: Código para provisionamento de infraestrutura em nuvem (EKS, RDS, S3).
*   `commands/`: Scripts utilitários para facilitar o gerenciamento (`up.sh`, `reload.sh`, `down.sh`).

---

## 📈 Escalabilidade e HPA

Os principais serviços (`auth`, `api` e `worker`) possuem **Horizontal Pod Autoscaler (HPA)** configurado para garantir a disponibilidade sob carga:

*   **Métricas:** O escalonamento é baseado no uso de **CPU** e **Memória**.
*   **Limites:** Geralmente configurado para manter o uso entre 50% e 80%, escalando entre 1 e 10 réplicas conforme a demanda detectada pelo `metrics-server`.

---

## ⚙️ Guia de Comandos

Utilize os scripts na pasta `commands/` para gerenciar o ciclo de vida da infraestrutura.

| Comando | Descrição |
| :--- | :--- |
| `./commands/up.sh` | Sobe todo o cluster (infra + serviços + ingress). |
| `./commands/down.sh` | Remove todos os recursos do Kubernetes (incluindo volumes). |
| `./commands/reload.sh [service]` | Recarrega ConfigMaps/Secrets e reinicia os pods de um serviço. |
| `./commands/stabilize.sh [service]` | Força a estabilização de réplicas do HPA para o mínimo. |

### Exemplos de Uso:

*   **Subir apenas um serviço:** `./commands/up.sh auth,api`
*   **Recarregar após mudar o .env:** `./commands/reload.sh api`
*   **Remover apenas o Locust:** `./commands/down.sh locust-auth`
*   **Acompanhar escalabilidade:** `kubectl get hpa -n fiapx`

---

## 🤝 Contribuindo

FIAP SOAT - Projeto Acadêmico de Processamento de Vídeos.
