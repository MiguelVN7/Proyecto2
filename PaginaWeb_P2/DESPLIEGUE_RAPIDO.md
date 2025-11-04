# 🚀 Despliegue Rápido - EcoTrack Web

## Pasos para desplegar en Google Cloud Run

### 1️⃣ Instalar dependencias (solo primera vez)

```bash
# Instalar Google Cloud SDK
brew install --cask google-cloud-sdk

# Instalar Docker Desktop
brew install --cask docker
```

### 2️⃣ Configurar Google Cloud (solo primera vez)

```bash
# Iniciar sesión en Google Cloud
gcloud auth login

# Crear proyecto (o usar uno existente)
gcloud projects create ecotrack-prod --name="EcoTrack Production"

# Configurar proyecto
gcloud config set project ecotrack-prod
```

**⚠️ IMPORTANTE**: Activa la facturación en https://console.cloud.google.com/billing
(Tienes $300 USD gratis por 90 días)

### 3️⃣ Desplegar

```bash
cd PaginaWeb_P2
./deploy.sh
```

¡Eso es todo! El script hace todo automáticamente:
- ✅ Construye la imagen Docker
- ✅ Sube a Google Container Registry
- ✅ Configura Firebase
- ✅ Despliega en Cloud Run
- ✅ Te da la URL de tu aplicación

### 4️⃣ Acceder a tu aplicación

Al terminar verás algo como:
```
🎉 Your application is live at:
   https://ecotrack-web-xxx-uc.a.run.app
```

### 5️⃣ Crear usuario admin

1. Ve a https://console.cloud.google.com/run
2. Click en tu servicio `ecotrack-web`
3. Click en "CLOUD SHELL"
4. Ejecuta:
   ```bash
   python manage.py createsuperuser
   ```

---

## 🔄 Actualizar después de cambios

```bash
cd PaginaWeb_P2
./deploy.sh
```

---

## 💰 Costos

- **Primeros 2 millones de requests**: GRATIS
- **Estimado para tráfico bajo**: $1-5 USD/mes
- Solo pagas por lo que usas

---

## 📖 Documentación completa

Lee [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) para más detalles.

---

## ❓ ¿Problemas?

```bash
# Ver logs
gcloud run services logs read ecotrack-web --region us-central1 --limit 50

# Ver estado del servicio
gcloud run services describe ecotrack-web --region us-central1
```
