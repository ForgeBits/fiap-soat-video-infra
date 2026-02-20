# fiap-soat-video-infra

Repositório de infraestrutura do projeto de microsserviços FIAP SOAT - Sistema de Processamento de Vídeos.

## 📋 Visão Geral

Este repositório contém toda a infraestrutura como código para deploy da aplicação em Kubernetes, incluindo:

- **Serviços de Aplicação**: Auth, API
- **Message Broker**: RabbitMQ
- **Bancos de Dados**: PostgreSQL (Auth e API)
- **Observabilidade**: Elasticsearch, Kibana
- **Infraestrutura Cloud**: Terraform (AWS EKS, RDS, S3, ElastiCache)

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐      │
│  │   Auth   │    │   API    │    │    RabbitMQ      │      │
│  │ Service  │◄───┤ Service  │◄───┤  Message Broker  │      │
│  └────┬─────┘    └────┬─────┘    └──────────────────┘      │
│       │               │                                      │
│  ┌────▼─────┐    ┌───▼──────┐    ┌──────────────────┐      │
│  │PostgreSQL│    │PostgreSQL│    │  Elasticsearch   │      │
│  │   Auth   │    │   API    │    │   + Kibana       │      │
│  │  (5Gi)   │    │  (5Gi)   │    │   (10Gi)         │      │
│  └──────────┘    └──────────┘    └──────────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Pré-requisitos

- `kubectl` configurado e conectado ao cluster
- `envsubst` instalado (pacote `gettext`)
- Arquivo `.env` na raiz do projeto

### Deploy Completo

```bash
# 1. Configurar variáveis de ambiente
cp .env.example .env
# Edite o .env com suas credenciais

# 2. Aplicar infraestrutura (PostgreSQL, Elasticsearch, Kibana)
./commands/apply-infra.sh

# 3. Aplicar RabbitMQ
./commands/apply.sh rabbitmq

# 4. Aplicar serviços
./commands/apply.sh auth
./commands/apply.sh api
```

### Reset Completo

```bash
# Remover e reaplicar tudo
./commands/reset-all.sh --rerun

# Apenas remover
./commands/reset-all.sh
```

## 📁 Estrutura do Projeto

```
.
├── commands/               # Scripts de gerenciamento
│   ├── apply.sh           # Aplicar serviço específico
│   ├── apply-infra.sh     # Aplicar infraestrutura
│   ├── apply-secrets.sh   # Reaplicar secrets
│   ├── remove.sh          # Remover serviço
│   ├── restart.sh         # Reiniciar serviço
│   ├── reset-all.sh       # Reset completo
│   ├── load-test.sh       # Teste de carga
│   └── README.md          # Documentação dos comandos
│
├── k8s/                   # Manifests Kubernetes
│   ├── auth/              # Serviço de autenticação
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── secret.yaml
│   │   └── service.yaml
│   ├── api/               # Serviço de API
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── secret.yaml
│   │   └── service.yaml
│   ├── rabbitmq/          # Message Broker
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── secret.yaml
│   │   └── service.yaml
│   └── infrastructure/    # Infraestrutura base
│       ├── postgres-auth.yaml
│       ├── postgres-api.yaml
│       ├── elasticsearch.yaml
│       └── kibana.yaml
│
└── terraform/             # Infraestrutura AWS
    ├── main.tf
    ├── eks.tf
    ├── rds.tf
    ├── s3.tf
    ├── vpc.tf
    ├── security_groups.tf
    └── cache_mq.tf
```

## 🗄️ Bancos de Dados

### PostgreSQL Auth
- **Host**: `postgres-auth:5432`
- **Database**: `auth_db`
- **User**: `auth_user`
- **Storage**: 5Gi (persistente)
- **Connection String**: `postgresql://auth_user:password@postgres-auth:5432/auth_db`

### PostgreSQL API
- **Host**: `postgres-api:5432`
- **Database**: `api_db`
- **User**: `api_user`
- **Storage**: 5Gi (persistente)
- **Connection String**: `postgresql://api_user:password@postgres-api:5432/api_db`

kubectl exec -it deployment/redis-api -- redis-cli
# Redis API

