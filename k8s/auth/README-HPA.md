# HPA - Horizontal Pod Autoscaler - Auth Service

Configuração de auto-scaling para o serviço de autenticação.

## 🎯 Objetivo

Escalar automaticamente o número de pods do Auth Service baseado em CPU e memória para suportar cargas de até **1000 requisições/segundo**.

## ⚙️ Configuração

### Métricas de Scaling

- **CPU**: Escala quando atinge **70% de utilização**
- **Memory**: Escala quando atinge **80% de utilização**

### Limites

- **Min Replicas**: 2 (sempre mantém 2 pods rodando)
- **Max Replicas**: 10 (pode escalar até 10 pods)

### Comportamento de Scaling

#### Scale Up (Adicionar pods)
- **Rápido e agressivo**
- Sem janela de estabilização (0 segundos)
- Pode adicionar até 4 pods de uma vez
- Ou aumentar 100% do total atual
- Período de avaliação: 15 segundos

#### Scale Down (Remover pods)
- **Conservador**
- Janela de estabilização: 60 segundos
- Remove no máximo 50% dos pods por vez
- Período de avaliação: 60 segundos

## 📊 Recursos por Pod

Cada pod do Auth Service tem:

```yaml
resources:
  requests:
    cpu: "100m"      # 0.1 CPU cores
    memory: "256Mi"  # 256 MB RAM
  limits:
    cpu: "200m"      # 0.2 CPU cores
    memory: "512Mi"  # 512 MB RAM
```

## 🚀 Capacidade Teórica

### Com 2 pods (mínimo):
- **Requisições/segundo**: ~400-600 req/s
- **Usuários simultâneos**: ~200-300

### Com 10 pods (máximo):
- **Requisições/segundo**: ~2000-3000 req/s
- **Usuários simultâneos**: ~1000-1500

## 📈 Como Funciona

### Exemplo de Scaling Up (Carga aumentando):

```
Tempo 0s:  2 pods, CPU: 30%  → OK
Tempo 30s: 2 pods, CPU: 75%  → Trigger: CPU > 70%
Tempo 45s: 4 pods, CPU: 40%  → Escalou para 4 pods
Tempo 60s: 4 pods, CPU: 80%  → Trigger: CPU > 70%
Tempo 75s: 8 pods, CPU: 45%  → Escalou para 8 pods
```

### Exemplo de Scaling Down (Carga diminuindo):

```
Tempo 0s:   8 pods, CPU: 20%  → Abaixo do threshold
Tempo 60s:  8 pods, CPU: 20%  → Ainda aguardando (stabilization)
Tempo 120s: 4 pods, CPU: 35%  → Removeu 50% (4 pods)
Tempo 180s: 4 pods, CPU: 15%  → Abaixo do threshold
Tempo 240s: 2 pods, CPU: 25%  → Removeu mais 50% (chegou no mínimo)
```

## 🧪 Testar Autoscaling

### 1. Ver status do HPA:
```bash
kubectl get hpa -n fiapx
kubectl describe hpa auth-service-hpa -n fiapx
```

### 2. Ver pods do Auth:
```bash
kubectl get pods -n fiapx -l app=auth-service
```

### 3. Executar teste de carga:
```bash
# Teste padrão (1000 req/s por 30s)
./tests/auth/load-test-register.sh

# Teste mais leve
./tests/auth/load-test-register.sh 500 60

# Teste mais pesado
./tests/auth/load-test-register.sh 2000 30
```

### 4. Monitorar scaling em tempo real:
```bash
# Terminal 1: Ver HPA
watch -n 2 'kubectl get hpa -n fiapx'

# Terminal 2: Ver pods
watch -n 2 'kubectl get pods -n fiapx -l app=auth-service'

# Terminal 3: Top de recursos
watch -n 2 'kubectl top pods -n fiapx -l app=auth-service'
```

## 📊 Comandos Úteis

### Ver métricas do HPA:
```bash
kubectl get hpa auth-service-hpa -n fiapx -w
```

