# Bucket S3 - FIAP Video Worker

Terraform configuration para provisionar bucket S3 AWS para armazenamento de vídeos.

## 📋 Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Credenciais AWS com permissões para criar S3

## 🚀 Uso

### 1. Inicializar Terraform

```bash
cd terraform-s3
terraform init
```

### 2. Planejar mudanças

```bash
terraform plan
```

### 3. Aplicar configuração

```bash
terraform apply
```

### 4. Destruir recursos (se necessário)

```bash
terraform destroy
```

## 📦 Recursos Criados

### S3 Bucket
- **Nome fixo:** `fiap-video-worker`
- **Região:** us-east-1 (configurável)
- **Versionamento:** Habilitado
- **Criptografia:** AES256
- **Acesso Público:** Bloqueado

### Configurações Adicionais

#### Lifecycle Policies:
- Versões antigas deletadas após 30 dias
- Transição para GLACIER após 90 dias
- Transição para DEEP_ARCHIVE após 180 dias

#### CORS:
- Habilitado para uploads diretos
- Permite: GET, PUT, POST, DELETE, HEAD
- Origins: * (ajustar para produção)

## 🔧 Variáveis

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `aws_region` | Região AWS | `us-east-1` |
| `bucket_name` | Nome do bucket | `fiap-video-worker` |
| `environment` | Ambiente | `dev` |

### Customizar variáveis

Crie um arquivo `terraform.tfvars`:

```hcl
aws_region  = "us-east-1"
bucket_name = "fiap-video-worker"
environment = "production"
```

Ou passe via linha de comando:

```bash
terraform apply -var="environment=prod"
```

## 📊 Outputs

Após aplicar, você terá acesso aos seguintes outputs:

```bash
terraform output bucket_name
terraform output bucket_arn
terraform output bucket_region
```

### Exemplo de saída:

```
bucket_name = "fiap-video-worker"
bucket_arn = "arn:aws:s3:::fiap-video-worker"
bucket_region = "us-east-1"
bucket_domain_name = "fiap-video-worker.s3.amazonaws.com"
```

## 🔐 Segurança

### Configurações de Segurança Implementadas:

- ✅ Versionamento habilitado
- ✅ Criptografia server-side (AES256)
- ✅ Bloqueio de acesso público
- ✅ Lifecycle policies para otimização de custos

### Para Produção:

1. **Restringir CORS:**
   ```hcl
   allowed_origins = ["https://seudominio.com"]
   ```

2. **Adicionar bucket policy:**
   ```hcl
   resource "aws_s3_bucket_policy" "video_storage" {
     bucket = aws_s3_bucket.video_storage.id
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [
         {
           Effect = "Allow"
           Principal = {
             AWS = "arn:aws:iam::ACCOUNT-ID:role/YourRole"
           }
           Action = ["s3:GetObject", "s3:PutObject"]
           Resource = "${aws_s3_bucket.video_storage.arn}/*"
         }
       ]
     })
   }
   ```

3. **Habilitar logging:**
   ```hcl
   resource "aws_s3_bucket_logging" "video_storage" {
     bucket = aws_s3_bucket.video_storage.id
     
     target_bucket = aws_s3_bucket.log_bucket.id
     target_prefix = "log/"
   }
   ```

## 💰 Custos Estimados

### Storage (por mês):
- S3 Standard: $0.023/GB
- S3 Glacier: $0.004/GB
- S3 Deep Archive: $0.00099/GB

### Requests:
- PUT/POST: $0.005 por 1.000 requisições
- GET: $0.0004 por 1.000 requisições

### Exemplo para 100GB de vídeos:
- Primeiros 90 dias (S3 Standard): ~$2.30/mês
- 90-180 dias (Glacier): ~$0.40/mês
- Após 180 dias (Deep Archive): ~$0.10/mês

## 🔄 Integração com Aplicação

### Variáveis de ambiente para a API:

```env
AWS_REGION=us-east-1
AWS_S3_BUCKET=fiap-video-worker
AWS_ACCESS_KEY_ID=<sua-access-key>
AWS_SECRET_ACCESS_KEY=<sua-secret-key>
```

### ConfigMap Kubernetes:

```yaml
AWS_REGION: "us-east-1"
AWS_S3_BUCKET: "fiap-video-worker"
```

## 📚 Comandos Úteis

```bash
# Ver estado atual
terraform show

# Listar recursos
terraform state list

# Ver output específico
terraform output -json

# Importar bucket existente (se já existe)
terraform import aws_s3_bucket.video_storage fiap-video-worker

# Validar configuração
terraform validate

# Formatar código
terraform fmt
```

## 🗑️ Remover Recursos

**ATENÇÃO:** Isso vai deletar o bucket e TODOS os arquivos!

```bash
# Remover proteção contra deleção (se configurada)
# Depois executar:
terraform destroy

# Confirmar digitando: yes
```

## 🔧 Troubleshooting

### Erro: Bucket já existe

Se o bucket `fiap-video-worker` já existe:

```bash
# Importar para o Terraform gerenciar
terraform import aws_s3_bucket.video_storage fiap-video-worker
```

### Erro: Permissões insuficientes

Certifique-se que suas credenciais AWS têm as seguintes permissões:
- `s3:CreateBucket`
- `s3:DeleteBucket`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`
- `s3:PutBucketPublicAccessBlock`
- `s3:PutLifecycleConfiguration`
- `s3:PutBucketCORS`

### Erro: Region mismatch

Se o bucket foi criado em outra região:

```bash
terraform apply -var="aws_region=<regiao-correta>"
```

## 📖 Documentação

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)

## ✅ Checklist

- [x] Bucket com nome fixo `fiap-video-worker`
- [x] Versionamento habilitado
- [x] Criptografia AES256
- [x] Acesso público bloqueado
- [x] Lifecycle policies configuradas
- [x] CORS configurado
- [x] Outputs para integração
- [x] Documentação completa
- [x] .gitignore configurado

## 📝 Licença

FIAP SOAT - Projeto Acadêmico

