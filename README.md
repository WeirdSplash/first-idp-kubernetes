# 🚀 De Kubernetes a Platform Engineering: construyendo tu primer Internal Developer Portal en AWS

> **Charla:** De Kubernetes a Platform Engineering: construyendo tu primer Internal Developer Portal en AWS
> **Evento:** AWS Community Day Perú 2026
> **Fecha:** 4 de octubre de 2026
> **Speaker:** [Joice Chávez](https://www.linkedin.com/in/joicechavez/) · Senior DevOps Engineer @ NTT Data · AWS Community Builder

---

## 🎯 ¿Qué es esto?

Este repositorio acompaña la charla y contiene los archivos de referencia para construir un **Internal Developer Portal (IDP)** usando [Backstage](https://backstage.io) sobre AWS, con la stack completa mencionada en la presentación.

La idea central: dejar de que los desarrolladores sean "mini-ops" y construir una plataforma interna que encapsule la complejidad de la infraestructura — para que puedan llegar a producción en minutos, sin tickets, sin esperar al equipo de plataforma.

---

## 🧩 Platform vs Portal — aclaración importante

En esta charla usamos las siglas **IDP** para referirnos a **Internal Developer Portal** — la interfaz central desde donde los desarrolladores consumen la plataforma.

> **Analogía:** la plataforma es el aeropuerto entero. El portal es la terminal de pasajeros.

---

## 🏗️ Stack técnica

| Herramienta | Rol en la plataforma |
|---|---|
| **Backstage** | Portal del desarrollador — lo que ven y tocan |
| **Amazon EKS** | Compute — donde corre todo |
| **Amazon ECR** | Registro de imágenes Docker |
| **GitHub Actions** | Motor de CI — tests, build, push a ECR |
| **Argo CD** | Motor de CD — GitOps, deploya a EKS automáticamente |
| **Terraform** | Infraestructura como código |
| **AWS Secrets Manager** | Gestión de secretos |
| **IAM Roles for Service Accounts (IRSA)** | Permisos granulares sin access keys hardcodeadas |

---

## 📁 Estructura del repositorio

\`\`\`
first-idp-kubernetes/
│
├── backstage/
│   ├── app-config.yaml              # Configuración de Backstage
│   ├── docker-compose.yml           # Levantar Backstage localmente
│   ├── k8s-deployment.yaml          # Backstage en EKS con IRSA
│   ├── .env.example                 # Variables de entorno necesarias
│   └── templates/
│       └── nuevo-microservicio/     # Software Template (Golden Path)
│           ├── template.yaml        # Definición del template
│           └── skeleton/            # Código generado automáticamente
│               ├── main.py          # FastAPI app base
│               ├── Dockerfile       # Lista para EKS
│               ├── requirements.txt
│               ├── catalog-info.yaml
│               └── .github/workflows/ci.yaml  # Pipeline CI/CD completo
│
├── catalog/
│   ├── all-components.yaml          # Location — punto de entrada del catálogo
│   ├── servicio-pagos.yaml          # Ejemplo de componente en producción
│   └── servicio-usuarios.yaml       # Ejemplo de componente en producción
│
├── argocd/
│   ├── backstage-app.yaml           # App de Argo CD para Backstage
│   └── ejemplo-microservicio-app.yaml
│
├── kind/
│   └── cluster-config.yaml         # Clúster local para pruebas
│
└── .github/workflows/
    └── validate.yaml               # Validación de YAMLs del repo
\`\`\`

---

## ⚡ Quickstart — Levantar localmente en 5 minutos

### Pre-requisitos
- Docker y Docker Compose instalados
- Token de GitHub con permisos \`repo\` y \`workflow\`

### Pasos

\`\`\`bash
# 1. Clonar el repo
git clone https://github.com/WeirdSplash/first-idp-kubernetes
cd first-idp-kubernetes

# 2. Configurar variables de entorno
cp backstage/.env.example backstage/.env
# Editar .env y agregar tu GITHUB_TOKEN

# 3. Levantar Backstage + PostgreSQL
cd backstage
docker-compose up -d

# 4. Abrir el portal
open http://localhost:3000
\`\`\`

✅ Verás el catálogo con los servicios de ejemplo y el template para crear nuevos microservicios.

---

## 🔄 Flujo completo (el golden path en acción)

\`\`\`
Desarrollador entra a Backstage
        │
        ▼
Elige template "nuevo-microservicio"
Llena formulario: nombre, equipo, ambiente
        │
        ▼
Backstage llama a GitHub Actions
        ├── ✅ Crea repositorio
        ├── ✅ Configura pipeline CI/CD
        └── ✅ Registra servicio en el catálogo
        │
        ▼
Dev hace su primer push
        │
        ▼
GitHub Actions
        ├── Tests automáticos
        ├── Build imagen Docker
        ├── Push a Amazon ECR
        └── Actualiza manifiestos en repo GitOps
        │
        ▼
Argo CD detecta el cambio
        │
        ▼
Deploy automático a EKS 🎉

Tiempo total: menos de 5 minutos
Sin tickets. Sin esperar al equipo de plataforma.
\`\`\`

---

## 🔑 Conceptos clave

### Golden Path
El camino pavimentado que el equipo de plataforma construyó para que los desarrolladores lleguen a producción de forma segura y eficiente. No es el único camino — pueden salirse si quieren — pero es el recomendado, documentado y que funciona.

### IRSA (IAM Roles for Service Accounts)
Permite que los pods en EKS asuman roles de IAM sin credenciales hardcodeadas. Cada servicio tiene exactamente los permisos que necesita — ni más, ni menos.

\`\`\`yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::<cuenta>:role/mi-servicio-role
\`\`\`

### GitOps con Argo CD
Todo lo que va a producción pasa por Git. Si no está en Git, no existe en producción. Argo CD sincroniza el estado del cluster automáticamente con cada push.

---

## 📊 DORA Metrics — antes vs después del IDP

| Métrica | Sin IDP | Con IDP |
|---|---|---|
| Deployment Frequency | 1x / semana | Varias veces al día |
| Lead Time for Changes | Días | Horas |
| Change Failure Rate | Alto | Bajo (guardrails en golden path) |
| Time to Restore | Horas | Minutos (rollback = un push) |

---

## ✅ ¿Estás lista/listo para empezar?

- [ ] ¿Tienes un equipo de plataforma — aunque sea de dos personas?
- [ ] ¿Tienes EKS corriendo (o Kind para local)?
- [ ] ¿Usas GitHub o GitLab?
- [ ] ¿Tienes al menos un pain point claro que el IDP podría resolver?

Si marcaste tres de cuatro: **empieza la semana que viene**. Instala Backstage, crea un solo template, mídelo, itera.

> No busques la perfección. Busca el primer *"wow"* de un desarrollador.

---

## 📚 Recursos

- [Documentación oficial de Backstage](https://backstage.io/docs)
- [AWS Blog — Backstage en EKS](https://aws.amazon.com/blogs/containers/)
- [Argo CD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [CNCF Platform Engineering Slack](https://cloud-native.slack.com/archives/C020RHD43BP)
- [DORA Metrics](https://dora.dev/guides/dora-metrics-four-keys/)
- [Humanitec State of Platform Engineering](https://humanitec.com/whitepapers/state-of-platform-engineering-report-volume-2)

---

## 👩‍💻 Autora

**Joice Chávez** · Senior DevOps Engineer @ NTT Data · AWS Community Builder

[![LinkedIn](https://img.shields.io/badge/LinkedIn-joicechavez-blue)](https://www.linkedin.com/in/joicechavez/)
[![GitHub](https://img.shields.io/badge/GitHub-WeirdSplash-black)](https://github.com/WeirdSplash)

Si esta charla o repo te ayudó, considera dar ⭐ al repo y compartirlo con tu equipo 🖤

---

*Demo creado para AWS Community Day Perú 2026*
