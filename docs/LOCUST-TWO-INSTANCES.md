# 🦗 Duas Instâncias do Locust

## 📋 Visão Geral

Agora temos **2 instâncias separadas** do Locust:

| Instância | Testa | Host | Porta UI |
|-----------|-------|------|----------|
| **locust-auth** | Auth Service | `http://auth-service:3000` | 8089 |
| **locust-api** | API Service | `http://api-service:3001` | 8090 |

---

## 🚀 Deploy

### **Subir ambos:**
```bash
./commands/up.sh --locust
```

### **Subir apenas Locust Auth:**
```bash
./commands/up.sh locust-auth
```

### **Subir apenas Locust API:**
```bash
./commands/up.sh locust-api
```

---

## 🌐 Acessar

### **1. Port-forward para Locust Auth:**
```bash
kubectl port-forward -n fiapx service/locust-master 8089:8089
```

Acessar: **http://localhost:8089**

### **2. Port-forward para Locust API (em outro terminal):**
```bash
kubectl port-forward -n fiapx service/locust-api-master 8090:8090
```

Acessar: **http://localhost:8090**

---

## 🧪 Configurar Testes

### **Locust Auth (porta 8089):**
```
Host: http://auth-service:3000
Users: 100
Spawn rate: 10
```

**Endpoints testados:**
- `POST /auth/register` (56%)
- `POST /auth/login` (28%)
- `POST /auth/validate` (16%)

### **Locust API (porta 8090):**
```
Host: http://api-service:3001
Users: 50
Spawn rate: 5
```

**Endpoints testados:**
- `GET /videos` (59%)
- `GET /videos/:id` (29%)
- `POST /videos/process` (12%)

---

## 📊 Pods

### **Locust Auth:**
```
locust-master (1 pod)      → UI + Execução
```

### **Locust API:**
```
locust-api-master (1 pod)  → UI + Execução
```

**Total: 2 pods do Locust**

---

## 🔧 Gerenciar

### **Recarregar script do Locust Auth:**
```bash
# Editar configmap
kubectl edit configmap locust-script -n fiapx

# Aplicar
./commands/reload.sh locust-auth
```

### **Recarregar script do Locust API:**
```bash
# Editar configmap
kubectl edit configmap locust-api-script -n fiapx

# Aplicar
./commands/reload.sh locust-api
```

### **Remover:**
```bash
# Ambos
./commands/down.sh locust-auth,locust-api

# Apenas um
./commands/down.sh locust-auth
./commands/down.sh locust-api
```

---

## 🎯 Cenário de Teste Completo

**Terminal 1 - Port-forward Auth:**
```bash
kubectl port-forward -n fiapx service/locust-master 8089:8089
```

**Terminal 2 - Port-forward API:**
```bash
kubectl port-forward -n fiapx service/locust-api-master 8090:8090
```

**Terminal 3 - Monitorar HPA Auth:**
```bash
watch kubectl get hpa auth-service-hpa -n fiapx
```

**Terminal 4 - Monitorar HPA API:**
```bash
watch kubectl get hpa api-service-hpa -n fiapx
```

**Browser 1:** http://localhost:8089 → Teste Auth  
**Browser 2:** http://localhost:8090 → Teste API  

**Iniciar ambos simultaneamente e observar o autoscaling! 🚀**

---

## 📁 Estrutura

```
k8s/
├── locust-auth/
│   ├── configmap.yaml     # Script Python (Auth)
│   ├── deployment.yaml    # Standalone (Master)
│   └── service.yaml       # Porta 8089
│
└── locust-api/
    ├── configmap.yaml     # Script Python (API)
    ├── deployment.yaml    # Standalone (Master)
    └── service.yaml       # Porta 8090
```

---

## 💡 Vantagens

✅ **Independentes** - Testar Auth e API separadamente  
✅ **Portas diferentes** - Rodar ambos simultaneamente  
✅ **Scripts específicos** - Otimizado para cada serviço  
✅ **Fácil de gerenciar** - Comandos simples  

---

## 🎨 Diferenças nos Testes

### **Locust Auth:**
- Wait time: 0-1s (rápido)
- Foco: Autenticação e validação de tokens
- RPS esperado: 50-100

### **Locust API:**
- Wait time: 1-3s (mais lento devido a uploads)
- Foco: Listagem e processamento de vídeos
- RPS esperado: 10-30
- Upload de vídeo fake (1KB)

---

## ✅ Status Atual

```bash
kubectl get pods -n fiapx | grep locust
```

**Output esperado:**
```
locust-master-xxx          1/1  Running  (Auth)
locust-api-master-xxx      1/1  Running  (API)
```

**Pronto para testes! 🦗🚀**

