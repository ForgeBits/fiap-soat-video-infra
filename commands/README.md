# Comandos de Gerenciamento K8s

Scripts utilitários para gerenciar os recursos Kubernetes do projeto.

## Pré-requisitos

- `kubectl` configurado e conectado ao cluster
- `envsubst` instalado (geralmente disponível no pacote `gettext`)
- Arquivo `.env` na raiz do projeto com as variáveis de ambiente necessárias

---

## Scripts Disponíveis

### `apply-all.sh`

Aplica **TODOS** os recursos K8s do projeto na ordem correta.

**Uso:**
```bash
./commands/apply-all.sh
```

**O que faz:**
1. Carrega as variáveis de ambiente do arquivo `.env`
2. Cria o namespace `fiapx` (se não existir)
3. Aplica recursos na ordem:
   - **Infrastructure**: PostgreSQL Auth, PostgreSQL API, Redis API, Elasticsearch, Kibana
   - **RabbitMQ**: Message broker
   - **Auth Service**: Serviço de autenticação
   - **API Service**: Serviço principal da aplicação
4. Aguarda pods ficarem prontos entre cada etapa
5. Exibe status final de todos os pods

**Ordem de aplicação garantida:**
```
1. Namespace fiapx
2. PostgreSQL Auth + PostgreSQL API + Redis + Elasticsearch + Kibana
3. RabbitMQ (depende de bancos)
4. Auth Service (depende de PostgreSQL Auth)
5. API Service (depende de todos os anteriores)
```

**Tempo estimado:** 3-5 minutos (dependendo do cluster)

---

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

**Serviços disponíveis:** `auth`, `api`, `rabbitmq`, `infrastructure`

**Exemplo:**
```bash
# Remover serviço auth
./commands/remove.sh auth

# Remover serviço api
./commands/remove.sh api

# Remover serviço rabbitmq
./commands/remove.sh rabbitmq

# Remover toda infraestrutura (PostgreSQL, Elasticsearch, Kibana)
./commands/remove.sh infrastructure
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

**Serviços disponíveis:** `auth`, `api`, `rabbitmq`

**Exemplo:**
```bash
# Reiniciar serviço auth após alterar uma env
./commands/restart.sh auth

# Reiniciar serviço api
./commands/restart.sh api

# Reiniciar serviço rabbitmq
./commands/restart.sh rabbitmq
```

**O que faz:**
1. Executa `kubectl rollout restart` no deployment
2. Aguarda o rollout completar com `kubectl rollout status`

---

### `apply-infra.sh`

Aplica os recursos de infraestrutura K8s (PostgreSQL, Redis, Elasticsearch e Kibana).

**Uso:**
```bash
./commands/apply-infra.sh
```

**Recursos aplicados:**
- PostgreSQL Auth (statefulset + service + secret + PVC 5Gi)
- PostgreSQL API (statefulset + service + secret + PVC 5Gi)
- Redis API (deployment + service + PVC 2Gi)
- Elasticsearch (deployment + service + PVC 10Gi)
- Kibana (deployment + service)

**Detalhes dos Bancos de Dados:**

**PostgreSQL Auth:**
- Database: `auth_db`
- User: `auth_user`
- Password: Definida no secret `postgres-auth-secret`
- Service: `postgres-auth:5432`
- Storage: 5Gi (persistente)

**PostgreSQL API:**
- Database: `api_db`
- User: `api_user`
- Password: Definida no secret `postgres-api-secret`
- Service: `postgres-api:5432`
- Storage: 5Gi (persistente)

**Redis API:**
- Service: `redis-api:6379`
- Storage: 2Gi (persistente)
- Max Memory: 256MB (política: allkeys-lru)
- Persistence: AOF (append-only file)

**Elasticsearch:**
- Service: `elasticsearch:9200`
- Storage: 10Gi (persistente)

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

## Infraestrutura de Bancos de Dados

### PostgreSQL

O projeto utiliza dois bancos de dados PostgreSQL independentes, cada um com armazenamento persistente.

#### Conexão aos Bancos

**PostgreSQL Auth:**
```bash
# Dentro do cluster
Host: postgres-auth
Port: 5432
Database: auth_db
User: auth_user
Password: auth_password_123 (configurável no secret)

