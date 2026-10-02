#!/bin/bash
# ──────────────────────────────────────────────────────────────────
# populate-idp-repo.sh
# Puebla el repo WeirdSplash/first-idp-kubernetes con los archivos
# del demo de AWS Community Day Perú 2026
#
# Uso:
#   1. Clona tu repo: git clone https://github.com/WeirdSplash/first-idp-kubernetes
#   2. cd first-idp-kubernetes
#   3. bash populate-idp-repo.sh
#   4. git push
# ──────────────────────────────────────────────────────────────────

set -e
echo "🚀 Poblando first-idp-kubernetes..."

# ── app-config.yaml ───────────────────────────────────────────────
cat > backstage/app-config.yaml << 'EOF'
app:
  title: Internal Developer Portal — Demo
  baseUrl: http://localhost:3000

organization:
  name: Mi Empresa

backend:
  baseUrl: http://localhost:7007
  listen:
    port: 7007
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, Template]
  locations:
    - type: file
      target: ../catalog/all-components.yaml
    # En producción apuntar a tu GitHub org:
    # - type: github-discovery
    #   target: https://github.com/tu-org

integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}

scaffolder:
  defaultAuthor:
    name: Platform Team
    email: platform@miempresa.com
  defaultCommitMessage: "feat: scaffold from Backstage IDP"

auth:
  environment: development
  providers: {}

techdocs:
  builder: local
  generator:
    runIn: local
  publisher:
    type: local
EOF

# ── docker-compose.yml ────────────────────────────────────────────
cat > backstage/docker-compose.yml << 'EOF'
version: '3.8'

# Stack LOCAL — para probar Backstage sin necesitar EKS/Kind
# Para producción en Kubernetes, ver /backstage/k8s-deployment.yaml

services:
  backstage:
    image: backstage/backstage:latest
    ports:
      - '3000:7007'
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - APP_CONFIG_app_baseUrl=http://localhost:3000
      - APP_CONFIG_backend_baseUrl=http://localhost:7007
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=backstage
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-backstage}
    volumes:
      - ./app-config.yaml:/app/app-config.yaml:ro
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: backstage
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-backstage}
      POSTGRES_DB: backstage
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U backstage']
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

# ── backstage/k8s-deployment.yaml ────────────────────────────────
cat > backstage/k8s-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
  namespace: backstage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
    spec:
      serviceAccountName: backstage
      containers:
        - name: backstage
          image: backstage/backstage:latest
          ports:
            - containerPort: 7007
          env:
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: backstage-secrets
                  key: github-token
            - name: POSTGRES_HOST
              value: backstage-postgres.backstage.svc.cluster.local
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: backstage-secrets
                  key: postgres-user
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: backstage-secrets
                  key: postgres-password
          volumeMounts:
            - name: app-config
              mountPath: /app/app-config.production.yaml
              subPath: app-config.yaml
          readinessProbe:
            httpGet:
              path: /healthcheck
              port: 7007
            initialDelaySeconds: 30
            periodSeconds: 10
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1Gi
      volumes:
        - name: app-config
          configMap:
            name: backstage-config
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage
  namespace: backstage
  annotations:
    # IRSA — en EKS, el pod asume este role sin access keys
    eks.amazonaws.com/role-arn: arn:aws:iam::<cuenta>:role/backstage-eks-role
---
apiVersion: v1
kind: Service
metadata:
  name: backstage
  namespace: backstage
spec:
  selector:
    app: backstage
  ports:
    - port: 80
      targetPort: 7007
EOF

# ── backstage/.env.example ────────────────────────────────────────
cat > backstage/.env.example << 'EOF'
# Copiar a .env y completar con valores reales — NUNCA commitear .env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
POSTGRES_PASSWORD=backstage_local_pass
EOF

# ── Catálogo ──────────────────────────────────────────────────────
mkdir -p catalog

cat > catalog/all-components.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: all-components
  description: Registro central de todos los componentes
spec:
  targets:
    - ./servicio-pagos.yaml
    - ./servicio-usuarios.yaml
    - ../backstage/templates/nuevo-microservicio/template.yaml
EOF

cat > catalog/servicio-pagos.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: servicio-pagos
  description: Microservicio de procesamiento de pagos
  annotations:
    github.com/project-slug: WeirdSplash/servicio-pagos
    backstage.io/techdocs-ref: dir:.
  tags: [fastapi, python, pagos, kubernetes]
  links:
    - url: https://github.com/WeirdSplash/servicio-pagos
      title: Repositorio GitHub
    - url: https://argocd.miempresa.com/applications/servicio-pagos
      title: Argo CD
