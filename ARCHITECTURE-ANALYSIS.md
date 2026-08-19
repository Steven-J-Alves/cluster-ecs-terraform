# Análise Arquitetural: ECS/Terraform — Kriolu Kloud

---

## 1. Resumo Executivo

A arquitetura atual é funcional e os módulos de baixo nível são bem desenhados. O problema não está nos módulos — está na **camada de orquestração** acima deles. Cada workload requer intervenção manual em 5 a 8 arquivos diferentes, espalhados por diretórios distintos, sem nenhuma abstração que consolide a definição de um workload em um único lugar.

Com 5 workloads actuais, isso é gerenciável. Com 15 workloads, começa a ser pesado. Com 40+, torna-se inviável.

A boa notícia: os módulos reutilizáveis já existem. O que falta é uma camada de abstração declarativa entre "o que quero" e "como os módulos são chamados".

A recomendação é a **Arquitectura 2: Módulo Composto de Workload** — que mantém a estrutura atual de módulos, acrescenta uma abstração de workload, e elimina ~80% da duplicação sem introduzir complexidade desnecessária.

---

## 2. Arquitectura Actual

### Estrutura de diretórios (simplificada)

```
cluster-ecs-terraform/
├── apps/
│   ├── app/                          # Módulo "app" — uma aplicação
│   │   ├── ecs/
│   │   │   ├── core/                 # ← ponto central do problema
│   │   │   │   ├── app-api.tf        # task_def + service + autoscaling (HTTP)
│   │   │   │   ├── app-front.tf      # task_def + service + autoscaling (HTTP)
│   │   │   │   ├── app-manager.tf    # task_def + service + autoscaling (worker)
│   │   │   │   ├── app-scheduler.tf  # task_def + service + autoscaling (worker)
│   │   │   │   ├── app-worker.tf     # task_def + service + autoscaling (worker)
│   │   │   │   └── variables.tf
│   │   │   ├── main.tf               # chama ./core
│   │   │   └── remote-state-datasource.tf
│   │   ├── networking/
│   │   │   ├── security_groups.tf    # 1 SG por workload (5 blocos)
│   │   │   ├── target_groups.tf      # 1 TG por workload HTTP (2 blocos)
│   │   │   ├── alb.tf                # 1 listener rule por workload HTTP
│   │   │   ├── outputs.tf            # 1 output por workload
│   │   │   └── ...
│   │   ├── ecr/
│   │   │   ├── repositories.tf       # 1 ECR repo por workload (5 blocos)
│   │   │   └── outputs.tf            # 1 output por workload
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── iam.tf
│   │   └── locals.tf
│   └── environments/
│       └── prod/                     # entry point (chama apps/app)
├── cluster/                          # ECS cluster, ALBs, ASG, Capacity Provider
├── modules/                          # módulos reutilizáveis ← bem desenhados
│   ├── ecs_ec2/
│   │   ├── task_definition/
│   │   ├── service/
│   │   ├── autoscaling/
│   │   └── cluster/
│   ├── alb/
│   ├── ecr/
│   ├── iam/
│   ├── postgres/
│   └── securitygroup/
└── network/
```

### Representação conceptual

```
environments/prod/
       │
       ▼
   apps/app/                          ← "aplicação"
   ├── IAM (roles, policies)
   ├── RDS Aurora (shared por workloads)
   │
   ├── networking/                    ← infra de rede por workload
   │   ├── SG ──── [api] [front] [worker] [scheduler] [manager]
   │   ├── TG ──── [api-pvt] [front-pvt]
   │   └── ALB rules ── [rule1→api] [rule2→front]
   │
   ├── ecr/                           ← repositórios de imagem
   │   └── ECR ── [api] [front] [worker] [scheduler] [manager]
   │
   └── ecs/core/                      ← serviços em execução
       ├── [app-api]       → task_def + service + autoscaling
       ├── [app-front]     → task_def + service + autoscaling
       ├── [app-manager]   → task_def + service + autoscaling
       ├── [app-scheduler] → task_def + service + autoscaling
       └── [app-worker]    → task_def + service + autoscaling
```

### Padrão de cada workload (actual)

O arquivo `ecs/core/app-api.tf` é **estruturalmente idêntico** a todos os outros 4. A única diferença são os valores:

```hcl
# SEMPRE os mesmos 3 blocos, por workload:
module "ecs_taks_definition_app_<name>" { ... }
module "ecs_service_app_<name>"         { ... }
module "ecs_autoscaling_app_<name>"     { ... }
```

E nos outros diretórios, por workload:
- `networking/security_groups.tf`: 1 `module "security_group_ecs_task_app_<name>"`
- `networking/target_groups.tf` (se HTTP): 1 `module "target_group_app_<name>_pvt"`
- `ecr/repositories.tf`: 1 `module "ecr_app_<name>"`

### Orientação actual

A arquitectura actual é **orientada a aplicação** (existe um módulo "app" que contém todos os workloads). Dentro desse módulo, os workloads são representados como **ficheiros Terraform separados** — não como instâncias de uma abstração comum.

---

## 3. Problemas Identificados

### P1 — Nenhuma abstração de workload: a duplicação está na camada de orquestração

Os módulos de baixo nível (`task_definition`, `service`, `autoscaling`, `securitygroup`, `alb`, `ecr`) são bem abstraídos. Mas a camada que os orquestra **não tem abstração**. Cada workload é um conjunto de chamadas de módulo repetidas à mão.

