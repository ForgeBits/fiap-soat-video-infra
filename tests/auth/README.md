# Testes de Carga - Auth Service

Scripts de teste de carga para o serviço de autenticação.

## 📋 Testes Disponíveis

### 1. Register Endpoint (`load-test-register.sh`)

Testa o endpoint de registro de usuários com alta carga.

**Endpoint:** `POST /auth/register`

**Payload:**
```json
{
  "email": "user_<timestamp>_<random>@loadtest.com",
  "password": "Senha123"
}
```

---

## 🚀 Uso

### Teste Padrão (1000 req/s por 30 segundos)

```bash
./tests/auth/load-test-register.sh
```

**Resultado:**
- Total de requisições: 30.000
- Duração: ~30 segundos

### Customizar Parâmetros

```bash
./tests/auth/load-test-register.sh [REQUESTS_PER_SECOND] [DURATION] [URL]
```

**Parâmetros:**
- `REQUESTS_PER_SECOND`: Requisições por segundo (padrão: 1000)
- `DURATION`: Duração do teste em segundos (padrão: 30)
- `URL`: URL do endpoint (padrão: http://localhost:8081/auth/register)

### Exemplos

```bash
# 500 requisições/segundo por 60 segundos
./tests/auth/load-test-register.sh 500 60

# 2000 requisições/segundo por 10 segundos
./tests/auth/load-test-register.sh 2000 10

# Teste em URL customizada
./tests/auth/load-test-register.sh 1000 30 http://auth-service:8081/auth/register

# 100 requisições/segundo por 5 segundos (teste leve)
./tests/auth/load-test-register.sh 100 5
```

---

## 📊 Output do Teste

### Durante a Execução

```
==========================================
  Iniciando Teste de Carga - Auth Register
==========================================

Configuração:
  URL:                  http://localhost:8081/auth/register
  Requisições/segundo:  1000
  Duração:              30s
  Total de requisições: 30000
  Intervalo:            0.001000s

Iniciando envio de requisições...

[✓] Requisição #1 - Status: 201 - Email: user_1234567890_12345@loadtest.com
[✓] Requisição #2 - Status: 201 - Email: user_1234567891_23456@loadtest.com
[✗] Requisição #3 - Status: 500 - Erro: Database connection failed
...
--- Segundo 1 de 30 completo (1000 requisições) ---
...
```

### Ao Final

```
==========================================
  Teste de Carga Finalizado
==========================================

Resultados:
  Tempo total:          30.45s
  Total de requisições: 30000
  Sucessos:             28500
  Falhas:               1500
  Taxa de sucesso:      95.00%
  RPS real:             985.22 req/s
  RPS esperado:         1000 req/s

✓ Teste concluído com sucesso!
```

---

## 🎯 Cenários de Teste Recomendados

### 1. Teste de Estresse Moderado
```bash
./tests/auth/load-test-register.sh 100 60
```
- 100 req/s por 1 minuto
- Total: 6.000 requisições
- Ideal para verificar estabilidade básica

### 2. Teste de Carga Normal (Padrão)
```bash
./tests/auth/load-test-register.sh 1000 30
```
- 1000 req/s por 30 segundos
- Total: 30.000 requisições
- Simula carga média-alta

### 3. Teste de Pico
```bash
./tests/auth/load-test-register.sh 5000 10
```
- 5000 req/s por 10 segundos
- Total: 50.000 requisições
- Simula pico de acesso

### 4. Teste de Resistência
```bash
./tests/auth/load-test-register.sh 500 300
```
- 500 req/s por 5 minutos
- Total: 150.000 requisições
- Testa resistência prolongada

### 5. Teste Extremo
```bash
./tests/auth/load-test-register.sh 10000 5
```
- 10.000 req/s por 5 segundos
- Total: 50.000 requisições
- Testa limites do sistema

---

## 🔍 Análise de Resultados

### Taxa de Sucesso Esperada

| Taxa | Classificação | Ação |
|------|---------------|------|
| > 99% | Excelente | Sistema performando muito bem |
| 95-99% | Bom | Sistema estável com pequenas falhas |
| 90-95% | Aceitável | Investigar causas de falhas |
| < 90% | Problemático | Sistema precisa de otimização |

### Métricas Importantes

1. **RPS Real vs Esperado**
   - Se muito diferente, sistema não consegue acompanhar a carga

2. **Taxa de Sucesso**
   - Indica saúde geral do sistema sob carga

3. **Tempo Total**
   - Deve ser próximo da duração esperada

---

## 🐛 Troubleshooting

### Erro: "Connection refused"

**Causa:** Serviço não está rodando ou porta incorreta

**Solução:**
```bash
# Verificar se auth está rodando
kubectl get pods -l app=auth-service

# Fazer port-forward se necessário
kubectl port-forward service/auth-service 8081:3000
```

### Taxa de Sucesso Muito Baixa (< 50%)

**Possíveis causas:**
- Banco de dados sobrecarregado
- Limites de recursos (CPU/Memory)
- Rate limiting ativado
- Timeouts de conexão

**Verificar:**
```bash
# Ver logs do auth
kubectl logs -f deployment/auth-service

# Ver uso de recursos
kubectl top pods -l app=auth-service

# Ver banco de dados
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db -c "SELECT count(*) FROM users;"
```

### Sistema Travando Durante o Teste

**Causa:** Muitas requisições simultâneas

**Solução:**
- Reduzir REQUESTS_PER_SECOND
- Aumentar recursos do pod (replicas, CPU, memory)
- Otimizar queries do banco

---

## 📈 Monitoramento Durante Teste

### Ver Pods

```bash
# Status dos pods
kubectl get pods -w

# Top de recursos
watch -n 1 'kubectl top pods'
```

### Ver Logs em Tempo Real

```bash
# Logs do Auth
kubectl logs -f deployment/auth-service

# Logs do PostgreSQL Auth
kubectl logs -f statefulset/postgres-auth
```

### Verificar Banco de Dados

```bash
# Conectar ao banco
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db

# Ver total de usuários
SELECT count(*) FROM users;

# Ver últimos registros
SELECT email, created_at FROM users ORDER BY created_at DESC LIMIT 10;

# Limpar dados de teste
DELETE FROM users WHERE email LIKE '%@loadtest.com';
```

---

## 🧹 Limpeza Após Teste

### Remover Usuários de Teste

```bash
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db -c "DELETE FROM users WHERE email LIKE '%@loadtest.com';"
```

### Script de Limpeza

```bash
#!/bin/bash
echo "Removendo usuários de teste..."
kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db -c "DELETE FROM users WHERE email LIKE '%@loadtest.com';"
echo "Limpeza concluída!"
```

---

## 📝 Notas Importantes

1. **Emails Únicos**: Cada requisição gera um email único usando timestamp + random
2. **Senha Padrão**: Todos os usuários de teste usam "Senha123"
3. **Timeout**: Requisições tem timeout de 10 segundos
4. **Paralelismo**: Requisições são enviadas em paralelo para atingir o RPS desejado
5. **Resultados Temporários**: Salvos em `/tmp` e removidos ao final

---

## ⚠️ Avisos

- **Não executar em produção** sem autorização
- **Alto volume** de requisições pode sobrecarregar o sistema
- **Banco de dados** pode ficar com muitos registros de teste
- **Lembre-se de limpar** os dados de teste após

---

## ✅ Checklist Antes de Executar

- [ ] Auth service está rodando
- [ ] PostgreSQL Auth está rodando
- [ ] Port-forward configurado (se local)
- [ ] Recursos suficientes (CPU/Memory)
- [ ] Monitoramento ativo
- [ ] Plano de limpeza após teste

---

## 🎯 Objetivos do Teste

1. **Verificar capacidade**: Quantas requisições/segundo o sistema aguenta
2. **Identificar gargalos**: Banco, CPU, memória, rede
3. **Testar escalabilidade**: Como sistema se comporta sob carga
4. **Validar resiliência**: Sistema se recupera de falhas
5. **Medir performance**: Tempo de resposta sob carga

---

## 📚 Referências

- [Auth Service Documentation](../../k8s/auth/README.md)
- [Load Test API](../../commands/load-test.sh)
- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