# Connection string
postgresql://auth_user:auth_password_123@postgres-auth:5432/auth_db
```

**PostgreSQL API:**
```bash
# Dentro do cluster
Host: postgres-api
Port: 5432
Database: api_db
User: api_user
Password: api_password_123 (configurável no secret)

# Connection string
postgresql://api_user:api_password_123@postgres-api:5432/api_db
```

#### Acessar o banco diretamente

```bash
# PostgreSQL Auth
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db

# PostgreSQL API
kubectl exec -it statefulset/postgres-api -- psql -U api_user -d api_db
```

#### Backup e Restore

```bash
# Backup PostgreSQL Auth
kubectl exec statefulset/postgres-auth -- pg_dump -U auth_user auth_db > backup-auth.sql

# Restore PostgreSQL Auth
kubectl exec -i statefulset/postgres-auth -- psql -U auth_user auth_db < backup-auth.sql

# Backup PostgreSQL API
kubectl exec statefulset/postgres-api -- pg_dump -U api_user api_db > backup-api.sql

# Restore PostgreSQL API
kubectl exec -i statefulset/postgres-api -- psql -U api_user api_db < backup-api.sql
```

#### Alterar Senha do PostgreSQL

Para alterar a senha, edite o secret correspondente:

```bash
# Editar secret do PostgreSQL Auth
kubectl edit secret postgres-auth-secret

# Editar secret do PostgreSQL API
kubectl edit secret postgres-api-secret
```

Após alterar, reinicie o StatefulSet:

```bash
# Reiniciar PostgreSQL Auth
kubectl rollout restart statefulset/postgres-auth

# Reiniciar PostgreSQL API
kubectl rollout restart statefulset/postgres-api
```

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

---

### `reset-all.sh`

Remove **TODOS** os recursos K8s do projeto.

**Uso:**
```bash
./commands/reset-all.sh
```

**O que faz:**
1. Remove todos os recursos K8s:
   - Auth (deployment, service, configmap, secret)
   - API (deployment, service, configmap, secret)
   - RabbitMQ (deployment, service, configmap, secret)
   - Infrastructure (PostgreSQL Auth, PostgreSQL API, Redis API, MinIO, Elasticsearch, Kibana)
   - PVCs (postgres-auth-storage, postgres-api-storage, redis-api-storage, minio-storage, elastic-storage)
2. Mostra instruções de como reaplicar manualmente

**Para reaplicar após remover:**
```bash
# Aplicar infraestrutura
./commands/apply-infra.sh

# Aplicar serviços
./commands/apply.sh rabbitmq
./commands/apply.sh auth
./commands/apply.sh api
```

---

### `load-test.sh`

Executa teste de carga no endpoint de processamento de vídeos.

**Uso:**
```bash
./commands/load-test.sh [REQUESTS_PER_SECOND] [DURATION] [URL] [VIDEO_FILE] [FORMAT] [FPS] [TOKEN]
```

**Parâmetros:**
| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `REQUESTS_PER_SECOND` | Número de requisições por segundo | 5 |
| `DURATION` | Duração do teste em segundos | 10 |
| `URL` | URL do endpoint | `http://localhost:8082/videos/process` |
| `VIDEO_FILE` | Caminho do arquivo de vídeo | `/home/mt-dev/Videos/OBS/2026-01-08 20-46-44.mp4` |
| `FORMAT` | Formato de saída | `png` |
| `FPS` | Frames por segundo | `15` |
| `TOKEN` | Token JWT de autenticação | Token padrão |

**Exemplos:**
```bash
# 5 requisições por segundo durante 10 segundos (padrão)
./commands/load-test.sh

# 10 requisições por segundo durante 30 segundos
./commands/load-test.sh 10 30

# 20 requisições por segundo durante 60 segundos em URL customizada
./commands/load-test.sh 20 60 http://api-service:8082/videos/process

# Exibir ajuda
./commands/load-test.sh --help
```

**O que faz:**
1. Envia múltiplas requisições POST paralelas ao endpoint
2. Cada requisição inclui o arquivo de vídeo especificado
3. Exibe o status de cada requisição (sucesso/falha)
4. Mostra um resumo ao final do teste

---