Adicionar `app-notifications` requer editar manualmente:
1. `ecs/core/app-notifications.tf` (novo ficheiro)
2. `networking/security_groups.tf` (novo bloco)
3. `networking/outputs.tf` (novo output)
4. `ecr/repositories.tf` (novo bloco)
5. `ecr/outputs.tf` (novo output)
6. `variables.tf` (nova entrada no map `container_name`, `port_*`)
7. `ecs/core/variables.tf` (pass-through)
8. `networking/target_groups.tf` (se HTTP)
9. `networking/alb.tf` / `main.tf` (se HTTP, nova listener rule)

Isso é **9 pontos de intervenção** para 1 workload.

### P2 — Os ficheiros de networking não sabem quais workloads existem

`networking/security_groups.tf` e `networking/outputs.tf` têm entradas hard-coded para os 5 workloads actuais. Se adicionar um workload em `ecs/core/`, **o networking não é actualizado automaticamente**. São ficheiros diferentes, sem relação declarativa entre si.

### P3 — O container_name e o port são variáveis map, mas a estrutura não escala com eles

```hcl
variable "container_name" {
  type = map(string)
  default = {
    app_api       = "container-app-api"
    app_worker    = "container-app-worker"
    ...
  }
}
```

Cada workload tem uma chave no map. Mas não há nada que garanta que um workload em `ecs/core/` tem a entrada correspondente em `container_name`. Pode haver divergência silenciosa.

### P4 — Duplicação nos módulos cluster/ vs root modules/

Existe um directório `cluster/modules/` que aparentemente duplica parte do `modules/` raiz. Isso cria risco de divergência entre versões dos mesmos módulos.

### P5 — O ecs/core/variables.tf é um pass-through sem valor

```hcl
variable "service_name" { type = string }
variable "base_name" { type = string }
variable "networking" {}    # untyped
variable "ecs_role" {}      # untyped
```

Variáveis sem tipo (`{}`) são um sinal de que a interface entre módulos não foi formalizada. Não há contrato explícito entre o módulo `ecs/core` e quem o chama.

### P6 — Workers e HTTP workloads partilham a mesma estrutura de variáveis

`app-manager.tf`, `app-scheduler.tf`, `app-worker.tf` são workers sem porta, sem target group, sem listener rule. Mas o módulo `ecs/core/variables.tf` tem `port_api_app` e `port_front_app` como variáveis — obrigando todos os workloads a "conhecer" os ports de outros workloads. Não há separação de responsabilidades.

### P7 — O Terraform State da aplicação é monolítico

Todo o `apps/app/` vive num único state file: `apps-terraform/prod/kriolu-kloud-app-us-east-1.tfstate`. Com 40+ workloads, um único `terraform plan` toca tudo — network, ECR, ECS, RDS — aumentando o tempo de plan e o raio de blast de qualquer alteração.

### P8 — Sem mecanismo de defaults + overrides

`cpu = 256, memory = "512", desired_tasks = 1` estão hard-coded em cada ficheiro de workload. Para mudar o default de memória para todos os workers, é preciso editar N ficheiros.

### P9 — Nomenclatura inconsistente nos módulos

`ecs_taks_definition_app_api` (typo: "taks" em vez de "task"), `ecs_autoscaling_app-front` (hífen em vez de underscore). Indica que os ficheiros foram criados manualmente sem uma convenção enforçada.

### P10 — Remote state hardcoded em dois lugares

`apps/app/ecs/remote-state-datasource.tf` e `apps/app/networking/remote-state-datasource.tf` têm exactamente o mesmo bloco `data "terraform_remote_state"` apontando para o mesmo bucket/key. Duplicação desnecessária.

---

## 4. Análise de Escalabilidade

### 1 app, 5 workloads (actual)

Gerenciável. O problema existe mas não é doloroso.

### 1 app, 15 workloads (+10 novos)

| Ficheiro | Intervenção necessária |
|---|---|
| `ecs/core/` | +10 ficheiros .tf |
| `networking/security_groups.tf` | +10 blocos module |
| `networking/outputs.tf` | +10 outputs |
| `ecr/repositories.tf` | +10 blocos module |
| `ecr/outputs.tf` | +10 outputs |
| `variables.tf` | +10 entradas no map |
| Novos HTTP workloads | +N target_groups + listener rules |

**~80 linhas de código de cola** para adicionar 10 workloads, espalhadas por 6 ficheiros.

### 2 apps, 30 workloads

Com 2 aplicações separadas (ex: "app" e "admin"), toda a estrutura de `apps/app/` seria duplicada para `apps/admin/`. A duplicação de ficheiros de infra de aplicação seria ~100% — cada nova app é uma cópia manual.

### 5 apps, 50+ workloads

`terraform plan` sobre um state monolítico que inclui 50+ ECS Services, 50+ ECR repos, 50+ SGs vai ser lento (facilmente 2-5 minutos). Qualquer erro afecta o plan inteiro. O blast radius de um `terraform apply` inclui todos os workloads de todas as apps.

### O que escala naturalmente

- Os módulos de baixo nível (`task_definition`, `service`, `autoscaling`, `securitygroup`, `alb`) — genéricos e reutilizáveis
- O modelo de ambientes (`environments/prod/`) — basta um `tfvars` diferente por ambiente
- A separação cluster vs apps — já é correcta

### O que não escala

- `ecs/core/` — ficheiro por workload, sem automação
- `networking/security_groups.tf`, `target_groups.tf`, `alb.tf` — entradas manuais
- `ecr/repositories.tf` — entradas manuais
- O state monolítico por aplicação
- O mecanismo de output — precisa de ser atualizado manualmente para cada novo workload

---

## 5. Abstração Arquitectural Correcta

### O que um workload é, conceptualmente

Um workload ECS EC2 tem estas propriedades essenciais:

