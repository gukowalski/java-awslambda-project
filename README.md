# S3 File Renamer — AWS Lambda + Terraform

Solução serverless que renomeia e move arquivos entre buckets S3 automaticamente. Quando um arquivo é enviado ao bucket de origem, um evento dispara uma função Lambda em Java que copia o arquivo para o bucket de destino com um novo nome baseado no timestamp do upload.

## Arquitetura

<!-- Diagrama draw.io -->

## Infraestrutura (Terraform)

Toda a infraestrutura é provisionada como código usando Terraform.

### Buckets S3

| Bucket | Finalidade |
|---|---|
| `lambda-bucket-gkowalski` | Armazena o JAR de deploy da Lambda |
| `source-bucket-gkowalski` | Bucket de origem — qualquer upload aqui inicia o fluxo |
| `destionation-bucket-gkowalski` | Bucket de destino onde os arquivos renomeados são gravados |

### IAM

Uma IAM Role dedicada (`role-lambda-s3-renamer`) é criada com uma trust policy restrita exclusivamente ao serviço `lambda.amazonaws.com`, seguindo o princípio do menor privilégio.

Uma IAM Policy (`lambda-s3-policy`) é anexada a essa role com três blocos de permissão:

- **Acesso ao S3** — `s3:GetObject` e `s3:PutObject` nos objetos dos buckets de origem e destino (`/*`)
- **Criação de log group** — `logs:CreateLogGroup` com escopo na região da conta
- **Escrita de logs** — `logs:CreateLogStream` e `logs:PutLogEvents` com escopo no log group específico da Lambda (`/aws/lambda/s3-file-renamer`)

### Função Lambda

A função é deployada a partir do JAR armazenado no `lambda-bucket-gkowalski` com as seguintes configurações:

- **Runtime:** Java 21
- **Handler:** `org.example.Handler::handleRequest`
- **Timeout:** 30 segundos
- **HTTP Client:** AWS SDK v2 `UrlConnectionHttpClient` configurado explicitamente no builder do cliente S3

### Trigger S3

Uma resource-based policy (`aws_lambda_permission`) concede ao `s3.amazonaws.com` permissão para invocar a Lambda, com escopo restrito ao ARN do bucket de origem. Esse recurso precisa existir antes que a notificação S3 possa ser criada.

O recurso `aws_s3_bucket_notification` configura o bucket de origem para disparar nos eventos `s3:ObjectCreated:Put` e `s3:ObjectCreated:Post`. O `depends_on` garante que a permissão exista antes que a notificação seja registrada, evitando uma condição de corrida durante o `terraform apply`.

## Stack

- **AWS Lambda** — runtime Java 21
- **AWS S3** — armazenamento e fonte de eventos
- **AWS IAM** — role e policy com menor privilégio
- **Terraform** — infraestrutura como código
- **Maven Shade Plugin** — empacotamento em fat JAR
