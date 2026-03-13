# 🏗️ Infraestrutura do Ecossistema FIAP-X (Terraform)

Este diretório contém os manifestos do Terraform para provisionamento de toda a infraestrutura em nuvem (AWS) necessária para a plataforma de processamento de vídeos.

## 🚀 Componentes Principais

A infraestrutura é segmentada nos seguintes arquivos para facilitar a manutenção:

- **`main.tf`**: Configurações globais, provedores (AWS), variáveis globais e geração de IDs aleatórios para unicidade de recursos.
- **`vpc.tf`**: Toda a camada de rede, incluindo VPC, subnets públicas em múltiplas zonas de disponibilidade (AZs) e Internet Gateway.
- **`security_groups.tf`**: Regras de firewall (entrada/saída) que controlam o acesso entre o EKS, bancos de dados e o mundo externo.
- **`eks.tf`**: Configuração do cluster **Amazon EKS (Kubernetes)** e o Node Group (instâncias EC2 t3.small) onde os serviços rodam.
- **`rds.tf`**: Banco de dados relacional **PostgreSQL (RDS)** gerenciado, utilizado para persistência de dados (usuários e status de vídeos).
- **`cache_mq.tf`**: Instância gerenciada de **Redis (ElastiCache)** para cache e mensageria rápida.
- **`s3.tf`**: Buckets do **Amazon S3** para armazenamento de arquivos (vídeos originais e frames extraídos).
- **`outputs.tf`**: Exibe informações críticas após o deploy, como endpoints de bancos de dados e nomes de recursos.

## 🛠️ Como Utilizar

### Pré-requisitos
- Terraform instalado (versão >= 1.5.0 recomendada).
- AWS CLI configurado com credenciais válidas.

### Comandos Comuns
1.  **Inicializar**: `terraform init` (baixa os plugins necessários).
2.  **Validar**: `terraform validate` (verifica erros de sintaxe).
3.  **Formatar**: `terraform fmt` (ajusta o estilo do código).
4.  **Planejar**: `terraform plan` (visualiza o que será criado/alterado).
5.  **Aplicar**: `terraform apply` (aplica as mudanças na AWS).

## 🤖 CI/CD Pipeline

Este projeto possui uma pipeline automatizada via **GitHub Actions** (`.github/workflows/terraform.yml`) que é disparada ao realizar `push` na branch `main`.

A pipeline executa:
1. `terraform fmt -check`: Garante que o código está formatado.
2. `terraform plan`: Gera o plano de execução.
3. `terraform apply`: Aplica automaticamente as mudanças na branch principal.

---
**Nota de Segurança:** Recomenda-se configurar um *Backend Remoto* (S3 + DynamoDB) para o estado do Terraform (`.tfstate`) em ambientes de produção.