```
IDENTIDADE:        nome, aplicação a que pertence, ambiente
COMPUTAÇÃO:        cpu, memory, desired_count, image
NETWORKING:        tipo (http | worker), porta (se http), domínio (se http)
SCALING:           min, max, cpu_target, memory_target
LIFECYCLE:         deployment config, health check
SEGURANÇA:         security group rules, IAM role
OBSERVABILIDADE:   log group, métricas
```

E tem um **tipo** que determina que infra de suporte precisa:

```
http_workload   → task_def + service + SG + TG + listener_rule + ECR + autoscaling
worker_workload → task_def + service + SG + ECR + autoscaling
```

### A abstração correcta: o Workload

A unidade fundamental de abstração deve ser o **workload** — não a aplicação, não o serviço ECS, não o módulo Terraform.

- **Responsabilidades próprias**: definir o que precisa (tipo, cpu, memory, port, scaling)
- **Responsabilidades da plataforma**: como a infra é criada (task_definition, service, SG, TG, etc.)

A configuração do workload descreve **o que deve existir**. Os módulos Terraform determinam **como é criado**.

---

## 6. Solução Arquitectural 1 — for_each no nível de ficheiro (evolutivo mínimo)

### Como funciona

Mantém a estrutura actual de diretórios mas substitui os ficheiros individuais (`app-api.tf`, `app-front.tf`, etc.) por um único ficheiro que usa `for_each` sobre uma variável map. Dois ficheiros: um para workloads HTTP, outro para workers.

### Estrutura Terraform

```
apps/app/
├── ecs/
│   ├── core/
│   │   ├── http_workloads.tf      # for_each sobre var.http_workloads
│   │   ├── worker_workloads.tf    # for_each sobre var.worker_workloads
│   │   └── variables.tf
│   └── ...
├── networking/
│   ├── security_groups.tf         # for_each sobre todos os workloads
│   ├── target_groups.tf           # for_each sobre http_workloads
│   ├── alb.tf                     # for_each sobre http_workloads
│   └── ...
└── ecr/
    └── repositories.tf            # for_each sobre todos os workloads
```

### Modelo de configuração

```hcl
# apps/app/variables.tf

variable "http_workloads" {
  type = map(object({
    cpu           = number
    memory        = number
    desired_count = number
    port          = number
    domain        = string
    priority      = number
    max_capacity  = number
    cpu_target    = number
  }))
  default = {
    api = {
      cpu = 256, memory = 512, desired_count = 1
      port = 4004, domain = "app-api.kriolu-kloud.cv"
      priority = 184, max_capacity = 15, cpu_target = 90
    }
    front = {
      cpu = 256, memory = 512, desired_count = 1
      port = 80, domain = "app.kriolu-kloud.cv"
      priority = 185, max_capacity = 3, cpu_target = 80
    }
  }
}

variable "worker_workloads" {
  type = map(object({
    cpu           = number
    memory        = number
    desired_count = number
    max_capacity  = number
    cpu_target    = number
  }))
  default = {
    worker    = { cpu = 256, memory = 512, desired_count = 1, max_capacity = 15, cpu_target = 80 }
    scheduler = { cpu = 256, memory = 512, desired_count = 1, max_capacity = 8,  cpu_target = 80 }
    manager   = { cpu = 256, memory = 512, desired_count = 1, max_capacity = 3,  cpu_target = 80 }
  }
}
```

```hcl
# apps/app/ecs/core/http_workloads.tf

module "task_def_http" {
  for_each           = var.http_workloads
  source             = "../../../../modules/ecs_ec2/task_definition"
  name               = "${var.base_name}-${each.key}-tf"
  cpu                = each.value.cpu
  memory             = tostring(each.value.memory)
  container_port     = each.value.port
  docker_repo        = var.ecr_repos[each.key].ecr_repository_url
  # ...
}

module "service_http" {
  for_each              = var.http_workloads
  source                = "../../../../modules/ecs_ec2/service"
  name                  = "${var.base_name}-${each.key}"
  desired_tasks         = each.value.desired_count
  use_load_balancer     = true
  arn_target_group      = [var.target_groups[each.key].arn_tg]
  arn_task_definition   = module.task_def_http[each.key].arn_task_definition
  arn_security_group    = var.security_groups[each.key].sg_id
  # ...
}
```

### Vantagens

- Migração mínima — não reorganiza a estrutura de diretórios
- Adicionar workload = adicionar 1 entrada no map em `variables.tf`
- Nenhum ficheiro novo em `ecs/core/`, `networking/`, `ecr/`

### Desvantagens

- Dois maps separados (`http_workloads` vs `worker_workloads`) — precisa de escolher o tipo certo
- O wiring entre security_groups, task_definitions e target_groups ainda é feito via outputs passados como variáveis — interface complexa
- `for_each` com módulos exige que as chaves sejam `string` — limitação de naming

### Escalabilidade

- **5 workloads**: excelente
- **20 workloads**: excelente — adicionar uma entrada no map
- **50+ workloads**: bom, mas o state monolítico começa a ser lento

### Developer Experience

Adicionar novo workload: editar **1 ficheiro**, **1 bloco** no map. Muito melhor que 9 ficheiros.

### Complexidade operacional

Baixa. A estrutura de diretórios não muda. Quem já conhece o projecto entende.

### Migração

Moderada. Requer reescrever os módulos core mas não requer `terraform state mv`.

---

## 7. Solução Arquitectural 2 — Módulo Composto de Workload ⭐ RECOMENDADA

### Como funciona

Cria um novo módulo `modules/ecs_ec2/workload/` que encapsula toda a infra de um workload (task_def + service + autoscaling + SG + opcionalmente TG + listener rule + ECR). A configuração de cada app declara os seus workloads como chamadas a esse módulo.

