# 🗄️ Infraestrutura de Dados - PostgreSQL

## Recursos Criados

### 1. PostgreSQL Auth (postgres-auth.yaml)

**StatefulSet com armazenamento persistente para o serviço de autenticação**

- **Nome**: `postgres-auth`
- **Imagem**: `postgres:15-alpine`
- **Réplicas**: 1
- **Storage**: 5Gi (PersistentVolumeClaim)

**Configurações:**
```yaml
Database: auth_db
User: auth_user
Password: auth_password_123 (via secret)
Port: 5432
```

**Service:**
- Nome: `postgres-auth`
- Tipo: ClusterIP
- Port: 5432

**Secret:**
- Nome: `postgres-auth-secret`
- Key: `password`

**Recursos:**
- Requests: 256Mi RAM, 250m CPU
- Limits: 512Mi RAM, 500m CPU

---

### 2. PostgreSQL API (postgres-api.yaml)

**StatefulSet com armazenamento persistente para o serviço de API**

- **Nome**: `postgres-api`
- **Imagem**: `postgres:15-alpine`
- **Réplicas**: 1
- **Storage**: 5Gi (PersistentVolumeClaim)

**Configurações:**
```yaml
Database: api_db
User: api_user
Password: api_password_123 (via secret)
Port: 5432
```

**Service:**
- Nome: `postgres-api`
- Tipo: ClusterIP
- Port: 5432

**Secret:**
- Nome: `postgres-api-secret`
- Key: `password`

**Recursos:**
- Requests: 256Mi RAM, 250m CPU
- Limits: 512Mi RAM, 500m CPU

---

### 3. Elasticsearch (elasticsearch.yaml)

**Deployment com armazenamento persistente para logs e observabilidade**

- **Nome**: `elasticsearch`
- **Imagem**: `docker.elastic.co/elasticsearch/elasticsearch:8.11.0`
- **Réplicas**: 1
- **Storage**: 10Gi (PersistentVolumeClaim)

**Configurações:**
```yaml
Type: single-node
Security: disabled (xpack.security.enabled=false)
Java Heap: 512m
Port: 9200
```

**Service:**
- Nome: `elasticsearch`
- Port: 9200

---

## 🚀 Deploy

### Aplicar toda a infraestrutura:
```bash
./commands/apply-infra.sh
```

### Aplicar recursos individualmente:
```bash
kubectl apply -f k8s/infrastructure/postgres-auth.yaml
kubectl apply -f k8s/infrastructure/postgres-api.yaml
kubectl apply -f k8s/infrastructure/elasticsearch.yaml
kubectl apply -f k8s/infrastructure/kibana.yaml
```

---

## 🔗 Connection Strings

### PostgreSQL Auth
```bash
# Interno (dentro do cluster K8s)
postgresql://auth_user:auth_password_123@postgres-auth:5432/auth_db

# Port-forward para acesso local
kubectl port-forward service/postgres-auth 5432:5432
# Então conecte: localhost:5432
```

### PostgreSQL API
```bash
# Interno (dentro do cluster K8s)
postgresql://api_user:api_password_123@postgres-api:5432/api_db

# Port-forward para acesso local
kubectl port-forward service/postgres-api 5433:5432
# Então conecte: localhost:5433
```

### Elasticsearch
```bash
# Interno (dentro do cluster K8s)
http://elasticsearch:9200

# Port-forward para acesso local
kubectl port-forward service/elasticsearch 9200:9200
# Então acesse: http://localhost:9200
```

---

## 🔧 Comandos Úteis

### Verificar status dos recursos

```bash
# Ver StatefulSets
kubectl get statefulset

# Ver PVCs (Persistent Volume Claims)
kubectl get pvc

# Ver pods da infraestrutura
kubectl get pods -l app=postgres-auth
kubectl get pods -l app=postgres-api
kubectl get pods -l app=elasticsearch
```

### Acessar os bancos de dados

```bash
# PostgreSQL Auth
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db

# PostgreSQL API
kubectl exec -it statefulset/postgres-api -- psql -U api_user -d api_db
```

### Ver logs

