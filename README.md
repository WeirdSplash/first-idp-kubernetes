# Mi primer Internal Developer Platform en Kubernetes

> **Charla:** Construyendo tu primer Internal Developer Platform en Kubernetes
> **Evento:** KCD Peru 2026
> **Fecha:** 18 de julio de 2026
> **Speaker:** Joice Chávez 

Este repositorio acompaña la charla y contiene todo lo necesario para construir un IDP mínimo en tu laptop usando Kubernetes (Kind), Backstage, ArgoCD y GitHub Actions.

## 🎯 ¿Qué vas a construir?

Un flujo end-to-end donde:

1. Un developer entra a **Backstage**
2. Crea un componente nuevo desde un **software template**
3. Se genera automáticamente un **repo en GitHub** con código boilerplate + manifests Kubernetes
4. **GitHub Actions** construye la imagen Docker
5. **ArgoCD** despliega el servicio en tu clúster Kubernetes
6. El servicio queda corriendo y accesible

Todo esto sin que el developer tenga que escribir una línea de YAML.

## 🧩 Platform vs Portal — aclaración importante

En esta charla y este repo usamos las siglas **IDP** para referirnos a **Internal Developer Platform** — el sistema completo (Kubernetes + GitOps + CI/CD + Templates + Portal).

Un **Internal Developer Portal** (como Backstage) es solo la interfaz visual del developer. Es un componente de la plataforma, no toda la plataforma.

> **Analogía:** la plataforma es el aeropuerto entero. El portal es la terminal de pasajeros.

## 📐 Arquitectura

```
┌─────────────────────────────────────────────┐
│  Internal Developer Platform (IDP)          │
│                                             │
│  ┌──────────────┐    ┌──────────────┐       │
│  │  Backstage   │───▶│    GitHub    │       │
│  │  (Portal)    │    │    Actions   │       │
│  └──────────────┘    └──────┬───────┘       │
│         ▲                    │              │
│         │                    ▼              │
│         │            ┌──────────────┐       │
│         │            │    ArgoCD    │       │
│         │            │   (GitOps)   │       │
│         │            └──────┬───────┘       │
│         │                    │              │
│         │                    ▼              │
│         │            ┌──────────────┐       │
│         └────────────│  Kubernetes  │       │
│                      │    (Kind)    │       │
│                      └──────────────┘       │
└─────────────────────────────────────────────┘
```

## 📋 Requisitos previos

Antes de empezar, asegúrate de tener instalado:

- [Docker](https://docs.docker.com/get-docker/) 20+
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) 0.20+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) 1.28+
- [Node.js](https://nodejs.org/) 20+
- [Yarn](https://yarnpkg.com/) classic (1.x)
- Cuenta de GitHub con permisos para crear repos

**Recursos mínimos recomendados:** 8 GB de RAM libre, 20 GB de disco.

## 🚀 Quick Start

### 1. Clonar el repo

```bash
git clone https://github.com/TU_USUARIO/first-idp-kubernetes.git
cd first-idp-kubernetes
```

### 2. Crear el clúster Kind

```bash
kind create cluster --name idp-demo
```

### 3. Instalar ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Acceso a la UI de ArgoCD:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Abre https://localhost:8080

### 4. Levantar Backstage local

Ver instrucciones detalladas en [backstage/README.md](backstage/README.md)

## 🧩 ¿Qué hace cada componente?

| Componente | Rol en el IDP |
|-----------|---------------|
| **Kind** | Clúster Kubernetes local para pruebas |
| **Backstage** | Portal del developer (la UI del IDP) |
| **Software Templates** | Definen los "golden paths" — patrones repetibles |
| **GitHub** | Fuente de verdad del código y los manifests |
| **GitHub Actions** | CI: build, test, push de imagen Docker |
| **ArgoCD** | CD: sincroniza el estado deseado (Git) con el clúster |

## 🎓 Concepto clave

> **Un IDP no elimina la complejidad. La encapsula para que los equipos puedan avanzar más rápido.**

Este repo demuestra las capas mínimas necesarias para empezar. En producción vas a necesitar más (observabilidad, seguridad, secrets management, políticas), pero **la mejor forma de aprender es empezando pequeño**.

## 📚 Recursos para profundizar

- [Backstage.io](https://backstage.io) — documentación oficial
- [Argo CD Docs](https://argo-cd.readthedocs.io/)
- [Kind Docs](https://kind.sigs.k8s.io/)
- [Platform Engineering Community](https://platformengineering.org/)
- [Internal Developer Platform Guide](https://internaldeveloperplatform.org/)

## 🤝 Contribuciones

Este repo nace de una charla en KCD Peru 2026. Si encuentras un bug, tienes una mejora, o quieres agregar un template, pull requests son bienvenidos.

## 📄 Licencia

MIT. Usa este código libremente para aprender, enseñar, o construir tu propio IDP.

## 🙋‍♀️ Sobre la autora

Joice Chávez es Senior DevOps Engineer, AWS Community Builder, y speaker en la comunidad LATAM de cloud. Actualmente construye una comunidad de Cloud y DevOps en Cusco, Perú, para llevar el conocimiento tech a la región andina.

- LinkedIn: [agregar tu link]
- GitHub: [agregar tu link]

Si esta charla o repo te ayudó, considera dar ⭐ al repo y compartirlo con tu equipo.
