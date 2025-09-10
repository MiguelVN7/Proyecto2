// Se crea una pantalla para listar los reportes con filtros

import 'package:flutter/material.dart';
import '../models/reporte.dart';

class ListaReportesScreen extends StatefulWidget {
  final List<Reporte> reportes;
  const ListaReportesScreen({super.key, required this.reportes});

  @override
  State<ListaReportesScreen> createState() => _ListaReportesScreenState();
}

class _ListaReportesScreenState extends State<ListaReportesScreen> {
  String? estado;
  String? prioridad;
  String? tipoResiduo;
  // Mapa para guardar el estado seleccionado de cada reporte
  final Map<String, String> estadoBoton = {};

  @override
  Widget build(BuildContext context) {
    var filtrados = widget.reportes.where((r) {
      if (estado != null && r.estado != estado) return false;
      if (prioridad != null && r.prioridad != prioridad) return false;
      if (tipoResiduo != null && r.tipoResiduo != tipoResiduo) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Filtros
        Row(
          children: [
            DropdownButton<String>(
              hint: const Text('Estado'),
              value: estado,
              items: ['Pendiente', 'En proceso', 'Completado']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => estado = v),
            ),
            DropdownButton<String>(
              hint: const Text('Prioridad'),
              value: prioridad,
              items: ['Alta', 'Media', 'Baja']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => prioridad = v),
            ),
            DropdownButton<String>(
              hint: const Text('Tipo'),
              value: tipoResiduo,
              items: ['Plástico', 'Orgánico', 'Vidrio']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => tipoResiduo = v),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtrados.length,
            itemBuilder: (context, i) {
              final r = filtrados[i];
              // Estado actual del botón para este reporte
              final estadoActual = estadoBoton[r.id] ?? 'Recibido';
              return Card(
                child: ListTile(
                  leading: Image.network(r.fotoUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(r.clasificacion),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.ubicacion}\n${r.estado} - ${r.prioridad} - ${r.tipoResiduo}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Estado: '),
                          DropdownButton<String>(
                            value: estadoActual,
                            items: const [
                              DropdownMenuItem(value: 'Recibido', child: Text('Recibido')),
                              DropdownMenuItem(value: 'En recorrido', child: Text('En recorrido')),
                              DropdownMenuItem(value: 'Recogido', child: Text('Recogido')),
                            ],
                            onChanged: (nuevoEstado) {
                              if (nuevoEstado != null) {
                                setState(() {
                                  estadoBoton[r.id] = nuevoEstado;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}