Este módulo recebe um `type = "http" | "worker"` e constrói o conjunto correcto de recursos.

### Estrutura Terraform

```
modules/
└── ecs_ec2/
    └── workload/                  # ← módulo novo
        ├── main.tf                # orquestra task_def + service + autoscaling
        ├── variables.tf           # interface do workload
        └── outputs.tf

apps/
└── app/
    ├── workloads.tf               # 1 module call por workload ← toda a definição aqui
    ├── main.tf
    ├── variables.tf               # só vars de plataforma (vpc_id, cluster_arn, etc.)
    └── data.tf
```

### Modelo de configuração

```hcl
# apps/app/workloads.tf — TODA a definição de workloads numa página

module "api" {
  source = "../../modules/ecs_ec2/workload"

  # identidade
  name        = "api"
  app_name    = local.base_name
  environment = var.environment_name

  # tipo
  type         = "http"
  port         = 4004
  domain       = "app-api.kriolu-kloud.cv"
  alb_priority = 184

  # computação
  cpu    = 256
  memory = 512

  # scaling
  min_capacity = 1
  max_capacity = 15
  cpu_target   = 90

  # plataforma
  cluster_id           = local.cluster.ecs_cluster_id
  cluster_name         = local.cluster.ecs_cluster_name
  vpc_id               = data.aws_vpc.crawler_vpc.id
  private_subnets      = data.aws_subnets.private_subnets.ids
  allowed_cidrs        = [data.aws_vpc.crawler_vpc.cidr_block, var.kriolu_kloud_vpn]
  private_listener_arn = local.cluster.https_listener_arn_private
  execution_role_arn   = module.ecs_role.arn_role
  task_role_arn        = module.ecs_role.arn_role_ecs_task_role
  aws_region           = var.aws_region
}

module "worker" {
  source = "../../modules/ecs_ec2/workload"
  name        = "worker"
  app_name    = local.base_name
  type        = "worker"          # ← sem port, sem TG, sem listener rule
  max_capacity = 15
  # plataforma...
}

module "scheduler" {
  source = "../../modules/ecs_ec2/workload"
  name         = "scheduler"
  app_name     = local.base_name
  type         = "worker"
  cpu          = 512             # ← override específico
  memory       = 1024
  max_capacity = 8
  # plataforma...
}
```

### O módulo `modules/ecs_ec2/workload/variables.tf`

```hcl
# Identidade
variable "name"        { type = string }
variable "app_name"    { type = string }
variable "environment" { type = string }

# Tipo de workload
variable "type" {
  type = string
  validation {
    condition     = contains(["http", "worker"], var.type)
    error_message = "type must be 'http' or 'worker'."
  }
}

# Computação (com defaults)
variable "cpu"           { type = number; default = 256 }
variable "memory"        { type = number; default = 512 }
variable "desired_count" { type = number; default = 1 }

# HTTP-only (ignorado se type = "worker")
variable "port"               { type = number; default = null }
variable "domain"             { type = string; default = null }
variable "alb_priority"       { type = number; default = null }
variable "health_check_path"  { type = string; default = "/health" }
variable "health_check_matcher" { type = string; default = "200-499" }

# Scaling
variable "min_capacity"  { type = number; default = 1 }
variable "max_capacity"  { type = number; default = 5 }
variable "cpu_target"    { type = number; default = 80 }
variable "memory_target" { type = number; default = 80 }

# Plataforma (passados pelo caller)
variable "cluster_id"           { type = string }
variable "cluster_name"         { type = string }
variable "vpc_id"               { type = string }
variable "private_subnets"      { type = list(string) }
variable "allowed_cidrs"        { type = list(string) }
variable "private_listener_arn" { type = string; default = null }
variable "execution_role_arn"   { type = string }
variable "task_role_arn"        { type = string }
variable "aws_region"           { type = string }

# Opcional: environment variables para o container
variable "environment_vars" {
  type    = list(object({ name = string; value = string }))
  default = []
}
```

### O módulo `modules/ecs_ec2/workload/main.tf`

```hcl
locals {
  is_http   = var.type == "http"
  full_name = "${var.app_name}-${var.name}"
}

module "ecr" {
  source = "../../ecr"
  name   = local.full_name
}

module "security_group" {
  source              = "../../securitygroup"
  name                = "${local.full_name}-task-sg"
  description         = "Controls access to ${local.full_name} ECS task"
  vpc_id              = var.vpc_id
  ingress_port        = local.is_http ? var.port : null
  cidr_blocks_ingress = var.allowed_cidrs
}

module "target_group" {
  count  = local.is_http ? 1 : 0
  source = "../../alb"
  create_target_group              = true
  name                             = "${local.full_name}-pvt"
  port                             = var.port
  protocol                         = "HTTP"
  vpc_id                           = var.vpc_id
  tg_type                          = "instance"
  health_check_path                = var.health_check_path
  health_check_port                = var.port
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 3
  health_check_interval            = 5
  health_check_matcher             = var.health_check_matcher
}

resource "aws_alb_listener_rule" "rule" {
  count        = local.is_http ? 1 : 0
  listener_arn = var.private_listener_arn
  priority     = var.alb_priority
  action {
    type             = "forward"
    target_group_arn = module.target_group[0].arn_tg
  }
  condition {
    host_header { values = [var.domain] }
  }
}

module "task_definition" {
  source             = "../task_definition"
  name               = "${local.full_name}-tf"
  network_mode       = "bridge"
  container_name     = "container-${local.full_name}"
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
  cpu                = var.cpu
  memory             = tostring(var.memory)
  docker_repo        = module.ecr.ecr_repository_url
  region             = var.aws_region
  container_port     = local.is_http ? var.port : null
  command            = "[]"
  port_mappings      = local.is_http ? jsonencode([{
    containerPort = var.port
    hostPort      = 0
  }]) : "[]"
  environment = jsonencode(var.environment_vars)
}

module "service" {
  source                            = "../service"
  name                              = local.full_name
  desired_tasks                     = var.desired_count
  arn_security_group                = module.security_group.sg_id
  ecs_cluster_id                    = var.cluster_id
  use_load_balancer                 = local.is_http
  arn_target_group                  = local.is_http ? [module.target_group[0].arn_tg] : []
  arn_task_definition               = module.task_definition.arn_task_definition
  subnets_id                        = var.private_subnets
  container_port                    = local.is_http ? [var.port] : []
  container_name                    = ["container-${local.full_name}"]
  health_check_grace_period_seconds = local.is_http ? 15 : 0
}

module "autoscaling" {
  depends_on    = [module.service]
  source        = "../autoscaling"
  name          = local.full_name
  cluster_name  = var.cluster_name
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity
  cpu_target    = var.cpu_target
  memory_target = var.memory_target
}
```

