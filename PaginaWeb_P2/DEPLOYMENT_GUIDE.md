# 🚀 Guía de Despliegue - EcoTrack Web (Google Cloud Run)

Esta guía te ayudará a desplegar la aplicación web de EcoTrack en Google Cloud Run.

## 📋 Pre-requisitos

1. **Cuenta de Google Cloud Platform**
   - Crear una cuenta en https://console.cloud.google.com
   - Activar facturación (hay créditos gratis de $300 USD por 90 días)

2. **Instalar Google Cloud SDK**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk

   # O descargar desde:
   # https://cloud.google.com/sdk/docs/install
   ```

3. **Docker Desktop**
   ```bash
   # macOS
   brew install --cask docker

   # O descargar desde:
   # https://www.docker.com/products/docker-desktop
   ```

4. **Firebase Service Account**
   - Ya tienes el archivo `firebase-service-account.json` en tu proyecto

---

## 🔧 Configuración Inicial

### 1. Configurar Google Cloud

```bash
# Iniciar sesión
gcloud auth login

# Crear un nuevo proyecto (o usar uno existente)
gcloud projects create ecotrack-prod --name="EcoTrack Production"

# Configurar el proyecto
gcloud config set project ecotrack-prod

# Habilitar facturación (requerido para Cloud Run)
# Visita: https://console.cloud.google.com/billing
```

### 2. Configurar Variables de Entorno

Crea un archivo `.env` en el directorio del proyecto:

```bash
cd PaginaWeb_P2
cp .env.example .env
```

Edita `.env` con tus valores:

```env
SECRET_KEY=tu-secret-key-super-segura-aqui
DEBUG=False
ALLOWED_HOSTS=.run.app
```

Para generar un SECRET_KEY seguro:
```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

---

## 🚀 Despliegue

### Opción 1: Despliegue Automático (Recomendado)

Ejecuta el script de despliegue:

```bash
cd PaginaWeb_P2
./deploy.sh
```

Este script:
- ✅ Verifica que tengas gcloud instalado
- ✅ Habilita las APIs necesarias
- ✅ Construye la imagen Docker
- ✅ Sube la imagen a Google Container Registry
- ✅ Configura los secretos de Firebase
- ✅ Despliega en Cloud Run
- ✅ Te muestra la URL de tu aplicación

---

### Opción 2: Despliegue Manual

#### Paso 1: Habilitar APIs

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

#### Paso 2: Construir la imagen Docker

```bash
# Reemplaza PROJECT_ID con tu ID de proyecto
PROJECT_ID=$(gcloud config get-value project)
docker build -t gcr.io/$PROJECT_ID/ecotrack-web:latest .
```

#### Paso 3: Subir la imagen

```bash
docker push gcr.io/$PROJECT_ID/ecotrack-web:latest
```

#### Paso 4: Crear secreto para Firebase

```bash
gcloud secrets create firebase-credentials \
    --data-file=firebase-service-account.json
```

#### Paso 5: Desplegar en Cloud Run

```bash
# Obtener SECRET_KEY
SECRET_KEY=$(grep SECRET_KEY .env | cut -d '=' -f2)

gcloud run deploy ecotrack-web \
    --image gcr.io/$PROJECT_ID/ecotrack-web:latest \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --set-env-vars "DEBUG=False,SECRET_KEY=$SECRET_KEY,ALLOWED_HOSTS=.run.app" \
    --set-secrets "GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-service-account.json:firebase-credentials:latest" \
    --memory 512Mi \
    --cpu 1 \
    --max-instances 10 \
    --min-instances 0
```

---

## 🌐 Post-Despliegue

### 1. Obtener la URL de tu aplicación

```bash
gcloud run services describe ecotrack-web \
    --region us-central1 \
    --format 'value(status.url)'
```

### 2. Actualizar ALLOWED_HOSTS

Una vez que tengas la URL (ej: `https://ecotrack-web-xxx-uc.a.run.app`), actualiza tu `.env`:

```env
ALLOWED_HOSTS=ecotrack-web-xxx-uc.a.run.app,.run.app
```

Y redespliega:

```bash
./deploy.sh
```

### 3. Configurar Dominio Personalizado (Opcional)

```bash
# Mapear un dominio personalizado
gcloud run domain-mappings create \
    --service ecotrack-web \
    --domain tudominio.com \
    --region us-central1
```

### 4. Crear Usuarios Admin

Conéctate al contenedor para crear un superusuario:

```bash
# Obtener el nombre del servicio
gcloud run services list

# Ejecutar comando en Cloud Run (usando Cloud Console o Cloud Shell)
# Ve a: https://console.cloud.google.com/run
# Click en tu servicio > Cloud Shell > Ejecutar:
python manage.py createsuperuser
```

---

## 💰 Estimación de Costos

Cloud Run cobra por uso:
- **Primeros 2 millones de requests/mes**: GRATIS
- **CPU**: $0.00002400 por vCPU-segundo
- **Memoria**: $0.00000250 por GiB-segundo
- **Requests**: $0.40 por millón

**Estimación para 10,000 visitas/mes**:
- Costo aproximado: **$1-5 USD/mes**

---

## 🔍 Monitoreo

### Ver logs

```bash
gcloud run services logs read ecotrack-web \
    --region us-central1 \
    --limit 50
```

### Ver métricas

Visita: https://console.cloud.google.com/run

---

## 🐛 Troubleshooting

### Error: "Application failed to start"

```bash
# Ver logs detallados
gcloud run services logs read ecotrack-web --region us-central1 --limit 100
```

### Error: "SECRET_KEY not set"

Verifica que el secreto se pasó correctamente:
```bash
gcloud run services describe ecotrack-web --region us-central1
```

### Error con Firebase

Verifica que el secreto existe:
```bash
gcloud secrets list
gcloud secrets versions access latest --secret firebase-credentials
```

---

## 📚 Recursos Adicionales

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

## 🔄 Actualizar la Aplicación

Para actualizar después de hacer cambios:

```bash
cd PaginaWeb_P2
./deploy.sh
```

---

## 🛡️ Seguridad

- ✅ SECRET_KEY está protegido en variables de entorno
- ✅ Firebase credentials se manejan como secretos
- ✅ DEBUG=False en producción
- ✅ HTTPS habilitado automáticamente
- ✅ Headers de seguridad configurados
- ✅ WhiteNoise para servir archivos estáticos de forma segura

---

## ✅ Checklist de Despliegue

- [ ] Cuenta de GCP creada y facturación activada
- [ ] Google Cloud SDK instalado y configurado
- [ ] Docker Desktop instalado
- [ ] Proyecto GCP creado
- [ ] Archivo .env configurado con SECRET_KEY
- [ ] Script deploy.sh ejecutado exitosamente
- [ ] URL de la aplicación obtenida
- [ ] ALLOWED_HOSTS actualizado con la URL
- [ ] Superusuario creado
- [ ] Aplicación probada en producción

---

¡Listo! Tu aplicación Django con Firestore está ahora en producción en Google Cloud Run. 🎉
