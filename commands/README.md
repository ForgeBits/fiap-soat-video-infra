# Comandos de Gerenciamento K8s

Scripts utilitários para gerenciar os recursos Kubernetes do projeto.

## Pré-requisitos

- `kubectl` configurado e conectado ao cluster
- `envsubst` instalado (geralmente disponível no pacote `gettext`)
- Arquivo `.env` na raiz do projeto com as variáveis de ambiente necessárias

---

## Scripts Disponíveis

### `apply-secrets.sh`

Remove e reaplica os secrets dos serviços **auth** e **api**.

**Uso:**
```bash
./commands/apply-secrets.sh
```

**O que faz:**
1. Carrega as variáveis de ambiente do arquivo `.env`
2. Remove os secrets `auth-secret` e `api-secret` (se existirem)
3. Reaplica os secrets usando `envsubst` para substituir as variáveis

---

### `remove.sh`

Remove todos os recursos K8s de um serviço específico.

**Uso:**
```bash
./commands/remove.sh <service>
```

**Serviços disponíveis:** `auth`, `api`, `rabbitmq`

**Exemplo:**
```bash
# Remover serviço auth
./commands/remove.sh auth

# Remover serviço api
./commands/remove.sh api

# Remover serviço rabbitmq
./commands/remove.sh rabbitmq
```

**Recursos removidos:**
- Service
- Deployment
- ConfigMap
- Secret

---

### `restart.sh`

Reinicia os pods de um serviço para refletir alterações em secrets ou configmaps.

**Uso:**
```bash
./commands/restart.sh <service>
```

**Serviços disponíveis:** `auth`, `api`, `rabbitmq`, `elasticsearch`, `kibana`

**Exemplo:**
```bash
# Reiniciar serviço auth após alterar uma env
./commands/restart.sh auth

# Reiniciar serviço api
./commands/restart.sh api
```

**O que faz:**
1. Executa `kubectl rollout restart` no deployment
2. Aguarda o rollout completar com `kubectl rollout status`

---

### `apply-infra.sh`

Aplica os recursos de infraestrutura K8s (Elasticsearch e Kibana).

**Uso:**
```bash
./commands/apply-infra.sh
```

**Recursos aplicados:**
- Elasticsearch (deployment + service)
- Kibana (deployment + service)

---

### `apply.sh`

Aplica todos os recursos K8s de um serviço específico (**auth** ou **api**).

**Uso:**
```bash
# Aplicar serviço auth
./commands/apply.sh auth

# Aplicar serviço api
./commands/apply.sh api
```

**O que faz:**
1. Carrega as variáveis de ambiente do arquivo `.env`
2. Aplica os recursos na ordem correta:
   - Secret (com substituição de variáveis via `envsubst`)
   - ConfigMap
   - Deployment
   - Service

---

### `reset-auth.sh`

Remove todos os recursos K8s do serviço **auth** e opcionalmente reaplica.

**Uso:**
```bash
# Apenas remover os recursos
./commands/reset-auth.sh

# Remover e reaplicar automaticamente
./commands/reset-auth.sh --reapply
./commands/reset-auth.sh -r
```

**Recursos gerenciados:**
- `auth-deployment`
- `auth-service`
- `auth-configmap`
- `auth-secret`

---

### `reset-api.sh`

Remove todos os recursos K8s do serviço **api** e opcionalmente reaplica.

**Uso:**
```bash
# Apenas remover os recursos
./commands/reset-api.sh

# Remover e reaplicar automaticamente
./commands/reset-api.sh --reapply
./commands/reset-api.sh -r
```

**Recursos gerenciados:**
- `api-deployment`
- `api-service`
- `api-configmap`
- `api-secret`

---

## Variáveis de Ambiente

O arquivo `.env` na raiz do projeto deve conter as seguintes variáveis:

### Para o serviço Auth:
| Variável | Descrição |
|----------|-----------|
| `AUTH_POSTGRES_PASSWORD` | Senha do PostgreSQL |
| `AUTH_DATABASE_URL` | URL de conexão com o banco |
| `AUTH_JWT_SECRET` | Secret para geração de JWT |

### Para o serviço API:
| Variável | Descrição |
|----------|-----------|
| `API_DB_PASSWORD` | Senha do banco de dados |
| `API_DATABASE_URL` | URL de conexão com o banco |
| `API_RABBITMQ_PASSWORD` | Senha do RabbitMQ |
| `API_AWS_ACCESS_KEY_ID` | AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key |
| `API_JWT_SECRET` | Secret para validação de JWT |

---

## Exemplo de `.env`

```env
# Auth Service
AUTH_POSTGRES_PASSWORD=sua_senha_auth
AUTH_DATABASE_URL=postgresql://user:pass@host:5432/auth_db
AUTH_JWT_SECRET=seu_jwt_secret_auth

# API Service
API_DB_PASSWORD=sua_senha_api
API_DATABASE_URL=postgresql://user:pass@host:5432/api_db
API_RABBITMQ_PASSWORD=sua_senha_rabbitmq
API_AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=sua_secret_key_aws
API_JWT_SECRET=seu_jwt_secret_api
```