**Output:**
```
NAME               REFERENCE                 TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
auth-service-hpa   Deployment/auth-service   cpu: 45%/70%, memory: 35%/80%  2         10        4          5m
```

### Ver eventos do HPA:
```bash
kubectl describe hpa auth-service-hpa -n fiapx
```

### Ver uso de recursos dos pods:
```bash
kubectl top pods -n fiapx -l app=auth-service
```

**Output:**
```
NAME                            CPU(cores)   MEMORY(bytes)
auth-service-774667ccc7-44vb4   45m          180Mi
auth-service-774667ccc7-qczvt   52m          195Mi
```

### Forçar scaling manual (para teste):
```bash
# Escalar manualmente (temporário, HPA vai ajustar depois)
kubectl scale deployment auth-service -n fiapx --replicas=5
```

## 🔧 Ajustar Configuração

### Aumentar capacidade máxima:
```yaml
maxReplicas: 20  # Aumentar de 10 para 20
```

### Tornar scaling mais agressivo:
```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # Reduzir de 70 para 50
```

### Manter mais pods mínimos:
```yaml
minReplicas: 5  # Aumentar de 2 para 5
```

## ⚠️ Importante

### **1. Metrics Server Necessário**

O HPA requer o Metrics Server rodando no cluster:

```bash
# Verificar se está instalado
kubectl get deployment metrics-server -n kube-system

# Se não estiver, instalar:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### **2. Recursos Definidos**

O deployment **DEVE** ter `resources.requests` definidos:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
```

Sem isso, o HPA não funciona!

### **3. Não definir replicas no Deployment**

Quando HPA está ativo, **NÃO** definir `replicas` no deployment:

```yaml
# ❌ ERRADO (com HPA)
spec:
  replicas: 3

# ✅ CORRETO (com HPA)
spec:
  # sem campo replicas
```

## 🐛 Troubleshooting

### HPA mostra "unknown" nas métricas:

**Causa:** Metrics Server não está rodando

**Solução:**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### HPA não escala:

**Causa 1:** Deployment tem `replicas` definido

**Solução:** Remover campo `replicas` do deployment

**Causa 2:** Recursos não estão definidos

**Solução:** Adicionar `resources.requests` no deployment

### Pods ficam em Pending:

**Causa:** Cluster não tem recursos suficientes

**Solução:** 
- Adicionar mais nodes ao cluster
- Ou reduzir `maxReplicas`

## 📈 Custo x Benefício

### Sem HPA (1 replica fixa):
- **Custo**: Baixo (1 pod sempre)
- **Capacidade**: ~200 req/s
- **Problema**: Cai em picos de carga

### Com HPA (2-10 replicas):
- **Custo**: Médio (2 pods em idle, até 10 em pico)
- **Capacidade**: 400-3000 req/s
- **Benefício**: Auto-ajusta à demanda

### Economia vs Always On:
- **10 pods sempre**: 100% do custo
- **HPA 2-10 pods**: ~20-40% do custo (em média)
- **Economia**: ~60-80%

## ✅ Checklist

- [x] HPA criado (hpa.yaml)
- [x] Min replicas: 2
- [x] Max replicas: 10
- [x] Métrica CPU: 70%
- [x] Métrica Memory: 80%
- [x] Scale up rápido (15s, +4 pods)
- [x] Scale down conservador (60s, -50%)
- [x] Deployment sem replicas fixo
- [x] Recursos definidos no deployment
- [x] Scripts atualizados
- [x] Documentação completa

## 🎯 Resultado Esperado

Com o HPA configurado, o Auth Service:

✅ Suporta **1000 req/s** do teste padrão  
✅ Escala automaticamente de 2 a 10 pods  
✅ Responde em ~15 segundos a picos de carga  
✅ Economiza recursos em períodos de baixa carga  
✅ Mantém disponibilidade alta (2 pods mínimos)  

**Pronto para produção! 🚀**