### Acessar Recursos

- **Persistence**: AOF (append-only file)
- **Eviction Policy**: allkeys-lru
- **Max Memory**: 256MB
- **Storage**: 2Gi (persistente)
- **Host**: `redis-api:6379`
### Redis API (Cache)

```bash
# PostgreSQL Auth
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db

# PostgreSQL API
kubectl exec -it statefulset/postgres-api -- psql -U api_user -d api_db
```

## 📊 Observabilidade

### Elasticsearch
- **URL**: `http://elasticsearch:9200`
- **Storage**: 10Gi (persistente)
- **Java Heap**: 512MB

### Kibana
- **URL**: `http://kibana:5601`
- **Dashboard**: Visualização de logs e métricas

### Acessar Kibana

```bash
# Port-forward para acessar localmente
kubectl port-forward service/kibana 5601:5601

# Acessar: http://localhost:5601
```

## 🐰 RabbitMQ

- **Management UI**: `http://rabbitmq:15672`
- **AMQP Port**: `5672`
- **Default User**: Configurado via secret

```bash
# Port-forward para acessar management UI
kubectl port-forward service/rabbitmq 15672:15672

# Acessar: http://localhost:15672
```

## 🔧 Comandos Úteis

Ver documentação completa em: [commands/README.md](./commands/README.md)

```bash
# Aplicar serviço
./commands/apply.sh <service>

# Remover serviço
./commands/remove.sh <service>

# Reiniciar serviço (após mudança de env)
./commands/restart.sh <service>

# Reaplicar secrets
./commands/apply-secrets.sh

# Teste de carga
./commands/load-test.sh [rps] [duration]

# Reset completo com reaplicação
./commands/reset-all.sh --rerun
```

## 🔐 Variáveis de Ambiente

Criar arquivo `.env` na raiz do projeto:

```env
# Auth Service
AUTH_POSTGRES_PASSWORD=sua_senha_auth
AUTH_DATABASE_URL=postgresql://auth_user:senha@postgres-auth:5432/auth_db
AUTH_JWT_SECRET=seu_jwt_secret_auth

# API Service
API_DB_PASSWORD=sua_senha_api
API_DATABASE_URL=postgresql://api_user:senha@postgres-api:5432/api_db
API_RABBITMQ_PASSWORD=sua_senha_rabbitmq
API_AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=sua_secret_key_aws
API_JWT_SECRET=seu_jwt_secret_api

# RabbitMQ
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=sua_senha_rabbitmq
```

## ☁️ Terraform (AWS)

Infraestrutura provisionada na AWS:

- **EKS**: Cluster Kubernetes
- **RDS**: PostgreSQL gerenciado
- **S3**: Armazenamento de objetos
- **ElastiCache**: Redis cache
- **VPC**: Rede privada
- **Security Groups**: Regras de firewall

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## 🧪 Testes

### Teste de Carga

```bash
# 10 requisições por segundo durante 30 segundos
./commands/load-test.sh 10 30

# Com configurações customizadas
./commands/load-test.sh 20 60 http://api-service:8082/videos/process
```

## 📝 Logs

```bash
# Ver logs de um serviço
kubectl logs -f deployment/auth-service
kubectl logs -f deployment/api-service
kubectl logs -f deployment/rabbitmq

# Ver logs de todos os pods de um serviço
kubectl logs -f -l app=auth-service
```

## 🔍 Troubleshooting

```bash
# Ver status dos pods
kubectl get pods

# Descrever pod com problemas
kubectl describe pod <pod-name>

# Ver eventos do cluster
kubectl get events --sort-by='.lastTimestamp'

# Verificar PVCs
kubectl get pvc

# Verificar secrets
kubectl get secrets
```

## 📚 Documentação Adicional

- [Comandos de Gerenciamento](./commands/README.md)
- [Terraform AWS](./terraform/README.md) _(se existir)_

## 🤝 Contribuindo

1. Clone o repositório
2. Crie uma branch para sua feature
3. Faça commit das mudanças
4. Abra um Pull Request

## 📄 Licença

FIAP SOAT - Projeto Acadêmico
