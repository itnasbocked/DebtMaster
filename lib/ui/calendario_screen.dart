import 'package:dm/data/database/database_helper.dart';
import 'package:flutter/material.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => CalendarioScreenState();
}

class CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _eventosDelDia = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    cargarEventos();
  }

  String _formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  Future<void> cargarEventos() async {
    setState(() => _cargando = true);
    String fechaStr = _formatearFecha(_fechaSeleccionada);
    try {
      final eventos = await DatabaseHelper.instance.obtenerMovimientosPorFecha(fechaStr);
      setState(() => _eventosDelDia = eventos);
    } catch (e) {
      debugPrint("Error al consultar DB: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarFormularioEvento(BuildContext context) {
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    String tipo = 'egreso';
    bool esFijo = false;
    bool crearAlerta = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Programar Evento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004481))),
              Row(
                children: [
                  Expanded(child: RadioListTile(title: const Text("Gasto"), value: 'egreso', groupValue: tipo, onChanged: (v) => setModalState(() => tipo = v!))),
                  Expanded(child: RadioListTile(title: const Text("Ingreso"), value: 'ingreso', groupValue: tipo, onChanged: (v) => setModalState(() => tipo = v!))),
                ],
              ),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: montoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Monto (\$)", border: OutlineInputBorder())),
              SwitchListTile(title: const Text("Movimiento recurrente"), value: esFijo, activeColor: const Color(0xFF004481), onChanged: (v) => setModalState(() => esFijo = v)),
              SwitchListTile(title: const Text("Crear alerta"), value: crearAlerta, activeColor: const Color(0xFF004481), onChanged: (v) => setModalState(() => crearAlerta = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004481), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    int montoCen = ((double.tryParse(montoCtrl.text) ?? 0) * 100).toInt();
                    String fecha = _formatearFecha(_fechaSeleccionada);

                    int? idUsuario = DatabaseHelper.instance.userId;
                    if (idUsuario == null) return;

                    await DatabaseHelper.instance.insertarMovimiento({
                      'usuario_id': idUsuario, 'monto': montoCen, 'fecha': fecha, 'tipo': tipo, 'descripcion': descCtrl.text, 'frecuencia': 'ninguna'
                    });

                    if (esFijo) {
                      if (tipo == 'egreso') {
                        await DatabaseHelper.instance.insertarGastoFijo({'usuario_id': idUsuario, 'nombre_gasto': descCtrl.text, 'monto': montoCen, 'frecuencia': 'mensual', 'fecha_pago': fecha});
                      } else {
                        await DatabaseHelper.instance.insertarIngresoFijo({'usuario_id': idUsuario, 'nombre_ingreso': descCtrl.text, 'monto': montoCen, 'frecuencia': 'mensual', 'fecha_cobro': fecha});
                      }
                    }

                    if (crearAlerta) {
                      await DatabaseHelper.instance.insertarAlerta({'usuario_id': idUsuario, 'tipo': 'recordatorio', 'fecha_alerta': fecha, 'mensaje': 'Evento: ${descCtrl.text}'});
                    }

                    if (context.mounted) Navigator.pop(context);
                    cargarEventos();
                  },
                  child: const Text("Guardar", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            
            child: CalendarDatePicker(
              initialDate: _fechaSeleccionada,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (DateTime nuevaFecha) {
                setState(() {
                  _fechaSeleccionada = nuevaFecha;
                });
                cargarEventos();
              },
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Eventos del ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : _eventosDelDia.isEmpty
                ? const Center(
                    child: Text("Sin eventos programados.", style: TextStyle(color: Colors.grey))
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _eventosDelDia.length,
                    itemBuilder: (context, i) {
                      final ev = _eventosDelDia[i];
                      bool esIngreso = ev['tipo'] == 'ingreso';
                      double montoPesos = (ev['monto'] as int) / 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: esIngreso ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                                color: esIngreso ? const Color(0xFF4CAF50) : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                ev['descripcion'] ?? "Sin nombre",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            Text(
                              "${esIngreso ? '+' : '-'}\$${montoPesos.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: esIngreso ? const Color(0xFF4CAF50) : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF004481),
        onPressed: () => _mostrarFormularioEvento(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}