### Vantagens

- **Um module call por workload** — a definição completa está num único lugar
- O tipo (`http` vs `worker`) determina automaticamente que recursos são criados
- Defaults claros e overrides simples
- Adicionar um novo tipo de workload (ex: `scheduled`) = adicionar condicionais no módulo, sem tocar nas apps
- A interface do workload é explícita e tipada
- Elimina todos os outputs manuais de networking e ECR

### Desvantagens

- O módulo `workload/` tem `count`/`for_each` internos que aumentam a complexidade do state path
- Se o módulo `workload/` mudar, afecta todos os workloads — requer cuidado
- A variável `networking` passada ao módulo precisa de ser um objecto bem definido
- State paths mais profundos: `module.api.module.target_group[0].aws_alb_target_group.target_group`

### Escalabilidade

- **5 workloads**: excelente
- **20 workloads**: excelente — 20 blocos `module` num único `workloads.tf`
- **50+ workloads**: bom, mas o state continua monolítico por aplicação

### Developer Experience

Adicionar workload: copiar 10-15 linhas num ficheiro, mudar nome e tipo. **Sem tocar em nenhum outro ficheiro**.

### Migração

Moderada. Requer `terraform state mv` para os recursos existentes.

---

## 8. Solução Arquitectural 3 — Plataforma Declarativa com Registry de Workloads

### Como funciona

Separa completamente a **plataforma** da **configuração de workloads**. Os workloads são declarados num único ficheiro de configuração (`workloads.auto.tfvars`) como um mapa. Um único módulo de plataforma processa esse mapa com `for_each` e cria todos os recursos necessários.

### Estrutura Terraform

```
cluster-ecs-terraform/
├── platform/                          # ← módulo de plataforma genérico
│   ├── main.tf                        # for_each sobre workloads map
│   ├── workloads.tf
│   ├── networking.tf
│   ├── ecr.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── apps/
│   └── app/
│       ├── workloads.auto.tfvars      # ← declaração dos workloads (dados puros)
│       ├── main.tf                    # chama platform/ com os workloads
│       └── data.tf
│
└── environments/
    └── prod/
        ├── main.tf
        └── prod.auto.tfvars
```

### Modelo de configuração

```hcl
# apps/app/workloads.auto.tfvars  ← arquivo de configuração puro, sem HCL lógico

workloads = {
  api = {
    type         = "http"
    cpu          = 256
    memory       = 512
    desired      = 1
    port         = 4004
    domain       = "app-api.kriolu-kloud.cv"
    alb_priority = 184
    scaling = {
      min        = 1
      max        = 15
      cpu_target = 90
    }
  }

  front = {
    type         = "http"
    cpu          = 256
    memory       = 512
    desired      = 1
    port         = 80
    domain       = "app.kriolu-kloud.cv"
    alb_priority = 185
    scaling = {
      min        = 1
      max        = 3
      cpu_target = 80
    }
  }

  worker = {
    type    = "worker"
    cpu     = 256
    memory  = 512
    desired = 1
    scaling = {
      min        = 1
      max        = 15
      cpu_target = 80
    }
  }

  scheduler = {
    type    = "worker"
    cpu     = 256
    memory  = 512
    desired = 1
    scaling = {
      min        = 1
      max        = 8
      cpu_target = 80
    }
  }
}
```

```hcl
# platform/main.tf

locals {
  http_workloads   = { for k, v in var.workloads : k => v if v.type == "http" }
  worker_workloads = { for k, v in var.workloads : k => v if v.type == "worker" }
}

module "task_def" {
  for_each = var.workloads
  source   = "../modules/ecs_ec2/task_definition"
  name     = "${var.app_name}-${each.key}-tf"
  cpu      = each.value.cpu
  memory   = tostring(each.value.memory)
  # ...
}

module "security_group" {
  for_each     = var.workloads
  source       = "../modules/securitygroup"
  name         = "${var.app_name}-${each.key}-task-sg"
  vpc_id       = var.networking.vpc_id
  ingress_port = try(each.value.port, null)
  # ...
}

module "target_group" {
  for_each = local.http_workloads
  source   = "../modules/alb"
  create_target_group = true
  name     = "${var.app_name}-${each.key}-pvt"
  port     = each.value.port
  # ...
}

resource "aws_alb_listener_rule" "rules" {
  for_each     = local.http_workloads
  listener_arn = var.networking.private_listener_arn
  priority     = each.value.alb_priority
  action {
    type             = "forward"
    target_group_arn = module.target_group[each.key].arn_tg
  }
  condition {
    host_header { values = [each.value.domain] }
  }
}

module "service" {
  for_each          = var.workloads
  source            = "../modules/ecs_ec2/service"
  name              = "${var.app_name}-${each.key}"
  desired_tasks     = each.value.desired
  use_load_balancer = each.value.type == "http"
  arn_target_group  = each.value.type == "http" ? [module.target_group[each.key].arn_tg] : []
  arn_security_group = module.security_group[each.key].sg_id
  # ...
}

module "ecr" {
  for_each = var.workloads
  source   = "../modules/ecr"
  name     = "${var.app_name}-${each.key}"
}

module "autoscaling" {
  for_each     = var.workloads
  source       = "../modules/ecs_ec2/autoscaling"
  name         = "${var.app_name}-${each.key}"
  cluster_name = var.cluster.ecs_cluster_name
  min_capacity = each.value.scaling.min
  max_capacity = each.value.scaling.max
  cpu_target   = each.value.scaling.cpu_target
}
```

