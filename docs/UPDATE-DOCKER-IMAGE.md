# 🔄 Como Atualizar Imagens Docker (Mesma Tag)

## ✅ Problema Resolvido

**Pergunta:** Se atualizei a imagem Docker com a mesma tag (`v2.0.2`), o `kubectl rollout restart` vai pegar a versão atualizada?

**Resposta:** Agora **SIM**! ✅

---

## 🔧 O Que Foi Configurado

### **1. Adicionado `imagePullPolicy: Always`**

**Antes:**
```yaml
containers:
  - name: api-app
    image: vineco/api-fiapx-11soat:v2.0.2
    ports:
      - containerPort: 3000
```

**Depois:**
```yaml
containers:
  - name: api-app
    image: vineco/api-fiapx-11soat:v2.0.2
    imagePullPolicy: Always  # ← ADICIONADO
    ports:
      - containerPort: 3000
```

**Onde:** 
- ✅ `k8s/api/deployment.yaml`
- ✅ `k8s/auth/deployment.yaml`

---

### **2. Script `restart.sh` Melhorado**

Agora o script:
1. Aplica o deployment (garante `imagePullPolicy: Always`)
2. Faz rollout restart (força pull da imagem)
3. Aguarda completar
4. Mostra status dos pods

---

## 🎯 Como Usar

### **Cenário: Você atualizou a imagem no Docker Hub**

**Exemplo:** Fez push de nova versão da API com a mesma tag `v2.0.2`:

```bash
# 1. Você buildou e fez push
docker build -t vineco/api-fiapx-11soat:v2.0.2 .
docker push vineco/api-fiapx-11soat:v2.0.2
```

**Agora no cluster:**

```bash
# 2. Reiniciar serviço (vai puxar imagem atualizada)
./commands/restart.sh api
```

**O que acontece:**
1. ✅ Aplica deployment com `imagePullPolicy: Always`
2. ✅ Faz rollout restart
3. ✅ Kubernetes **puxa a imagem do Docker Hub** novamente
4. ✅ Cria novos pods com a imagem atualizada
5. ✅ Termina pods antigos

---

## 📊 Comportamento do `imagePullPolicy`

### **`Always` (configurado agora):**
```yaml
imagePullPolicy: Always
```
- ✅ **SEMPRE** puxa a imagem do registry antes de criar o pod
- ✅ Funciona mesmo com a **mesma tag**
- ✅ Garante imagem atualizada

### **`IfNotPresent` (padrão Kubernetes):**
```yaml
imagePullPolicy: IfNotPresent
```
- ❌ Só puxa se **não tiver** a imagem localmente
- ❌ **Não funciona** com mesma tag
- ❌ Usa cache local mesmo se imagem foi atualizada

### **`Never`:**
```yaml
imagePullPolicy: Never
```
- ❌ **Nunca** puxa do registry
- ❌ Só usa imagens locais

---

## 🚀 Comandos Disponíveis

### **Reiniciar API:**
```bash
./commands/restart.sh api
```

### **Reiniciar Auth:**
```bash
./commands/restart.sh auth
```

### **Reiniciar RabbitMQ:**
```bash
./commands/restart.sh rabbitmq
```

### **Reiniciar Elasticsearch:**
```bash
./commands/restart.sh elasticsearch
```

### **Reiniciar Kibana:**
```bash
./commands/restart.sh kibana
```

---

## 📝 Fluxo Completo de Atualização

### **1. Desenvolvimento Local:**
```bash
# Fazer mudanças no código
vim src/controllers/videoController.js

# Build da imagem
docker build -t vineco/api-fiapx-11soat:v2.0.2 .

# Push para Docker Hub
docker push vineco/api-fiapx-11soat:v2.0.2
```

### **2. Atualizar no Cluster:**
```bash
# Reiniciar serviço (puxa imagem nova)
./commands/restart.sh api
```

### **3. Verificar:**
```bash
# Ver se pod novo está rodando
kubectl get pods -n fiapx -l app=api-service

# Ver logs do pod novo
kubectl logs -n fiapx -l app=api-service --tail=50

# Testar endpoint
curl http://localhost:8082/health/detailed
```

