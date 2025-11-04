"""
Firestore Service for Django Integration

This service provides a bridge between Django and Firebase Firestore,
allowing the Django web application to read and write reports from/to
the same Firestore database used by the mobile app and backend API.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from django.conf import settings
import os


class FirestoreService:
    """Service class to handle Firestore operations for Django"""

    _instance = None
    _initialized = False

    def __new__(cls):
        """Singleton pattern to ensure only one Firebase connection"""
        if cls._instance is None:
            cls._instance = super(FirestoreService, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        """Initialize Firebase Admin SDK"""
        if not FirestoreService._initialized:
            try:
                # Get credentials path from settings or use default
                cred_path = getattr(settings, 'FIREBASE_CREDENTIALS',
                                   os.path.join(settings.BASE_DIR, 'firebase-service-account.json'))

                # Initialize Firebase Admin
                if not firebase_admin._apps:
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    print('🔥 Firebase Admin SDK initialized successfully')

                self.db = firestore.client()
                FirestoreService._initialized = True
                print('✅ Firestore Service ready')

            except Exception as e:
                print(f'❌ Error initializing Firestore Service: {e}')
                raise

    # ==================== READ OPERATIONS ====================

    def get_all_reports(self, limit=None, order_by='created_at', descending=True):
        """
        Get all reports from Firestore

        Args:
            limit: Maximum number of reports to retrieve
            order_by: Field to order by (default: created_at)
            descending: Order descending (default: True)

        Returns:
            List of report dictionaries
        """
        try:
            print(f'📋 Fetching all reports from Firestore (limit: {limit})')

            # Build query
            query = self.db.collection('reports').order_by(
                order_by,
                direction=firestore.Query.DESCENDING if descending else firestore.Query.ASCENDING
            )

            if limit:
                query = query.limit(limit)

            # Execute query
            docs = query.stream()

            # Convert to Django-compatible format
            reports = [self._firestore_to_django(doc) for doc in docs]

            print(f'✅ Retrieved {len(reports)} reports from Firestore')
            return reports

        except Exception as e:
            print(f'❌ Error fetching reports from Firestore: {e}')
            return []

    def get_report_by_id(self, report_id):
        """
        Get a single report by ID

        Args:
            report_id: The report ID

        Returns:
            Report dictionary or None
        """
        try:
            print(f'📖 Fetching report {report_id} from Firestore')

            doc = self.db.collection('reports').document(report_id).get()

            if doc.exists:
                report = self._firestore_to_django(doc)
                print(f'✅ Report {report_id} retrieved')
                return report
            else:
                print(f'⚠️ Report {report_id} not found in Firestore')
                return None

        except Exception as e:
            print(f'❌ Error fetching report {report_id}: {e}')
            return None

    def get_reports_by_status(self, status, limit=None):
        """
        Get reports filtered by status

        Args:
            status: Status to filter by (e.g., 'received', 'in_progress', 'completed')
            limit: Maximum number of reports

        Returns:
            List of report dictionaries
        """
        try:
            print(f'📋 Fetching reports with status: {status}')

            query = self.db.collection('reports').where('estado', '==', status)
            query = query.order_by('created_at', direction=firestore.Query.DESCENDING)

            if limit:
                query = query.limit(limit)

            docs = query.stream()
            reports = [self._firestore_to_django(doc) for doc in docs]

            print(f'✅ Retrieved {len(reports)} reports with status {status}')
            return reports

        except Exception as e:
            print(f'❌ Error fetching reports by status: {e}')
            return []

    def get_reports_by_classification(self, clasificacion, limit=None):
        """
        Get reports filtered by classification (tipo_residuo)

        Args:
            clasificacion: Classification to filter by
            limit: Maximum number of reports

        Returns:
            List of report dictionaries
        """
        try:
            query = self.db.collection('reports').where('clasificacion', '==', clasificacion)
            query = query.order_by('created_at', direction=firestore.Query.DESCENDING)

            if limit:
                query = query.limit(limit)

            docs = query.stream()
            reports = [self._firestore_to_django(doc) for doc in docs]

            return reports

        except Exception as e:
            print(f'❌ Error fetching reports by classification: {e}')
            return []

    def get_reports_by_priority(self, prioridad, limit=None):
        """
        Get reports filtered by priority

        Args:
            prioridad: Priority to filter by
            limit: Maximum number of reports

        Returns:
            List of report dictionaries
        """
        try:
            query = self.db.collection('reports').where('prioridad', '==', prioridad)
            query = query.order_by('created_at', direction=firestore.Query.DESCENDING)

            if limit:
                query = query.limit(limit)

            docs = query.stream()
            reports = [self._firestore_to_django(doc) for doc in docs]

            return reports

        except Exception as e:
            print(f'❌ Error fetching reports by priority: {e}')
            return []

    # ==================== WRITE OPERATIONS ====================

    def update_report_status(self, report_id, new_status):
        """
        Update the status of a report

        Args:
            report_id: The report ID
            new_status: New status value

        Returns:
            Boolean indicating success
        """
        try:
            print(f'🔄 Updating report {report_id} status to: {new_status}')

            doc_ref = self.db.collection('reports').document(report_id)
            doc_ref.update({
                'estado': new_status,
                'updated_at': firestore.SERVER_TIMESTAMP
            })

            print(f'✅ Report {report_id} status updated to {new_status}')
            return True

        except Exception as e:
            print(f'❌ Error updating report status: {e}')
            return False

    def update_report(self, report_id, updates):
        """
        Update a report with custom fields

        Args:
            report_id: The report ID
            updates: Dictionary with fields to update

        Returns:
            Boolean indicating success
        """
        try:
            print(f'🔄 Updating report {report_id} with {len(updates)} fields')

            # Always add updated_at timestamp
            updates['updated_at'] = firestore.SERVER_TIMESTAMP

            doc_ref = self.db.collection('reports').document(report_id)
            doc_ref.update(updates)

            print(f'✅ Report {report_id} updated successfully')
            return True

        except Exception as e:
            print(f'❌ Error updating report: {e}')
            return False

    def assign_report_to_user(self, report_id, user_id, user_name):
        """
        Assign a report to a user (encargado)

        Args:
            report_id: The report ID
            user_id: The user ID to assign to
            user_name: The user's full name

        Returns:
            Boolean indicating success
        """
        try:
            updates = {
                'assigned_to': user_id,
                'assigned_to_name': user_name,
                'assigned_at': firestore.SERVER_TIMESTAMP,
                'estado': 'asignado'
            }

            return self.update_report(report_id, updates)

        except Exception as e:
            print(f'❌ Error assigning report: {e}')
            return False

    # ==================== STATISTICS ====================

    def get_stats(self):
        """
        Get statistics about reports

        Returns:
            Dictionary with statistics
        """
        try:
            print('📊 Calculating Firestore statistics...')

            # Get all reports
            all_reports = self.get_all_reports()

            # Calculate stats
            stats = {
                'total_reports': len(all_reports),
                'by_status': {},
                'by_classification': {},
                'by_priority': {},
            }

            # Count by status
            for report in all_reports:
                status = report.get('estado', 'unknown')
                stats['by_status'][status] = stats['by_status'].get(status, 0) + 1

            # Count by classification
            for report in all_reports:
                clasificacion = report.get('tipo_residuo', 'unknown')
                stats['by_classification'][clasificacion] = stats['by_classification'].get(clasificacion, 0) + 1

            # Count by priority
            for report in all_reports:
                prioridad = report.get('prioridad', 'unknown')
                stats['by_priority'][prioridad] = stats['by_priority'].get(prioridad, 0) + 1

            print(f'✅ Statistics calculated: {stats["total_reports"]} total reports')
            return stats

        except Exception as e:
            print(f'❌ Error calculating statistics: {e}')
            return {}

    # ==================== HELPER METHODS ====================

    def _firestore_to_django(self, doc):
        """
        Convert Firestore document to Django-compatible dictionary

        Args:
            doc: Firestore document snapshot

        Returns:
            Dictionary compatible with Django templates and views
        """
        data = doc.to_dict()

        # Extract location data
        location = data.get('location', {})
        latitud = location.get('latitude', 0)
        longitud = location.get('longitude', 0)

        # Extract timestamps
        created_at = data.get('created_at')
        if created_at and hasattr(created_at, 'timestamp'):
            fecha_reporte = datetime.fromtimestamp(created_at.timestamp())
        else:
            fecha_reporte = datetime.now()

        # Map Firestore fields to Django model fields
        return {
            'id': doc.id,
            'tipo_residuo': self._map_clasificacion_to_django(data.get('clasificacion', '')),
            'tipo_residuo_display': data.get('clasificacion', 'Desconocido'),
            'descripcion': data.get('descripcion', ''),
            'foto': None,  # Not used with Firestore
            'foto_url': data.get('foto_url', ''),
            'latitud': latitud,
            'longitud': longitud,
            'direccion': data.get('ubicacion', ''),
            'estado': self._map_estado_to_django(data.get('estado', 'received')),
            'estado_display': data.get('estado', 'Recibido'),
            'prioridad': self._map_prioridad_to_django(data.get('prioridad', 'Media')),
            'prioridad_display': data.get('prioridad', 'Media'),
            'assigned_to': data.get('assigned_to'),
            'assigned_to_name': data.get('assigned_to_name', ''),
            'fecha_reporte': fecha_reporte,
            'fecha_asignacion': self._parse_timestamp(data.get('assigned_at')),
            'reportado_por': data.get('user_id', 'Desconocido'),
            'version_app': data.get('device_info', ''),

            # AI Classification fields (additional info)
            'is_ai_classified': data.get('is_ai_classified', False),
            'ai_confidence': data.get('ai_confidence', 0),
            'ai_suggested_classification': data.get('ai_suggested_classification', ''),
            'ai_model_version': data.get('ai_model_version', ''),

            # Raw Firestore data (for debugging)
            '_firestore_data': data,
        }

    def _map_clasificacion_to_django(self, firestore_value):
        """
        Map Firestore classification to Django model choices

        Args:
            firestore_value: Classification from Firestore

        Returns:
            Django-compatible classification value
        """
        # Normalize to lowercase
        value = str(firestore_value).lower().strip()

        # Direct mapping
        mapping = {
            'orgánico': 'organico',
            'organico': 'organico',
            'plástico': 'plastico',
            'plastico': 'plastico',
            'vidrio': 'vidrio',
            'papel': 'papel',
            'papel/cartón': 'papel',
            'cartón': 'papel',
            'metal': 'metal',
            'electrónico': 'electronico',
            'electronico': 'electronico',
            'textil': 'textil',
            'peligroso': 'peligroso',
            'construcción': 'construccion',
            'construccion': 'construccion',
        }

        return mapping.get(value, 'otros')

    def _map_estado_to_django(self, firestore_estado):
        """
        Map Firestore status to Django model status choices

        Args:
            firestore_estado: Status from Firestore

        Returns:
            Django-compatible status value
        """
        mapping = {
            'received': 'pendiente',
            'recibido': 'pendiente',
            'pendiente': 'pendiente',
            'assigned': 'asignado',
            'asignado': 'asignado',
            'in_progress': 'en_proceso',
            'en_proceso': 'en_proceso',
            'completed': 'resuelto',
            'resuelto': 'resuelto',
            'finalizado': 'resuelto',
            'cancelado': 'cancelado',
            'cancelled': 'cancelado',
        }

        value = str(firestore_estado).lower().strip()
        return mapping.get(value, 'pendiente')

    def _map_prioridad_to_django(self, firestore_prioridad):
        """
        Map Firestore priority to Django model priority choices

        Args:
            firestore_prioridad: Priority from Firestore

        Returns:
            Django-compatible priority value
        """
        mapping = {
            'baja': 'baja',
            'low': 'baja',
            'media': 'media',
            'medium': 'media',
            'alta': 'alta',
            'high': 'alta',
            'urgente': 'urgente',
            'urgent': 'urgente',
        }

        value = str(firestore_prioridad).lower().strip()
        return mapping.get(value, 'media')

    def _parse_timestamp(self, timestamp):
        """
        Parse Firestore timestamp to Python datetime

        Args:
            timestamp: Firestore timestamp or None

        Returns:
            Python datetime or None
        """
        if timestamp and hasattr(timestamp, 'timestamp'):
            return datetime.fromtimestamp(timestamp.timestamp())
        return None


# Singleton instance
firestore_service = FirestoreService()