spec:
  type: service
  lifecycle: production
  owner: equipo-pagos
  system: plataforma-core
EOF

cat > catalog/servicio-usuarios.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: servicio-usuarios
  description: Microservicio de gestión de usuarios y autenticación
  annotations:
    github.com/project-slug: WeirdSplash/servicio-usuarios
    backstage.io/techdocs-ref: dir:.
  tags: [fastapi, python, usuarios, kubernetes]
spec:
  type: service
  lifecycle: production
  owner: equipo-plataforma
  system: plataforma-core
EOF

# ── Software Template ─────────────────────────────────────────────
mkdir -p backstage/templates/nuevo-microservicio/skeleton/.github/workflows

cat > backstage/templates/nuevo-microservicio/template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: nuevo-microservicio-fastapi
  title: Nuevo Microservicio FastAPI
  description: |
    Golden Path para crear un microservicio FastAPI listo para producción.
    Crea el repo, configura CI/CD con GitHub Actions, y registra el
    servicio en el catálogo automáticamente.
  tags: [fastapi, python, kubernetes, golden-path]
spec:
  owner: equipo-plataforma
  type: service
  parameters:
    - title: Información del servicio
      required: [nombre, descripcion, owner]
      properties:
        nombre:
          title: Nombre del servicio
          type: string
          description: En kebab-case (ej. servicio-notificaciones)
          pattern: '^[a-z][a-z0-9-]*$'
        descripcion:
          title: Descripción
          type: string
        owner:
          title: Equipo dueño
          type: string
          ui:field: OwnerPicker
          ui:options:
            allowedKinds: [Group]
        puerto:
          title: Puerto de la aplicación
          type: integer
          default: 8000
    - title: Repositorio GitHub
      required: [repoUrl]
      properties:
        repoUrl:
          title: Ubicación del repositorio
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts: [github.com]
  steps:
    - id: fetch-template
      name: Generar código base
      action: fetch:template
      input:
        url: ./skeleton
        values:
          nombre: ${{ parameters.nombre }}
          descripcion: ${{ parameters.descripcion }}
          owner: ${{ parameters.owner }}
          puerto: ${{ parameters.puerto }}
    - id: crear-repo
      name: Crear repositorio en GitHub
      action: publish:github
      input:
        allowedHosts: [github.com]
        description: ${{ parameters.descripcion }}
        repoUrl: ${{ parameters.repoUrl }}
        defaultBranch: main
        topics: [fastapi, python, kubernetes, microservicio]
    - id: registrar-catalogo
      name: Registrar en el catálogo
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps['crear-repo'].output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml
  output:
    links:
      - title: Repositorio GitHub
        url: ${{ steps['crear-repo'].output.remoteUrl }}
      - title: Ver en el catálogo
        icon: catalog
        entityRef: ${{ steps['registrar-catalogo'].output.entityRef }}
EOF

cat > backstage/templates/nuevo-microservicio/skeleton/catalog-info.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: ${{ values.nombre }}
  description: ${{ values.descripcion }}
  annotations:
    github.com/project-slug: ${{ values.repoUrl | parseRepoUrl | pick('owner') }}/${{ values.nombre }}
    backstage.io/techdocs-ref: dir:.
  tags: [fastapi, python, kubernetes]
spec:
  type: service
  lifecycle: experimental
  owner: ${{ values.owner }}
  system: plataforma-core
EOF

cat > backstage/templates/nuevo-microservicio/skeleton/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(
    title="${{ values.nombre }}",
    description="${{ values.descripcion }}",
    version="0.1.0",
)

@app.get("/health")
async def health_check():
    """Health check para Kubernetes liveness/readiness probe."""
    return JSONResponse(content={"status": "ok", "service": "${{ values.nombre }}"})

@app.get("/")
async def root():
    return {"message": "Hola desde ${{ values.nombre }} 🚀"}
EOF

cat > backstage/templates/nuevo-microservicio/skeleton/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE ${{ values.puerto }}

# Usuario no-root (best practice en Kubernetes)
RUN adduser --disabled-password --gecos '' appuser
USER appuser

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "${{ values.puerto }}"]
EOF

cat > backstage/templates/nuevo-microservicio/skeleton/requirements.txt << 'EOF'
fastapi==0.111.0
uvicorn[standard]==0.30.1
EOF

