// Se crea un modelo para los reportes

class Reporte {
  final String id;
  final String fotoUrl;
  final String ubicacion;
  final String clasificacion;
  final String estado;
  final String prioridad;
  final String tipoResiduo;
  final double lat;
  final double lng;

  Reporte({
    required this.id,
    required this.fotoUrl,
    required this.ubicacion,
    required this.clasificacion,
    required this.estado,
    required this.prioridad,
    required this.tipoResiduo,
    required this.lat,
    required this.lng,
  });
}
