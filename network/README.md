# network/ — VPC & Security Groups

Stack Terraform que provisiona toda a camada de rede da Kriolu Kloud na AWS (us-east-1). É a **base** das stacks `cluster/` e `apps/` — estas consomem os IDs daqui via remote state ou data sources.

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
- Nome: `h-kriolu-kloud-vpc` (prefix `h-` = homolog)
- Cobre as 4 database subnets
- Usado pelo Aurora PostgreSQL na stack `apps/`

### Security Groups (5 SGs)

| SG | ID | Ingress | Egress | Usado por |
|---|---|---|---|---|
| `alb-public-sg` | `sg-06857ad9c4fdcd339` | all-all de VPC + 0.0.0.0/0 | all | ALB público |
| `alb-private-sg` | `sg-05ac56816e4a11364` | all-all de VPC + 0.0.0.0/0 | all | ALB privado |
| `services-private-sg` | `sg-00d7915d98097b6ce` | all-all de VPC + 0.0.0.0/0 | all | ECS services |
| `data-private-sg` | `sg-0f9c00e33cf7b4a97` | all-all de VPC + 0.0.0.0/0 | all | Aurora, ElastiCache |
| `ssh-private-sg` | `sg-02e32c692736aaa3f` | all-all de VPC + 0.0.0.0/0 | all | EC2 instances / bastion |

---

## Backend Terraform

```hcl
backend "s3" {
  bucket         = "kriolu-kloud-terraform-tfstates"
  region         = "us-east-1"
  key            = "network-terraform/homolog/kriolu-kloud-vpc-us-east-1.tfstate"
  dynamodb_table = "kriolu-kloud-network-terraform-lock"
}
```

| Recurso AWS | Nome |
|---|---|
| S3 bucket state | `kriolu-kloud-terraform-tfstates` |
| DynamoDB lock | `kriolu-kloud-network-terraform-lock` |
| IAM user CI | `kk-terraform-ci` (ARN: `arn:aws:iam::598552768939:user/kk-terraform-ci`) |
| IAM policy | `kk-terraform-network-policy` (v2 — inclui RDS permissions) |

---

## Outputs

| Output | Valor actual |
|---|---|
| `vpc_id` | `vpc-0c6563b4e30626c2b` |
| `vpc_cidr_block` | `10.220.0.0/16` |
| `private_subnets` | `[subnet-00bf9896652c27873, subnet-0fd3eb53f8862e333, subnet-013412e408cd68cac, subnet-008d0e06efa9bc710]` |
| `public_subnets` | `[subnet-01a469f336db090f8, subnet-0427c631e430be10b, subnet-001dfe1855e10f411, subnet-00fc3798f7bd174f2]` |
| `nat_public_ips` | `[3.214.176.234]` |
| `azs` | `[us-east-1a, us-east-1b, us-east-1c, us-east-1d]` |
| `security_group_id` | `sg-06857ad9c4fdcd339` (alb-public) |
| `sg_id_alb_private` | `sg-05ac56816e4a11364` |
| `sg_id_services_private` | `sg-00d7915d98097b6ce` |
| `sg_id_data_private` | `sg-0f9c00e33cf7b4a97` |
| `sg_id_ssh_private` | `sg-02e32c692736aaa3f` |

> **Nota:** `database_subnets` e `database_subnet_group_name` existem no state mas não estão expostos como outputs ainda — adicionar a `vpc-outputs.tf` quando o `cluster/` ou `apps/` precisar deles.

---

## CI Pipeline

Ficheiro: `network/.gitlab-ci.yml` (incluído pelo root `.gitlab-ci.yml`)

| Job | Trigger | O que faz |
|---|---|---|
| `network:validate` | push com changes em `network/**` | `terraform init` + `terraform validate` |
| `network:plan` | após validate | `terraform plan -out=tfplan` |
| `network:apply` | **manual** | `terraform apply -auto-approve` (re-plan) |
| `network:destroy` | **manual** | `terraform destroy -auto-approve` |

Runner: `vps-native-runner` (shell executor, sem tags). Terraform via `docker run hashicorp/terraform:1.9 --user $(id -u):$(id -g)` para evitar ficheiros root-owned.

CI vars no grupo `ecs` (ID: 30): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` — todas protected + masked.

---

## Módulos usados

| Módulo | Versão | Fonte |
|---|---|---|
| `terraform-aws-modules/vpc/aws` | `5.13.0` | registry.terraform.io |
| `terraform-aws-modules/security-group/aws` | `5.2.0` | registry.terraform.io |

---

## Gotchas

- **`ingress_cidr_blocks` é obrigatório** nos módulos security-group quando usas `ingress_rules`. Sem ele, o módulo tenta criar `cidr_blocks = null` → timeout de 5min no provider. Todos os SGs têm `ingress_cidr_blocks = [module.vpc.vpc_cidr_block, "0.0.0.0/0"]`.
- **IAM policy v2** — a v1 não tinha `rds:CreateDBSubnetGroup`. O módulo VPC cria `aws_db_subnet_group` automaticamente quando `create_database_subnet_group = true`. Actualizado para v2 durante o primeiro apply.
- **NAT Gateway único** (`single_nat_gateway = true`) — reduz custo mas perde HA entre AZs. Aceitável para homolog.
- **`database_subnets` sem rota para internet** — `create_database_nat_gateway_route = false` e `create_database_internet_gateway_route = false`. Aurora não precisa de saída.

---

## Como usar localmente

```bash
cd cluster-ecs-terraform/network

# Credenciais (usar steven-prod para writes IAM/Route53, kk-terraform-ci para Terraform)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
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
terraform state rm '<address>'   # remover recurso do state sem destruir
terraform import '<address>' '<id>'
```