cat > backstage/templates/nuevo-microservicio/skeleton/.github/workflows/ci.yaml << 'EOF'
name: CI — Build & Push

# ──────────────────────────────────────────────────────────────────
# Golden Path — generado por Backstage IDP
# Flujo: Test → Build imagen → Push a registry → Actualizar manifiestos
# ArgoCD detecta el cambio y deploya a Kubernetes automáticamente.
# ──────────────────────────────────────────────────────────────────

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  IMAGE_NAME: ${{ values.nombre }}

jobs:
  test:
    name: Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      - run: pip install -r requirements.txt pytest httpx
      - run: pytest tests/ -v --tb=short

  build-and-push:
    name: Build & Push imagen
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      # Opción A — AWS ECR (producción en EKS)
      - name: Configurar credenciales AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-ecr-push
          aws-region: us-east-1

      - name: Login a Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build y Push a ECR
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ steps.login-ecr.outputs.registry }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ steps.login-ecr.outputs.registry }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  update-manifests:
    name: Actualizar manifiestos (GitOps)
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
        with:
          repository: WeirdSplash/k8s-manifests
          token: ${{ secrets.GITHUB_TOKEN }}
          path: manifests
      - name: Actualizar tag en manifiestos
        run: |
          cd manifests
          sed -i "s|image: .*${{ env.IMAGE_NAME }}:.*|image: ${{ env.IMAGE_NAME }}:${{ github.sha }}|g" \
            apps/${{ env.IMAGE_NAME }}/deployment.yaml
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .
          git commit -m "chore: update ${{ env.IMAGE_NAME }} to ${{ github.sha }}"
          git push
          # ArgoCD detecta este push y deploya automáticamente 🚀
EOF

# ── ArgoCD ────────────────────────────────────────────────────────
cat > argocd/backstage-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backstage
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    # GitOps puro — si no está en Git, no existe en el clúster
    repoURL: https://github.com/WeirdSplash/first-idp-kubernetes
    targetRevision: main
    path: backstage
  destination:
    server: https://kubernetes.default.svc
    namespace: backstage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

cat > argocd/ejemplo-microservicio-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mi-microservicio
  namespace: argocd
spec:
  project: default
  source:
    # Este repo es generado automáticamente por el Software Template de Backstage
    repoURL: https://github.com/WeirdSplash/mi-microservicio
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: mi-microservicio
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# ── GitHub Actions del repo principal ─────────────────────────────
mkdir -p .github/workflows

cat > .github/workflows/validate.yaml << 'EOF'
name: Validar manifiestos

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validar YAML del catálogo de Backstage
        run: |
          pip install pyyaml
          python -c "
          import yaml, glob, sys
          errors = []
          for f in glob.glob('catalog/**/*.yaml', recursive=True):
              try:
                  yaml.safe_load(open(f))
                  print(f'✅ {f}')
              except Exception as e:
                  errors.append(f'❌ {f}: {e}')
          if errors:
              print('\n'.join(errors))
              sys.exit(1)
          "

      - name: Validar YAML de ArgoCD
        run: |
          python -c "
          import yaml, glob, sys
          for f in glob.glob('argocd/**/*.yaml', recursive=True):
              try:
                  yaml.safe_load(open(f))
                  print(f'✅ {f}')
              except Exception as e:
                  print(f'❌ {f}: {e}')
                  sys.exit(1)
          "
EOF

# ── Commit y push ─────────────────────────────────────────────────
echo ""
echo "📁 Archivos creados:"
git status --short

echo ""
echo "¿Hacemos commit y push? (y/n)"
read -r respuesta

if [[ "$respuesta" == "y" || "$respuesta" == "Y" ]]; then
  git add .
  git commit -m "feat: agregar archivos del demo AWS Community Day Perú 2026

- Backstage: app-config.yaml, docker-compose, k8s deployment
- Catálogo: ejemplos de catalog-info.yaml
- Software Template: golden path nuevo-microservicio con FastAPI
- GitHub Actions: CI pipeline completo (build → ECR → GitOps)
- Argo CD: apps para Backstage y microservicios
- GitHub Actions: validación de YAMLs del repo"
  git push
  echo ""
  echo "✅ ¡Listo! Repo actualizado en https://github.com/WeirdSplash/first-idp-kubernetes"
else
  echo "Ok, puedes hacer el commit manualmente cuando quieras 🖤"
fi
