#!/bin/bash

# EcoTrack Web Deployment Script for Google Cloud Run
# This script deploys the Django application to Google Cloud Run

set -e

echo "🚀 EcoTrack Web - Deployment to Google Cloud Run"
echo "=================================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed."
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Get project configuration
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No GCP project is set."
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "📦 Project ID: $PROJECT_ID"
echo ""

# Configuration
SERVICE_NAME="ecotrack-web"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

# Generate SECRET_KEY if not exists
if [ ! -f .env ]; then
    echo "🔑 Generating SECRET_KEY..."
    SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    cat > .env << EOF
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=.run.app
EOF
    echo "✅ .env file created"
fi

# Step 1: Enable required APIs
echo "🔧 Enabling required Google Cloud APIs..."
gcloud services enable run.googleapis.com \
    cloudbuild.googleapis.com \
    containerregistry.googleapis.com \
    secretmanager.googleapis.com

echo ""
echo "🔨 Building Docker image for linux/amd64..."
docker build --platform linux/amd64 -t $IMAGE_NAME:latest .

echo ""
echo "📤 Pushing image to Google Container Registry..."
docker push $IMAGE_NAME:latest

echo ""
echo "🔐 Setting up Firebase credentials as secret..."
# Create secret for Firebase credentials
if gcloud secrets describe firebase-credentials &>/dev/null; then
    echo "Secret already exists, updating..."
    gcloud secrets versions add firebase-credentials --data-file=firebase-service-account.json
else
    echo "Creating new secret..."
    gcloud secrets create firebase-credentials --data-file=firebase-service-account.json
fi

# Get SECRET_KEY from .env
SECRET_KEY=$(grep SECRET_KEY .env | cut -d '=' -f2)

echo ""
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME:latest \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --set-env-vars "DEBUG=False,ALLOWED_HOSTS=.run.app,GOOGLE_APPLICATION_CREDENTIALS=/secrets/firebase/firebase-service-account.json,PYTHONPATH=/app,USE_CLOUD_SQL=True" \
    --set-secrets "/secrets/firebase/firebase-service-account.json=firebase-credentials:latest,/secrets/django/secret-key=django-secret-key:latest" \
    --add-cloudsql-instances "ecotrack-app-23a64:us-central1:ecotrack-db" \
    --memory 512Mi \
    --cpu 1 \
    --max-instances 10 \
    --min-instances 0 \
    --timeout 300

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')
echo ""
echo "=================================================="
echo "🎉 Your application is live at:"
echo "   $SERVICE_URL"
echo "=================================================="
echo ""
echo "📝 Next steps:"
echo "   1. Update ALLOWED_HOSTS in .env with your domain"
echo "   2. Configure custom domain (optional)"
echo "   3. Set up Cloud SQL for production database (optional)"
echo ""
