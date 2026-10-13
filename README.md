# GameTrackerProject-Infra

## Présentation

Ce dépôt contient toute l'**Infrastructure as Code (IaC)** nécessaire au déploiement de la plateforme **GameTracker** sur **Amazon Web Services (AWS)** à l'aide de **Terraform**.

L'objectif est de provisionner automatiquement une infrastructure cloud complète, sécurisée et proche d'un environnement de production : réseau isolé, load balancing, auto scaling, base de données managée, gestion des secrets et diffusion via CDN en HTTPS.

---

## Architecture

<table align="center">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6c6e9561-0826-4f57-8d3d-16766aa6cf1b" alt="Architecture AWS de GameTracker" width="100%" />
    </td>
  </tr>
  <tr>
    <td align="center">
      <em>Architecture AWS de GameTracker (région eu-west-3).<br />
      Traits pleins : trafic applicatif — Pointillés : trafic de démarrage et sortie (pull d'images, secrets, Internet).</em>
    </td>
  </tr>
</table>

### Flux d'une requête

```text
Utilisateur ──HTTPS──▶ CloudFront ──HTTP:80──▶ ALB ──▶ Front :80   (Angular)
                                                  └──▶ Back :8081 (Spring Boot) ──▶ RDS MySQL :3306
```

---

## Infrastructure déployée

| Module | Ressources AWS | Rôle | Stack |
|---|---|---|---|
| **network** | VPC, 6 subnets (public / private_app / private_data × 2 AZ), Internet Gateway, NAT Gateway, route tables, VPC endpoint S3 | Réseau isolé sur 2 zones. Les subnets de la base n'ont aucun accès sortant. | `terraform/` |
| **security** | 4 Security Groups (ALB, Front, Back, MySQL) | Flux chaînés : CloudFront → ALB → Front / Back → RDS | `terraform/` |
| **secrets** | SSM Parameter Store, Secrets Manager | Configuration non sensible (SSM) et secrets du back : mot de passe BDD, Cloudinary, JWT (Secrets Manager) | `terraform/` |
| **iam** | Rôles et instance profiles EC2 front / back | Moindre privilège : pull ECR, lecture des secrets, accès Session Manager | `terraform/` |
| **database** | Amazon RDS MySQL 8.4 (db.t4g.micro), subnet group | Base managée, chiffrée, non publique. Snapshot final au destroy, restauration au prochain apply. | `terraform/` |
| **load_balancing** | Application Load Balancer, 2 target groups | `/gametracker/*` → back (:8081), le reste → front (:80) | `terraform/` |
| **compute** | Launch templates, 2 Auto Scaling Groups (front 2 instances, back 2 à 4) | Instances EC2 qui lancent les conteneurs Docker depuis ECR | `terraform/` |
| **cdn** | Distribution Amazon CloudFront | HTTPS gratuit sans nom de domaine, cache du front, API non mise en cache | `terraform/` |
| **registry** | 2 dépôts Amazon ECR (front, back) + lifecycle policies | Stockage des images Docker | `terraform-persistent/` |
| **storage** | Bucket Amazon S3 (versioning, chiffrement, lifecycle) | Historique des sauvegardes MySQL | `terraform-persistent/` |

### Choix de conception

| Choix | Raison |
|---|---|
| Deux stacks Terraform séparées | Les images ECR et le bucket S3 survivent à un `terraform destroy`. Les images doivent exister **avant** le déploiement de l'infra. |
| Une seule NAT Gateway | Réduit le coût (environ 35 €/mois par NAT). En production, on en mettrait une par zone. |
| RDS en une seule zone | Couvert par le free tier. Le Multi-AZ est activable pour une démonstration. |
| CloudFront devant l'ALB | HTTPS sans nom de domaine. L'ALB n'accepte que le trafic venant de CloudFront. |
| Pas de SSH | Accès aux instances via AWS Systems Manager Session Manager. |

---

## Structure du projet

```text
GameTrackerProject-Infra/
├── docs/
│   └── architecture.drawio.svg     # Schéma d'architecture (modifiable dans draw.io)
│
├── terraform-persistent/           # Stack persistante : jamais détruite
│   ├── main.tf                     # Appelle les modules registry et storage
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
│
└── terraform/                      # Stack principale : détruite en fin de séance
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── terraform.tfvars            # Non versionné (contient les secrets)
    └── modules/
        ├── network/
        ├── security/
        ├── secrets/
        ├── iam/
        ├── database/
        ├── load_balancing/
        ├── compute/
        ├── cdn/
        ├── registry/               # Utilisé par terraform-persistent
        └── storage/                # Utilisé par terraform-persistent
```

Chaque module est responsable d'une partie spécifique de l'infrastructure afin de conserver un projet modulaire, maintenable et facilement extensible.

---

## Déploiement

### Prérequis

- Un compte AWS et l'**AWS CLI** configurée (`aws sts get-caller-identity` doit répondre)
- **Terraform** ≥ 1.7
- **Docker**
- *(Facultatif)* le plugin **Session Manager** pour l'AWS CLI, pour se connecter aux instances

### 1. Créer le fichier `terraform/terraform.tfvars`

Ce fichier contient les secrets : il ne doit **jamais** être commité (il est dans le `.gitignore`).

```hcl
project_name = "gametracker"
environment  = "dev"
aws_region   = "eu-west-3"

vpc_cidr                  = "10.0.0.0/16"
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
private_data_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
availability_zones        = ["eu-west-3a", "eu-west-3b"]

spring_datasource_username = "gametracker"
rds_password               = "MotDePasseSolide!"   # 8 à 41 caractères, sans / @ " ni espace

cloudinary_cloud_name = "..."
cloudinary_api_key    = "..."
cloudinary_api_secret = "..."
jwt_secret            = "..."

restore_db_from_snapshot = false   # passer à true après le premier destroy
```

### 2. Déployer la stack persistante (une seule fois)

Crée les dépôts ECR et le bucket S3.

```bash
cd terraform-persistent
terraform init
terraform apply
```

### 3. Construire et pousser les images Docker

Les images doivent être présentes dans ECR **avant** le déploiement de la stack principale : les instances les téléchargent au démarrage.

```bash
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com

# Backend
docker build -t gametracker-back <chemin-vers-GameTrackerProject-Backend>
docker tag gametracker-back <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/gametracker-dev-back:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/gametracker-dev-back:latest

# Frontend
docker build -t gametracker-front <chemin-vers-GameTrackerProject-Frontend>
docker tag gametracker-front <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/gametracker-dev-front:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/gametracker-dev-front:latest
```

> Le front doit appeler l'API avec une **URL relative** (`/gametracker/...`) : la page est servie en HTTPS par CloudFront, qui route lui-même l'API vers le back.

### 4. Déployer la stack principale

```bash
cd ../terraform
terraform init
terraform apply
```

La création prend environ **15 minutes** (RDS et CloudFront sont les plus longs). Récupérer ensuite l'URL de l'application :

```bash
terraform output app_url
```

Les instances ont besoin de 3 à 5 minutes supplémentaires pour démarrer leurs conteneurs.

### 5. Initialiser les données (premier déploiement uniquement)

Se connecter à une instance back (console EC2 > Connect > Session Manager), puis :

```bash
curl -i -X POST http://localhost:8081/admin/seed/games
```

---

## Cycle de vie


### Mettre à jour une image

Après un nouveau `docker push`, remplacer les instances pour qu'elles téléchargent la nouvelle image :

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name gametracker-dev-back-asg --region eu-west-3
aws autoscaling start-instance-refresh --auto-scaling-group-name gametracker-dev-front-asg --region eu-west-3
```

Pour le front, vider aussi le cache CloudFront :

```bash
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
```

---

## Dépôts associés

### Backend

https://github.com/yoanlouvois/GameTrackerProject-Backend

API REST développée avec Spring Boot, utilisant MySQL et Docker.

### Frontend

https://github.com/yoanlouvois/GameTrackerProject-Frontend

Application web Angular consommant les API REST du backend.

---

## Évolutions prévues

- Configuration des instances avec **Ansible** (à la place des user data)
- NAT Gateway et RDS en **Multi-AZ** pour une haute disponibilité complète