```bash
# Logs PostgreSQL Auth
kubectl logs -f statefulset/postgres-auth

# Logs PostgreSQL API
kubectl logs -f statefulset/postgres-api

# Logs Elasticsearch
kubectl logs -f deployment/elasticsearch
```

### Backup dos bancos

```bash
# Backup PostgreSQL Auth
kubectl exec statefulset/postgres-auth -- pg_dump -U auth_user auth_db > backup-auth-$(date +%Y%m%d).sql

# Backup PostgreSQL API
kubectl exec statefulset/postgres-api -- pg_dump -U api_user api_db > backup-api-$(date +%Y%m%d).sql
```

### Restore dos bancos

```bash
# Restore PostgreSQL Auth
kubectl exec -i statefulset/postgres-auth -- psql -U auth_user auth_db < backup-auth.sql

# Restore PostgreSQL API
kubectl exec -i statefulset/postgres-api -- psql -U api_user api_db < backup-api.sql
```

---

## 🔐 Alterar Senhas

### Editar secrets diretamente:

```bash
# PostgreSQL Auth
kubectl edit secret postgres-auth-secret

# PostgreSQL API
kubectl edit secret postgres-api-secret
```

### Ou recriar o secret:

```bash
# PostgreSQL Auth
kubectl delete secret postgres-auth-secret
kubectl create secret generic postgres-auth-secret --from-literal=password=nova_senha_auth

# PostgreSQL API
kubectl delete secret postgres-api-secret
kubectl create secret generic postgres-api-secret --from-literal=password=nova_senha_api
```

### Reiniciar após mudança de senha:

```bash
kubectl rollout restart statefulset/postgres-auth
kubectl rollout restart statefulset/postgres-api
```

---

## 📊 Monitoramento

### Verificar uso de recursos:

```bash
# Ver uso de CPU e memória
kubectl top pods -l app=postgres-auth
kubectl top pods -l app=postgres-api
kubectl top pods -l app=elasticsearch
```

### Verificar espaço em disco:

```bash
# PostgreSQL Auth
kubectl exec statefulset/postgres-auth -- df -h /var/lib/postgresql/data

# PostgreSQL API
kubectl exec statefulset/postgres-api -- df -h /var/lib/postgresql/data

# Elasticsearch
kubectl exec deployment/elasticsearch -- df -h /usr/share/elasticsearch/data
```

---

## 🗑️ Remover Recursos

### Remover toda a infraestrutura:

```bash
./commands/remove.sh infrastructure
```

### Remover manualmente:

```bash
# Remover deployments/statefulsets
kubectl delete statefulset postgres-auth postgres-api
kubectl delete deployment elasticsearch

# Remover services
kubectl delete service postgres-auth postgres-api elasticsearch

# Remover secrets
kubectl delete secret postgres-auth-secret postgres-api-secret

# Remover PVCs (CUIDADO: Isso remove os dados!)
kubectl delete pvc postgres-auth-storage postgres-api-storage elastic-storage
```

---

## ⚠️ Notas Importantes

1. **Persistência**: Os dados são armazenados em PVCs. Se você deletar os PVCs, **perderá todos os dados**.

2. **Senhas Padrão**: As senhas padrão estão definidas nos secrets. **Altere-as em produção!**

3. **Recursos**: Os limites de CPU e memória podem precisar de ajuste baseado na carga.

4. **Backup**: Sempre faça backup antes de operações destrutivas.

5. **Elasticsearch**: Está configurado sem segurança (xpack.security.enabled=false) para desenvolvimento. **Habilite em produção!**

---

## 🔄 Manutenção

### Atualizar versão do PostgreSQL:

```yaml
# Edite postgres-auth.yaml e postgres-api.yaml
image: postgres:16-alpine  # Altere a versão

# Então aplique
kubectl apply -f k8s/infrastructure/postgres-auth.yaml
kubectl apply -f k8s/infrastructure/postgres-api.yaml
```

### Aumentar storage:

```yaml
# Edite o PVC
kubectl edit pvc postgres-auth-storage

# Altere o valor de storage
storage: 10Gi  # Aumente conforme necessário
```

**Nota**: Nem todos os storage classes suportam expansão dinâmica.

---

## 📚 Referências

- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Elasticsearch Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