### Vantagens

- **Máxima separação** entre plataforma e configuração
- Adicionar workload = adicionar 1 entrada num ficheiro `.tfvars` (sem HCL lógico)
- O ficheiro `workloads.auto.tfvars` pode ser gerido por outras equipas sem conhecer Terraform profundamente
- Suporta facilmente múltiplas aplicações — basta criar `apps/admin/` com o seu próprio `workloads.auto.tfvars`
- Zero duplicação de código Terraform entre workloads
- Possibilita automação: um script pode gerar o `workloads.auto.tfvars` a partir de um catálogo de serviços

### Desvantagens

- **Flexibilidade limitada para workloads atípicos**: o schema do map precisa de ser extendido para casos especiais
- **O schema do mapa é rígido**: todos os workloads partilham o mesmo tipo de objecto
- **Debugging mais difícil**: `module.service["api"]` — os paths de state são data-driven
- **Curva de aprendizagem maior**: pattern `for_each` + `locals` mais sofisticado
- **`for_each` sobre modules com recursos condicionais**: state paths complexos

### Escalabilidade

- **5 workloads**: excelente
- **20 workloads**: excelente — 20 entradas no `.tfvars`
- **50+ workloads**: funciona, mas o state monolítico por app fica pesado

### Developer Experience

Adicionar workload: adicionar **1 bloco no ficheiro `.tfvars`**, sem tocar em Terraform. O melhor caso de todos.

### Complexidade operacional

Alta. O módulo `platform/` é sofisticado. Debugar requer entender o `for_each` e o state path.

### Migração

Alta. Requer `terraform state mv` para cada recurso de cada workload.

---

## 9. Matriz Comparativa

| Critério | Sol. 1: for_each evolutivo | Sol. 2: Módulo Workload ⭐ | Sol. 3: Plataforma Declarativa |
|---|:---:|:---:|:---:|
| **Escalabilidade (workloads)** | 8 | 9 | 10 |
| **Duplicação Terraform** | 3 | 9 | 10 |
| **Manutenção** | 6 | 9 | 8 |
| **Developer Experience** | 7 | 8 | 9 |
| **Flexibilidade por workload** | 9 | 8 | 5 |
| **Compatibilidade com ECS EC2** | 10 | 10 | 9 |
| **Gestão de ambientes** | 7 | 8 | 9 |
| **Complexidade operacional** | 4✅ | 6 | 8❌ |
| **Facilidade de migração** | 8✅ | 5 | 3❌ |
| **Extensibilidade (novos tipos)** | 5 | 9 | 7 |
| **Adequação a longo prazo** | 6 | 9 | 8 |
| **Debugging / visibilidade** | 9✅ | 7 | 5❌ |

> Notas: ✅ = ponto forte  ❌ = ponto fraco  
> Sol. 1 tem Flexibilidade=9 porque cada workload ainda pode ter override ad-hoc.  
> Sol. 3 tem Flexibilidade=5 porque o schema do mapa limita workloads atípicos.  
> Sol. 2 tem o melhor balanço entre extensibilidade e flexibilidade por workload.

---

## 10. Arquitectura Recomendada: Solução 2

### Por que esta e não as outras

**vs. Sol. 1**: For_each evolutivo resolve o problema de duplicação mas não cria uma abstração de workload. Continua a existir acoplamento entre ecs/core, networking e ecr. Não resolve workloads com características únicas.

**vs. Sol. 3**: A abordagem declarativa pura reduz demasiado a flexibilidade por workload. Workloads com requisitos únicos (múltiplos ports, sidecars, regras IAM específicas) precisam de ser expressos num schema genérico — que cresce e torna-se difícil de manter. O custo de migração é muito alto.

**Sol. 2 é o ponto óptimo**:
- Cada workload é um `module "name" {}` explícito — **legível e debugável**
- A interface do workload é um contrato Terraform tipado
- Workloads atípicos podem ter o que precisam declarado explicitamente no nível do module call
- O módulo `workload/` encapsula a lógica de tipo — adicionar `scheduled` = adicionar condicionais no módulo, sem tocar nas apps
- A migração é mais segura que Sol. 3

**Trade-offs aceites:**
- O módulo `workload/` é mais complexo que os módulos actuais individuais
- State paths ficam mais profundos
- Requer `terraform state mv` durante a migração

---

## 11. Arquitectura Alvo Detalhada (Sol. 2)

### Estrutura de diretórios final

