# network/ — VPC & Security Groups

Stack Terraform que provisiona toda a camada de rede na AWS (us-east-1). É a **base** das stacks `cluster/` e `apps/` — estas consomem os IDs daqui via remote state ou data sources.

---

## O que cria

### VPC
- **CIDR:** `10.220.0.0/16`
- **Region:** `us-east-1`
- **AZs:** `us-east-1a`, `us-east-1b`, `us-east-1c`, `us-east-1d`
- DNS hostnames e DNS support activos
- IPs públicos assignados automaticamente em subnets públicas

### Subnets (4 AZs × 3 tiers = 12 subnets)

| Tier | AZ-a | AZ-b | AZ-c | AZ-d | Uso |
|---|---|---|---|---|---|
| Public | `10.220.0.0/20` | `10.220.16.0/20` | `10.220.32.0/20` | `10.220.48.0/20` | ALB público, NAT GW |
| Private | `10.220.64.0/20` | `10.220.80.0/20` | `10.220.96.0/20` | `10.220.112.0/20` | ECS tasks, serviços |
| Database | `10.220.128.0/20` | `10.220.144.0/20` | `10.220.160.0/20` | `10.220.176.0/20` | Aurora PostgreSQL |

### Gateways & Routing
- **Internet Gateway** — para subnets públicas
- **NAT Gateway** — single NAT (custo reduzido), em `us-east-1a`, EIP estático
- **Route tables:** public → IGW, private → NAT GW, database → isolada (sem saída para internet)

### DB Subnet Group
- Cobre as 4 database subnets
- Usado pelo Aurora PostgreSQL na stack `apps/`

### Security Groups (5 SGs)

| SG | Ingress | Egress | Usado por |
|---|---|---|---|
| `alb-public-sg` | all-all de VPC CIDR + `0.0.0.0/0` | all | ALB público |
| `alb-private-sg` | all-all de VPC CIDR + `0.0.0.0/0` | all | ALB privado |
| `services-private-sg` | all-all de VPC CIDR + `0.0.0.0/0` | all | ECS services |
| `data-private-sg` | all-all de VPC CIDR + `0.0.0.0/0` | all | Aurora, ElastiCache |
| `ssh-private-sg` | all-all de VPC CIDR + `0.0.0.0/0` | all | EC2 instances / bastion |

---

## Backend Terraform

```hcl
backend "s3" {
  bucket         = "<tfstates-bucket>"
  region         = "us-east-1"
  key            = "network-terraform/homolog/kriolu-kloud-vpc-us-east-1.tfstate"
  dynamodb_table = "<network-lock-table>"
}
```

Recursos AWS de suporte (criados manualmente antes do primeiro apply):
- S3 bucket para state
- DynamoDB table para lock
- IAM user CI com policy de VPC + S3 + DynamoDB + RDS (para o DB subnet group)

---

## Outputs

| Output | Descrição |
|---|---|
| `vpc_id` | ID da VPC |
| `vpc_cidr_block` | CIDR block da VPC |
| `private_subnets` | Lista de IDs das subnets privadas (4) |
| `public_subnets` | Lista de IDs das subnets públicas (4) |
| `nat_public_ips` | IP público do NAT Gateway |
| `azs` | Lista de AZs usadas |
| `security_group_id` | ID do SG alb-public |
| `sg_id_alb_private` | ID do SG alb-private |
| `sg_id_services_private` | ID do SG services-private |
| `sg_id_data_private` | ID do SG data-private |
| `sg_id_ssh_private` | ID do SG ssh-private |

> **Nota:** `database_subnets` e `database_subnet_group_name` existem no state mas não estão expostos como outputs ainda — adicionar a `vpc-outputs.tf` quando `cluster/` ou `apps/` precisar deles.

---

## CI Pipeline

Ficheiro: `network/.gitlab-ci.yml` (incluído pelo root `.gitlab-ci.yml`)

| Job | Trigger | O que faz |
|---|---|---|
| `network:validate` | push com changes em `network/**` | `terraform init` + `terraform validate` |
| `network:plan` | após validate | `terraform plan -out=tfplan` |
| `network:apply` | **manual** | `terraform apply -auto-approve` (re-plan) |
| `network:destroy` | **manual** | `terraform destroy -auto-approve` |

Runner: shell executor no VPS. Terraform via `docker run hashicorp/terraform:1.9 --user $(id -u):$(id -g)` para evitar ficheiros root-owned.

CI vars no grupo GitLab `ecs`: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` — todas protected + masked.

---

## Módulos usados

| Módulo | Versão | Fonte |
|---|---|---|
| `terraform-aws-modules/vpc/aws` | `5.13.0` | registry.terraform.io |
| `terraform-aws-modules/security-group/aws` | `5.2.0` | registry.terraform.io |

---

## Gotchas

- **`ingress_cidr_blocks` é obrigatório** nos módulos security-group quando usas `ingress_rules`. Sem ele, o módulo tenta criar `cidr_blocks = null` → timeout de 5min no provider. Todos os SGs têm `ingress_cidr_blocks = [module.vpc.vpc_cidr_block, "0.0.0.0/0"]`.
- **IAM policy precisa de `rds:CreateDBSubnetGroup`** — o módulo VPC cria `aws_db_subnet_group` automaticamente quando `create_database_subnet_group = true`. Adicionar à policy do CI user.
- **NAT Gateway único** (`single_nat_gateway = true`) — reduz custo mas perde HA entre AZs. Aceitável para homolog.
- **`database_subnets` sem rota para internet** — `create_database_nat_gateway_route = false` e `create_database_internet_gateway_route = false`. Aurora não precisa de saída.

---

## Como usar localmente

```bash
cd cluster-ecs-terraform/network

export AWS_ACCESS_KEY_ID=<ci-user-key>
export AWS_SECRET_ACCESS_KEY=<ci-user-secret>
export AWS_DEFAULT_REGION=us-east-1

# Via Docker (igual ao CI)
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd):/workspace" -w /workspace \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION \
  hashicorp/terraform:1.9 <comando>

# Comandos úteis
terraform init -reconfigure
terraform plan
terraform apply -auto-approve
terraform output
terraform state list
terraform state rm '<address>'
terraform import '<address>' '<id>'
```
