# 📋 Commands

Scripts para gerenciar o cluster Kubernetes do projeto FIAP SOAT Video.

## Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `./commands/up.sh` | Sobe todo o cluster |
| `./commands/down.sh` | Remove recursos do cluster |
| `./commands/reload.sh` | Recarrega configuração de um serviço |
| `./commands/stabilize.sh` | Força estabilização dos pods (HPA) |

---

## ▲ `up.sh` — Subir recursos

Aplica todos os recursos Kubernetes na ordem correta.

```bash
# Subir TUDO (infra + rabbitmq + auth + api)
./commands/up.sh

# Subir apenas um serviço
./commands/up.sh auth
./commands/up.sh api

# Subir múltiplos serviços
./commands/up.sh auth,api

# Subir infra + rabbitmq
./commands/up.sh infra,rabbitmq

# Subir tudo + locust (testes de carga)
./commands/up.sh --locust
```

**Ordem de execução (quando sobe tudo):**
1. Namespace `fiapx`
2. Infrastructure (PostgreSQL, Redis, Elasticsearch, Kibana)
3. RabbitMQ
4. Auth Service
5. API Service

**Serviços disponíveis:** `infra`, `rabbitmq`, `auth`, `api`, `locust`

---

## ▼ `down.sh` — Remover recursos

Remove recursos do cluster. Sem argumentos, remove **tudo**.

```bash
# Remover TUDO
./commands/down.sh

# Remover apenas um serviço
./commands/down.sh auth
./commands/down.sh api

# Remover múltiplos
./commands/down.sh auth,api

# Remover infra (PostgreSQL, Redis, etc + PVCs)
./commands/down.sh infra

# Remover locust
./commands/down.sh locust
```

**Serviços disponíveis:** `infra`, `rabbitmq`, `auth`, `api`, `locust`

---

## ↻ `reload.sh` — Recarregar configuração

Reaplicar configmap + secret de um serviço e reiniciar os pods para refletir as alterações.

**Quando usar:** Sempre que alterar uma variável de ambiente, configmap ou secret.

```bash
# Recarregar auth (ex: mudou uma env)
./commands/reload.sh auth

# Recarregar api
./commands/reload.sh api

# Recarregar múltiplos
./commands/reload.sh auth,api

# Recarregar rabbitmq
./commands/reload.sh rabbitmq
```

**O que faz:**
1. Reaplicar secret (com `envsubst` do `.env`)
2. Reaplicar configmap
3. Reaplicar deployment (garante `imagePullPolicy: Always`)
4. `rollout restart` para recriar os pods com a nova config

**Serviços disponíveis:** `auth`, `api`, `rabbitmq`, `locust`

---

## ⚖ `stabilize.sh` — Forçar estabilização de pods

Quando o HPA cria muitos pods e demora a reduzir, usa este comando para forçar a estabilização.

```bash
# Estabilizar auth no minReplicas (3 pods)
./commands/stabilize.sh auth

# Estabilizar auth em 5 pods
./commands/stabilize.sh auth 5

# Estabilizar api em 1 pod
./commands/stabilize.sh api 1
```

**O que faz:**
1. Remove o HPA temporariamente
2. Escala o deployment para o número de réplicas desejado
3. Aguarda pods extras serem removidos
4. Recria o HPA

**Serviços com HPA:** `auth`

---

## 📁 Estrutura

```
commands/
├── up.sh           # Subir recursos
├── down.sh         # Remover recursos
├── reload.sh       # Recarregar configuração
└── stabilize.sh    # Estabilizar pods (HPA)
```

---

## 💡 Cenários Comuns

### Primeira vez (setup completo)
```bash
./commands/up.sh
```

### Mudei uma variável de ambiente do auth
```bash
# 1. Edite o .env ou o configmap/secret
# 2. Recarregue
./commands/reload.sh auth
```

### Atualizei a imagem Docker da API
```bash
# 1. Push da imagem no Docker Hub
# 2. Recarregue (imagePullPolicy: Always vai puxar a nova)
./commands/reload.sh api
```

### HPA criou pods demais e não está reduzindo
```bash
./commands/stabilize.sh auth
```

### Quero remover só o locust (parar testes)
```bash
./commands/down.sh locust
```

### Quero limpar tudo e recomeçar
```bash
./commands/down.sh
./commands/up.sh
```

### Quero subir só a infra e o auth
```bash
./commands/up.sh infra,rabbitmq,auth
```

---

## ⚙️ Pré-requisitos

- **kubectl** configurado e conectado ao cluster
- **minikube** (ou outro cluster) rodando
- **Arquivo `.env`** na raiz do projeto com as variáveis de ambiente
- **envsubst** disponível (geralmente já vem no Linux)

### Verificar conectividade
```bash
kubectl get nodes        # Node deve estar "Ready"
kubectl get namespace fiapx
```