```
cluster-ecs-terraform/
├── modules/
│   ├── ecs_ec2/
│   │   ├── workload/              # ← NOVO módulo composto
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── task_definition/       # sem alterações
│   │   ├── service/               # sem alterações
│   │   ├── autoscaling/           # sem alterações
│   │   └── cluster/               # sem alterações
│   ├── alb/                       # sem alterações
│   ├── ecr/                       # sem alterações
│   ├── iam/                       # sem alterações
│   ├── postgres/                  # sem alterações
│   └── securitygroup/             # sem alterações
│
├── apps/
│   └── app/
│       ├── workloads.tf           # ← ÚNICO ficheiro: um module por workload
│       ├── main.tf                # IAM, RDS, chamadas de plataforma
│       ├── variables.tf           # vars de plataforma (vpc, cluster, etc.)
│       ├── data.tf
│       ├── locals.tf
│       ├── iam.tf
│       ├── outputs.tf
│       └── provider.tf
│   └── environments/
│       └── prod/
│           ├── main.tf
│           └── variables.tf
│
└── cluster/                       # sem alterações estruturais
```

### Separação: Plataforma vs Workload

| Responsabilidade | Onde vive |
|---|---|
| ECS Cluster, ALBs, ASG, Capacity Provider | `cluster/` |
| VPC, subnets, security groups base | `network/` |
| IAM roles da aplicação | `apps/app/iam.tf` |
| RDS Aurora | `apps/app/main.tf` |
| **Task Definition, Service, Autoscaling** | `modules/ecs_ec2/workload/` |
| **Security Group da task** | `modules/ecs_ec2/workload/` |
| **Target Group + Listener Rule** (se HTTP) | `modules/ecs_ec2/workload/` |
| **ECR Repository** | `modules/ecs_ec2/workload/` |
| **Declaração de cada workload** | `apps/app/workloads.tf` |

---

## 12. Exemplos de Workloads (Arquitectura Alvo)

### Exemplo A — API HTTP nova

```hcl
module "payments_api" {
  source = "../../modules/ecs_ec2/workload"
  name         = "payments-api"
  app_name     = local.base_name
  type         = "http"
  port         = 4010
  domain       = "payments-api.kriolu-kloud.cv"
  alb_priority = 190
  cpu          = 512           # mais CPU para workload de pagamentos
  memory       = 1024
  max_capacity = 10
  cpu_target   = 70
  health_check_path    = "/api/health"
  health_check_matcher = "200"
  environment_vars = [
    { name = "PAYMENT_PROVIDER", value = "stripe" }
  ]
  # plataforma...
}
```

### Exemplo B — Worker de queue

```hcl
module "email_worker" {
  source        = "../../modules/ecs_ec2/workload"
  name          = "email-worker"
  app_name      = local.base_name
  type          = "worker"
  cpu           = 256
  memory        = 512
  desired_count = 2             # começa com 2 para drain de filas
  min_capacity  = 1
  max_capacity  = 20
  cpu_target    = 60
  # sem port, domain, alb_priority
  # plataforma...
}
```

### Exemplo C — Frontend com health check customizado

```hcl
module "admin_front" {
  source               = "../../modules/ecs_ec2/workload"
  name                 = "admin-front"
  app_name             = local.base_name
  type                 = "http"
  port                 = 3000
  domain               = "admin.kriolu-kloud.cv"
  alb_priority         = 200
  health_check_path    = "/"
  health_check_matcher = "200-302"  # aceita redirects do SPA
  max_capacity         = 2
  # plataforma...
}
```

### Exemplo D — App com múltiplos workloads (nova aplicação "billing")

```hcl
# apps/billing/workloads.tf

module "billing_api" {
  source   = "../../modules/ecs_ec2/workload"
  name     = "billing-api"
  app_name = "p-billing"         # base_name diferente da app "app"
  type     = "http"
  port     = 4020
  domain   = "billing-api.kriolu-kloud.cv"
  alb_priority = 210
  # plataforma...
}

module "billing_processor" {
  source   = "../../modules/ecs_ec2/workload"
  name     = "billing-processor"
  app_name = "p-billing"
  type     = "worker"
  cpu      = 1024               # mais CPU para processamento
  memory   = 2048
  # plataforma...
}

module "billing_reporter" {
  source   = "../../modules/ecs_ec2/workload"
  name     = "billing-reporter"
  app_name = "p-billing"
  type     = "worker"
  # plataforma...
}
```

Toda a infra de billing vive num ficheiro `apps/billing/workloads.tf`. O módulo `workload/` é reutilizado sem modificação.

---

## 13. Estratégia de Migração

### Princípio: não destruir e recriar — mover no state

A maioria dos recursos pode ser movida no state com `terraform state mv` sem impacto nos serviços em execução.

### Fase 0: Preparação (sem alterações AWS)

1. Criar `modules/ecs_ec2/workload/` com o módulo composto
2. Escrever `apps/app/workloads.tf` com os 5 workloads declarados via módulo
3. **Não remover** os ficheiros antigos ainda
4. Fazer `terraform plan` — deve mostrar "nada a fazer" se o state mv for correcto

### Fase 1: Migração de state (sem downtime)

Para cada workload (exemplo: `api`):

```bash
# Task Definition
terraform state mv \
  'module.ecs_clusters.module.ecs_core_services.module.ecs_taks_definition_app_api.aws_ecs_task_definition.ecs_task_definition' \
  'module.api.module.task_definition.aws_ecs_task_definition.ecs_task_definition'

# ECS Service
terraform state mv \
  'module.ecs_clusters.module.ecs_core_services.module.ecs_service_app_api.aws_ecs_service.service' \
  'module.api.module.service.aws_ecs_service.service'

# Autoscaling
terraform state mv \
  'module.ecs_clusters.module.ecs_core_services.module.ecs_autoscaling_app_api.aws_appautoscaling_target.ecs_target' \
  'module.api.module.autoscaling.aws_appautoscaling_target.ecs_target'

# Security Group
terraform state mv \
  'module.networking.module.security_group_ecs_task_app_api.aws_security_group.sg' \
  'module.api.module.security_group.aws_security_group.sg'

# Target Group (só HTTP)
terraform state mv \
  'module.networking.module.target_group_app_api_pvt.aws_alb_target_group.target_group[0]' \
  'module.api.module.target_group[0].aws_alb_target_group.target_group[0]'

# ECR
terraform state mv \
  'module.ecr_repositories.module.ecr_app_api.aws_ecr_repository.ecr_repository' \
  'module.api.module.ecr.aws_ecr_repository.ecr_repository'
```

