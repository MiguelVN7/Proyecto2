#!/bin/bash
# Script para ejecutar create_users.py en Cloud Run

gcloud run jobs create ecotrack-setup \
    --image gcr.io/ecotrack-app-23a64/ecotrack-web:latest \
    --region us-central1 \
    --set-env-vars "USE_CLOUD_SQL=True,GOOGLE_APPLICATION_CREDENTIALS=/secrets/firebase/firebase-service-account.json" \
    --set-secrets "/secrets/firebase/firebase-service-account.json=firebase-credentials:latest,/secrets/django/secret-key=django-secret-key:latest" \
    --add-cloudsql-instances "ecotrack-app-23a64:us-central1:ecotrack-db" \
    --execute-now \
    --wait \
    --command python \
    --args create_users.py
