import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/meta_model.dart';
import '../data/database/database_helper.dart';
import '../data/models/aporte_meta_model.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  List<Meta> metas = [];
  final Color primaryBlue = const Color(0xFF2563EB);
  final Color secondaryGreen = const Color(0xFF6BC88E);

  final int idUsuarioActual = 1;

  @override
  void initState() {
    super.initState();
    _cargarMetas();
  }

  Future<void> _cargarMetas() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('meta', where: 'usuario_id = ?', whereArgs: [idUsuarioActual]);
    setState(() {
      metas = result.map((map) => Meta.fromMap(map)).toList();
    });
  }

  Future<void> _guardarNuevaMeta(Meta nuevaMeta) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('meta', nuevaMeta.toMap());
    await _cargarMetas();
  }

  Future<void> _actualizarMeta(Meta metaEditada) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('meta', metaEditada.toMap(), where: 'id = ?', whereArgs: [metaEditada.id]);
    await _cargarMetas();
  }

  Future<void> _eliminarMeta(int idMeta) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('aporte_meta', where: 'meta_id = ?', whereArgs: [idMeta]);
    await db.delete('meta', where: 'id = ?', whereArgs: [idMeta]);
    await _cargarMetas();
  }

  Future<void> _abonarMeta(Meta meta, int centavosAhorro) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('aporte_meta', {
      'meta_id': meta.id,
      'monto': centavosAhorro,
      'fecha': DateTime.now().toIso8601String(),
    });

    int nuevoMonto = meta.montoActual + centavosAhorro;
    if (nuevoMonto > meta.montoObjetivo) nuevoMonto = meta.montoObjetivo;

    await db.update('meta', {'monto_actual': nuevoMonto}, where: 'id = ?', whereArgs: [meta.id]);
    await _cargarMetas();
  }

  Future<List<AporteMeta>> _obtenerHistorial(int metaId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'aporte_meta', 
      where: 'meta_id = ?', 
      whereArgs: [metaId],
      orderBy: 'fecha DESC'
    );
    return result.map((map) => AporteMeta.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Objetivos activos", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: metas.length + 1,
                itemBuilder: (context, index) {
                  if (index == metas.length) return _buildBotonCrearMeta();
                  return _buildTarjetaMeta(metas[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaMeta(Meta meta) {
    double progreso = meta.montoObjetivo == 0 ? 0 : meta.montoActual / meta.montoObjetivo;
    int porcentaje = (progreso * 100).toInt();

    return GestureDetector(
      onTap: () async {
        List<AporteMeta> historial = await _obtenerHistorial(meta.id!);
        _mostrarDetallesMeta(meta, historial);
      }, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${meta.nombre} ${meta.icono}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("$porcentaje%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(secondaryGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "\$${(meta.montoActual / 100).toStringAsFixed(0)} / \$${(meta.montoObjetivo / 100).toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Fecha límite: ${DateFormat('dd MMM yyyy').format(meta.fechaLimite)}",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonCrearMeta() {
    return GestureDetector(
      onTap: _mostrarDialogoNuevaMeta,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Text("Crear nueva meta", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  void _mostrarDetallesMeta(Meta meta, List<AporteMeta> historial) {
    TextEditingController aC = TextEditingController();
    double progreso = meta.montoObjetivo == 0 ? 0 : meta.montoActual / meta.montoObjetivo;
    int porcentaje = (progreso * 100).toInt();

    List<double> alturas = List.filled(6, 0.0);
    List<String> nombresMeses = List.filled(6, "");
    
    DateTime ahora = DateTime.now();
    double maxAbono = 0;
    List<double> montosPorMes = List.filled(6, 0.0);

    for (int i = 5; i >= 0; i--) {
      DateTime mesEvaluar = DateTime(ahora.year, ahora.month - i, 1);
      nombresMeses[5 - i] = DateFormat('MMM').format(mesEvaluar);
      double sumaMes = 0;
      for(var aporte in historial) {
        if(aporte.fecha.year == mesEvaluar.year && aporte.fecha.month == mesEvaluar.month) {
          sumaMes += aporte.monto;
        }
      }
      montosPorMes[5 - i] = sumaMes;
      if (sumaMes > maxAbono) maxAbono = sumaMes;
    }

    if (maxAbono > 0) {
      for(int i = 0; i < 6; i++) {
        alturas[i] = montosPorMes[i] / maxAbono;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            top: 32, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA), 
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${meta.nombre} ${meta.icono}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("$porcentaje% completado", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                    onPressed: () {
                      Navigator.pop(context); 
                      _mostrarDialogoEditarMeta(meta); 
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context); 
                      _confirmarEliminacion(meta); 
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return Column(
                      children: [
                        Container(
                          height: 100, width: 18,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            height: 100 * alturas[index],
                            width: 18,
                            decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(nombresMeses[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 25),
              const Text("Historial de aportes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),

              Expanded(
                child: historial.isEmpty 
                  ? const Center(child: Text("Aún no hay aportes registrados.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: historial.length,
                      itemBuilder: (context, index) {
                        var aporte = historial[index];
                        String fechaLimpia = DateFormat('dd MMM yyyy').format(aporte.fecha);
                        return AporteItem(
                          mes: fechaLimpia, 
                          monto: "+\$${(aporte.monto / 100).toStringAsFixed(2)}"
                        );
                      },
                    ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: aC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Cantidad a abonar",
                        prefixText: "\$ ",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      double abono = double.tryParse(aC.text) ?? 0;
                      if (abono > 0) {
                        await _abonarMeta(meta, (abono * 100).round());
                        Navigator.pop(context); 
                      }
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              )
            ],
          ),
        );
      }
    );
  }

  void _confirmarEliminacion(Meta meta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar meta?"),
        content: Text("Estás a punto de borrar '${meta.nombre}' y todo su historial de aportes. Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _eliminarMeta(meta.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarMeta(Meta meta) {
    TextEditingController nC = TextEditingController(text: meta.nombre);
    TextEditingController mC = TextEditingController(text: (meta.montoObjetivo / 100).toStringAsFixed(0));
    String iconoSeleccionado = meta.icono;
    DateTime fechaSeleccionada = meta.fechaLimite;
    
    final List<String> opcionesIconos = ["👾", "💻", "🚗", "✈️", "🏠", "📱", "🎓", "🎮", "🎸", "💰"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar Meta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: opcionesIconos.contains(iconoSeleccionado) ? iconoSeleccionado : "💰",
                    decoration: const InputDecoration(labelText: "Icono de la meta"),
                    items: opcionesIconos.map((String emoji) {
                      return DropdownMenuItem(
                        value: emoji,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      );
                    }).toList(),
                    onChanged: (String? nuevoValor) {
                      setStateDialog(() {
                        if (nuevoValor != null) iconoSeleccionado = nuevoValor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: "Nombre")),
                  const SizedBox(height: 8),
                  TextField(controller: mC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Objetivo (\$)")),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Fecha límite", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            Text(
                              DateFormat('dd MMM yyyy').format(fechaSeleccionada),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          DateTime? seleccion = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2100),
                          );
                          if (seleccion != null) {
                            setStateDialog(() => fechaSeleccionada = seleccion);
                          }
                        },
                        child: const Text("Cambiar"),
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double monto = double.tryParse(mC.text) ?? 0;
                    if (monto > 0 && nC.text.isNotEmpty) {
                      Meta metaActualizada = Meta(
                        id: meta.id,
                        usuarioId: meta.usuarioId,
                        nombre: nC.text,
                        montoObjetivo: (monto * 100).round(),
                        montoActual: meta.montoActual, 
                        fechaLimite: fechaSeleccionada,
                        icono: iconoSeleccionado,
                      );
                      await _actualizarMeta(metaActualizada);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("Actualizar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoNuevaMeta() {
    TextEditingController nC = TextEditingController();
    TextEditingController mC = TextEditingController();
    
    String iconoSeleccionado = "👾"; 
    final List<String> opcionesIconos = ["👾", "💻", "🚗", "✈️", "🏠", "📱", "🎓", "🎮", "🎸", "💰"];
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 30)); 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nueva Meta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: iconoSeleccionado,
                    decoration: const InputDecoration(labelText: "Icono de la meta"),
                    items: opcionesIconos.map((String emoji) {
                      return DropdownMenuItem(
                        value: emoji,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      );
                    }).toList(),
                    onChanged: (String? nuevoValor) {
                      setStateDialog(() {
                        if (nuevoValor != null) iconoSeleccionado = nuevoValor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nC, decoration: const InputDecoration(labelText: "Nombre (Ej: PC Gamer)")),
                  const SizedBox(height: 8),
                  TextField(controller: mC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Objetivo (\$)")),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Fecha límite", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            Text(
                              DateFormat('dd MMM yyyy').format(fechaSeleccionada),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: primaryBlue),
                        onPressed: () async {
                          DateTime? seleccion = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime.now(), 
                            lastDate: DateTime(2100),  
                          );
                          if (seleccion != null) {
                            setStateDialog(() {
                              fechaSeleccionada = seleccion;
                            });
                          }
                        },
                        child: const Text("Cambiar"),
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    double monto = double.tryParse(mC.text) ?? 0;
                    if (monto > 0 && nC.text.isNotEmpty) {
                      await _guardarNuevaMeta(Meta(
                        usuarioId: idUsuarioActual,
                        nombre: nC.text,
                        montoObjetivo: (monto * 100).round(),
                        fechaLimite: fechaSeleccionada,
                        icono: iconoSeleccionado,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                )
              ],
            );
          },
        );
      },
    );
  }
}

class AporteItem extends StatelessWidget {
  final String mes;
  final String monto;

  const AporteItem({super.key, required this.mes, required this.monto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(mes, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            monto,
            style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}