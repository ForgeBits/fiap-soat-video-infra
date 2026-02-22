# 🐛 Troubleshooting - Locust API (0 requisições)

## ❌ Problema

Ao rodar o teste do Locust API, **0 requisições** são executadas e os workers param imediatamente.

```
Total de requisições: 0
Requisições com falha: 0
```

## 🔍 Causa Raiz

O problema estava no `on_start()` da classe `ApiUser`:
- Tentava usar `self.client.post()` para chamar o Auth Service
- `self.client` aponta para `http://api-service:3001` (host configurado)
- Auth Service está em `http://auth-service:3000` (host diferente)
- Resultado: Requisições falhavam silenciosamente, setup não completava

## ✅ Solução Aplicada

Mudei para usar `requests` diretamente no setup:

**Antes (ERRADO):**
```python
# self.client aponta para API, não para Auth!
auth_response = self.client.post(
    "http://auth-service:3000/auth/register",  # ❌ Falha
    ...
)
```

**Depois (CORRETO):**
```python
import requests

# requests permite chamar qualquer URL
auth_response = requests.post(
    "http://auth-service:3000/auth/register",  # ✅ Funciona
    json={...},
    timeout=10
)
```

## 🚀 Testar Agora

### **1. Port-forward:**
```bash
kubectl port-forward -n fiapx service/locust-api-master 8090:8090
```

### **2. Acessar:**
```
http://localhost:8090
```

### **3. Configurar teste:**
```
Host: http://api-service:3001
Number of users: 10  (começar pequeno)
Spawn rate: 1
```

### **4. Clicar "Start swarming"**

### **5. Observar:**
- Dashboard deve mostrar requisições sendo feitas
- RPS deve ser > 0
- Gráficos devem aparecer

## 📊 O Que Esperar

### **Setup bem-sucedido:**
```
✓ Cada usuário registra no Auth Service
✓ Faz login e obtém token JWT
✓ Começa a fazer requisições na API
```

### **Requisições esperadas:**
- `GET /videos?page=1&limit=10` (59%)
- `GET /videos/:id` (29%)
- `POST /videos/process` (12%)

### **RPS esperado:**
- 10 usuários → ~5-10 RPS
- 50 usuários → ~20-30 RPS

## 🔧 Se Ainda Não Funcionar

### **Ver logs em tempo real:**
```bash
# Master
kubectl logs -f deployment/locust-api-master -n fiapx

# Worker
kubectl logs -f -l app=locust-api,role=worker -n fiapx
```

### **Verificar Auth Service está respondendo:**
```bash
# Port-forward do Auth
kubectl port-forward -n fiapx service/auth-service 3000:3000

# Testar registro (outro terminal)
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Senha123"}'
```

### **Verificar API Service está respondendo:**
```bash
# Port-forward da API
kubectl port-forward -n fiapx service/api-service 3001:3001

# Testar health (outro terminal)
curl http://localhost:3001/health
```

### **Verificar pods do Locust API:**
```bash
kubectl get pods -n fiapx -l app=locust-api

# Deve ter:
# locust-api-master (1 pod Running)
# locust-api-worker (3 pods Running)
```

## 💡 Dicas

### **Começar com poucos usuários:**
```
Users: 5
Spawn rate: 1
```

Observe se as requisições começam. Se sim, aumente gradualmente.

### **Endpoints da API podem retornar 404:**

Se os endpoints `/videos` ou `/videos/process` não existirem na sua API, você verá:
- Requisições sendo feitas ✅
- Mas com failures (404) ❌

**Isso é DIFERENTE** de 0 requisições (que era o bug).

### **Upload de vídeo:**

O teste envia vídeo fake de 1KB:
```python
fake_video = os.urandom(1024)  # 1KB de dados aleatórios
```

Se sua API validar que é vídeo real, vai falhar. Mas a requisição será feita.

## 📝 Verificar Endpoints da API

Os endpoints testados pelo Locust são:

```bash
GET  /videos?page=1&limit=10
GET  /videos/:id
POST /videos/process
```

**Certifique-se que eles existem na sua API!**

Se não existirem, você precisa:
1. Implementar os endpoints na API
2. Ou alterar o script do Locust para usar endpoints que existem

## 🎯 Próximos Passos

1. ✅ Correção aplicada (usando `requests` no setup)
2. ✅ Pods reiniciados
3. 🔄 Fazer port-forward: `kubectl port-forward -n fiapx service/locust-api-master 8090:8090`
4. 🔄 Acessar: http://localhost:8090
5. 🔄 Testar com 5-10 usuários primeiro
6. 🔄 Verificar se RPS > 0

**Se RPS > 0, funcionou! Se tiver failures, é porque os endpoints não existem (diferente do bug anterior).** ✅