Repetir para `front`, `worker`, `scheduler`, `manager`.

**Validação após cada workload**: `terraform plan` deve mostrar 0 changes.

### Fase 2: Remover ficheiros antigos

Depois de todos os workloads migrados e `terraform plan` = 0 changes:

- Remover `apps/app/ecs/core/app-*.tf`
- Remover `apps/app/networking/security_groups.tf`, `target_groups.tf`, `alb.tf`
- Remover `apps/app/ecr/repositories.tf`
- Simplificar `outputs.tf` — agora usa `module.api.outputs.*`
- Simplificar `variables.tf` — remover `container_name` map, portas isoladas

### Fase 3: Validação final

```bash
terraform plan   # deve mostrar 0 changes
terraform apply  # deve mostrar "Apply complete! Resources: 0 added, 0 changed, 0 destroyed"
```

### Riscos por fase

| Fase | Risco | Mitigação |
|---|---|---|
| Fase 0 | Módulo novo quebra validate | Testar em ambiente homolog primeiro |
| Fase 1 | `state mv` com path errado recria recursos | Validar com `terraform plan` após cada mv |
| Fase 1 | ECS Service recriado causa downtime | Não deve acontecer com `state mv` correcto |
| Fase 2 | Ficheiro removido mas state mv incompleto | Não remover antes de `terraform plan` = 0 changes |

### Duração estimada

| Fase | Duração |
|---|---|
| Fase 0 — criar módulo `workload/` | 2-3 horas |
| Fase 1 — `terraform state mv` dos 5 workloads | 1-2 horas |
| Fase 2 — remoção e limpeza | 30 minutos |
| **Total** | **~1 dia** |

---

## 14. Riscos e Problemas Adicionais

### R1 — Dois conjuntos de módulos: `cluster/` e `modules/` raiz

Existe `cluster/modules/` e `modules/` raiz. Se forem versões diferentes do mesmo código, qualquer bug corrigido num pode não ser corrigido no outro. **Recomendação**: consolidar num único `modules/` raiz.

### R2 — O Terraform state por app é monolítico e inclui RDS

O `apps-terraform/prod/kriolu-kloud-app-us-east-1.tfstate` inclui ECS Services, ECR, RDS, IAM. Um `terraform apply` acidental pode afectar o RDS. **Recomendação a médio prazo**: separar o state de dados (RDS) do state de compute (ECS Services, ECR).

### R3 — Listener rules com priority hard-coded

Se duas apps adicionam workloads HTTP com a mesma priority, o apply falha com conflito. **Recomendação**: documentar ranges de priority por aplicação (ex: app = 180-199, billing = 200-219).

### R4 — IAM role partilhada entre todos os workloads

Todos os 5 workloads usam o mesmo `ecs_task_role`. Se um workload precisar de acesso a S3 e outro não, ambos terão acesso. Viola o princípio do menor privilégio. **Recomendação**: o módulo `workload/` deve suportar `extra_iam_policies = []` opcional.

### R5 — `network_mode = "bridge"` bloqueia awsvpc

`bridge` mode não suporta Security Groups a nível de task. Para isolamento real entre workloads, `awsvpc` seria necessário — mas requer ENI trunking com limitações por tipo de instância. A escolha de `bridge` é provavelmente consciente para compatibilidade com ECS EC2, mas deve ser documentada.

### R6 — Sem gestão de secrets

`environment_vars` no container são plain text. Variáveis sensíveis não deveriam ser env vars — deveriam ser Secrets Manager ou SSM Parameter Store referenciados no `container_definitions`. **Recomendação**: adicionar `secrets = []` ao módulo `workload/`.

### R7 — Sem versionamento de módulos

Os módulos são referenciados por path relativo. Qualquer alteração no módulo afecta **imediatamente** todos os callers. **Recomendação a longo prazo**: módulos publicados num registry com versões semânticas.

### R8 — O `homolog` environment existe mas não está completo

`apps/environments/homolog/` existe mas não foi completado. Ao migrar para Sol. 2, garantir que `homolog/` usa o mesmo módulo `app` com overrides de ambiente — não uma cópia de ficheiros.

---

## 15. Recomendação Final

**Migrar para Arquitectura 2 (Módulo Composto de Workload) em fases.**

### Sequência prática

| Quando | Acção |
|---|---|
| **Agora** | Concluir o apply actual. Não migrar em produção sem testes. |
| **Curto prazo** | Criar `modules/ecs_ec2/workload/` e testá-lo no ambiente `homolog` com 1-2 workloads. |
| **Médio prazo** | Migrar state em prod (Fase 1 da estratégia). Limpar ficheiros antigos (Fase 2). |
| **Longo prazo** | Separar o state de RDS do state de compute. |

O investimento é **1-2 dias de trabalho**. O retorno: qualquer workload novo fica pronto em 15 minutos — um `module` block, um push, pipeline CI aplica. Sem tocar em 9 ficheiros diferentes.

---

*Análise gerada com base na inspeção directa do código em `cluster-ecs-terraform/`. Nenhuma assunção foi feita sobre que arquitectura estava prevista — a recomendação é consequência da análise.*
