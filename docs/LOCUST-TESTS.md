# 🦗 Locust - Testes de Carga

## 📋 Classes de Teste

O Locust está configurado com **2 classes de usuário**:

### 1. **AuthUser** - Testes do Auth Service
Testa os endpoints de autenticação.

**Host:** `http://auth-service:3000`

**Endpoints testados:**
- `POST /auth/register` (peso 10) - 56% das requisições
- `POST /auth/login` (peso 5) - 28% das requisições  
- `POST /auth/validate` (peso 3) - 16% das requisições

### 2. **ApiUser** - Testes da API Service  
Testa os endpoints de processamento de vídeo.

**Host:** `http://api-service:3001`

**Endpoints testados:**
- `GET /videos?page=1&limit=10` (peso 10) - 83% das requisições
- `POST /videos/process` (peso 2) - 17% das requisições

---

## 🎯 Como Funciona

### **AuthUser**

**Setup (on_start):**
1. Cria usuário único no Auth
2. Faz login e obtém token JWT
3. Armazena token para testes subsequentes

**Tasks:**
- **Register:** Cria novos usuários
- **Login:** Autentica com credenciais válidas
- **Validate:** Valida tokens JWT

---

### **ApiUser**

**Setup (on_start):**
1. Registra usuário no Auth Service
2. Faz login no Auth e obtém token
3. Usa token para chamar API

**Tasks:**
- **List Videos:** Lista vídeos do usuário (operação leve)
- **Process Video:** Upload e processamento de vídeo (operação pesada)
  - Gera vídeo fake de 1KB em memória
  - Envia como `multipart/form-data`
  - Parâmetros: `format=png`, `framesPerSecond=15`

---

## 🚀 Uso

### **Deploy do Locust:**
```bash
./commands/up.sh locust
```

### **Port-forward para acessar UI:**
```bash
kubectl port-forward -n fiapx service/locust-master 8089:8089
```

### **Acessar:**
```
http://localhost:8089
```

---

## 🧪 Cenários de Teste

### **Teste 1: Auth Only**
```
Host: http://auth-service:3000
Users: 100
Spawn rate: 10
```
Testa apenas autenticação.

### **Teste 2: API Only**
```
Host: http://api-service:3001
Users: 50
Spawn rate: 5
```
Testa apenas API (mais pesada devido ao upload de vídeos).

### **Teste 3: Mixed (recomendado)**
Configure dois testes separados ou use múltiplas instâncias do Locust.

---

## 📊 Peso das Tasks

### **AuthUser (total: 18)**
| Task | Peso | % |
|------|------|---|
| Register | 10 | 56% |
| Login | 5 | 28% |
| Validate | 3 | 16% |

### **ApiUser (total: 12)**
| Task | Peso | % |
|------|------|---|
| List Videos | 10 | 83% |
| Process Video | 2 | 17% |

---

## ⚠️ Observações Importantes

### **Upload de Vídeo no Locust**

O vídeo enviado no teste **NÃO é um vídeo real**, é um arquivo de 1KB com bytes aleatórios.

**Por quê?**
- Pods do Locust não têm acesso ao filesystem do host
- Enviar vídeo real de vários MB multiplicaria por muitos usuários
- 100 usuários × 10MB = 1GB de upload simultâneo
- Teste foca em **carga/concorrência**, não em validação de vídeo

**Para testes com vídeo real:**
- Use curl/Postman manualmente
- Ou monte um volume no pod do Locust com o vídeo

---

## 🔧 Customizar Testes

### **Editar o script:**
```bash
kubectl edit configmap locust-script -n fiapx
```

### **Reaplicar:**
```bash
kubectl rollout restart deployment/locust-master -n fiapx
```

---

## 📈 Métricas Esperadas

### **Auth Service**
| Métrica | Esperado |
|---------|----------|
| RPS | 50-100 |
| P95 | < 500ms |
| Failures | < 1% |

### **API Service**  
| Métrica | Esperado |
|---------|----------|
| RPS | 10-30 (upload é lento) |
| P95 | < 2000ms |
| Failures | < 5% |

---

## 💡 Dicas

### **Ver logs:**
```bash
kubectl logs -f deployment/locust-master -n fiapx
```

### **Remover Locust:**
```bash
./commands/down.sh locust
```

---

## 🎯 Endpoints Reais Testados

### **Auth Service:**
```bash
POST http://auth-service:3000/auth/register
POST http://auth-service:3000/auth/login
POST http://auth-service:3000/auth/validate
```

### **API Service:**
```bash
GET http://api-service:3001/videos?page=1&limit=10
POST http://api-service:3001/videos/process
```

**Todos os testes rodam DENTRO do cluster (sem latência externa)!** 🚀