---

## ⚠️ Importante: Tags de Imagem

### **Boa Prática (Recomendado):**
```bash
# Usar tags únicas (timestamp, commit hash, etc)
docker build -t vineco/api-fiapx-11soat:v2.0.2-20260221-abc123 .
docker push vineco/api-fiapx-11soat:v2.0.2-20260221-abc123

# Atualizar deployment
vim k8s/api/deployment.yaml
# image: vineco/api-fiapx-11soat:v2.0.2-20260221-abc123

# Aplicar
kubectl apply -f k8s/api/deployment.yaml
```

**Vantagens:**
- ✅ Não precisa de `imagePullPolicy: Always`
- ✅ Controle de versões mais claro
- ✅ Rollback fácil
- ✅ Cache funciona corretamente

### **Prática Atual (com `imagePullPolicy: Always`):**
```bash
# Usar mesma tag
docker build -t vineco/api-fiapx-11soat:v2.0.2 .
docker push vineco/api-fiapx-11soat:v2.0.2

# Reiniciar
./commands/restart.sh api
```

**Desvantagens:**
- ⚠️ Sempre puxa imagem (mais lento)
- ⚠️ Dificulta rollback
- ⚠️ Usa mais banda

**Mas funciona!** ✅

---

## 🔍 Verificar se Imagem Foi Atualizada

### **Ver qual imagem o pod está usando:**
```bash
kubectl get pod -n fiapx -l app=api-service -o jsonpath='{.items[0].spec.containers[0].image}'
```

Output:
```
vineco/api-fiapx-11soat:v2.0.2
```

### **Ver quando a imagem foi puxada:**
```bash
kubectl describe pod -n fiapx -l app=api-service | grep -A 5 "Image:"
```

Output:
```
Image:          vineco/api-fiapx-11soat:v2.0.2
Image ID:       docker.io/vineco/api-fiapx-11soat@sha256:abc123...
```

### **Ver eventos do pod:**
```bash
kubectl get events -n fiapx --sort-by='.lastTimestamp' | grep -i pull
```

Output:
```
4m    Normal   Pulling    pod/api-service-xxx   Pulling image "vineco/api-fiapx-11soat:v2.0.2"
4m    Normal   Pulled     pod/api-service-xxx   Successfully pulled image
```

---

## 💡 Resumo

### **Antes (problema):**
```yaml
# Sem imagePullPolicy
image: vineco/api-fiapx-11soat:v2.0.2
```

**Resultado:** Rollout restart **NÃO** puxava imagem atualizada (usava cache)

### **Agora (resolvido):**
```yaml
image: vineco/api-fiapx-11soat:v2.0.2
imagePullPolicy: Always  # ← Força pull
```

**Resultado:** Rollout restart **SEMPRE** puxa imagem atualizada do Docker Hub ✅

### **Script Melhorado:**
```bash
./commands/restart.sh api
```

**Faz:**
1. Aplica deployment (com imagePullPolicy: Always)
2. Rollout restart
3. **Puxa imagem atualizada** ✅
4. Recria pods
5. Mostra status

---

## ✅ Checklist de Atualização

- [x] `imagePullPolicy: Always` em API deployment
- [x] `imagePullPolicy: Always` em Auth deployment
- [x] Script `restart.sh` aplica deployment antes de rollout
- [x] Script aguarda rollout completar
- [x] Script mostra status dos pods

**Tudo pronto! Agora `./commands/restart.sh api` vai puxar a imagem atualizada! 🚀**

---

## 🎯 Teste Agora

```bash
# 1. Fazer push da imagem atualizada
docker push vineco/api-fiapx-11soat:v2.0.2

# 2. Reiniciar no cluster
./commands/restart.sh api

# 3. Verificar
kubectl get pods -n fiapx -l app=api-service

# 4. Testar
curl http://localhost:8082/health/detailed
```

**Funcionando! ✅**

