import 'package:dm/data/database/database_helper.dart';
import 'package:dm/logic/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => CalendarioScreenState();
}

class CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime _mesEnVista = DateTime.now();
  List<Map<String, dynamic>> _eventosDelDia = [];
  
  // Cache de marcadores en RAM para acceso ultra rápido (Separado por estado)
  Set<String> _diasConMovimientosReales = {}; 
  Set<int> _diasConPlanesRecurrentes = {}; 
  Set<String> _diasConPlanesUnicos = {};
  
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMarcadores();
    cargarEventos();
  }

  Future<void> _sincronizarTodo() async {
    await _cargarMarcadores();
    await cargarEventos();
  }

  String _formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  Future<void> _cargarMarcadores() async {
    int? idUsuario = DatabaseHelper.instance.userId;
    if (idUsuario == null) return;

    final db = await DatabaseHelper.instance.database;
    
    final resReal = await db.rawQuery(
      "SELECT DISTINCT fecha FROM movimiento WHERE usuario_id = ?", [idUsuario]
    );

    final resRec = await db.rawQuery(
      "SELECT DISTINCT CAST(SUBSTR(fecha_pago, 9, 2) AS INTEGER) as dia FROM gasto_fijo WHERE usuario_id = ? AND frecuencia = 'mensual' "
      "UNION SELECT DISTINCT CAST(SUBSTR(fecha_cobro, 9, 2) AS INTEGER) as dia FROM ingreso_fijo WHERE usuario_id = ? AND frecuencia = 'mensual'", 
      [idUsuario, idUsuario]
    );

    final resUnico = await db.rawQuery(
      "SELECT DISTINCT fecha_pago as fecha FROM gasto_fijo WHERE usuario_id = ? AND frecuencia = 'unica' "
      "UNION SELECT DISTINCT fecha_cobro as fecha FROM ingreso_fijo WHERE usuario_id = ? AND frecuencia = 'unica'",
      [idUsuario, idUsuario]
    );

    if (mounted) {
      setState(() {
        _diasConMovimientosReales = resReal.map((row) => row['fecha'] as String).toSet();
        _diasConPlanesRecurrentes = resRec.map((row) => row['dia'] as int).toSet();
        _diasConPlanesUnicos = resUnico.map((row) => row['fecha'] as String).toSet();
      });
    }
  }

  Future<void> cargarEventos() async {
    setState(() => _cargando = true);
    int? idUsuario = DatabaseHelper.instance.userId;
    String fechaStr = _formatearFecha(_fechaSeleccionada);
    int diaSeleccionado = _fechaSeleccionada.day;

    try {
      final db = await DatabaseHelper.instance.database;

      final movimientos = await DatabaseHelper.instance.obtenerMovimientosPorFecha(fechaStr);

      final planeadosRaw = await db.rawQuery(
        "SELECT *, 'egreso' as tipo, nombre_gasto as descripcion FROM gasto_fijo WHERE usuario_id = ? AND ((frecuencia = 'mensual' AND CAST(SUBSTR(fecha_pago, 9, 2) AS INTEGER) = ?) OR (frecuencia = 'unica' AND fecha_pago = ?)) "
        "UNION "
        "SELECT *, 'ingreso' as tipo, nombre_ingreso as descripcion FROM ingreso_fijo WHERE usuario_id = ? AND ((frecuencia = 'mensual' AND CAST(SUBSTR(fecha_cobro, 9, 2) AS INTEGER) = ?) OR (frecuencia = 'unica' AND fecha_cobro = ?))",
        [idUsuario, diaSeleccionado, fechaStr, idUsuario, diaSeleccionado, fechaStr]
      );

      List<Map<String, dynamic>> planesPendientes = [];
      for (var p in planeadosRaw) {
        Object? nombreBase = p['descripcion'];
        bool esRecurrente = p['frecuencia'] == 'mensual';
        bool yaExiste = movimientos.any((m) => (m['descripcion']) == nombreBase);
        if (!(esRecurrente && yaExiste)) {
          planesPendientes.add({...p, 'esPlan': true});
        }
      }

      if (mounted) {
        setState(() {
          _eventosDelDia = [
            ...movimientos.map((m) => {...m, 'esPlan': false}), 
            ...planesPendientes
          ];
        });
      }
    } catch (e) {
      debugPrint("Error al sincronizar recurrentes: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _confirmarPlan(Map<String, dynamic> plan) {
    bool esRecurrente = plan['frecuencia'] == 'mensual';
    String nombreReal = plan['descripcion'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(left: 24, top: 15, right: 10, bottom: 10),
        
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                esRecurrente ? "$nombreReal - Evento Mensual" : "$nombreReal - Evento Único", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              )
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
              tooltip: "Eliminar plan permanentemente",
              onPressed: () async {
                Navigator.pop(context);
                final db = await DatabaseHelper.instance.database;
                String tabla = plan['tipo'] == 'egreso' ? 'gasto_fijo' : 'ingreso_fijo';
                
                await db.delete(tabla, where: 'id = ?', whereArgs: [plan['id']]);
                
                Fluttertoast.showToast(msg: esRecurrente ? "Evento mensual eliminado" : "Evento eliminado");
                _sincronizarTodo();
              }, 
            ),
          ],
        ),
        
        content: Text(
          esRecurrente 
            ? "¿Deseas registrar este movimiento en tu balance real de hoy? (Para cancelar este plan en el futuro, usa el icono de papelera)."
            : "¿Deseas registrar este movimiento en tu balance real de hoy?"
        ),
        
        actionsPadding: const EdgeInsets.only(right: 20, bottom: 15),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004481),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              await DatabaseHelper.instance.insertarMovimiento({
                'usuario_id': plan['usuario_id'],
                'monto': plan['monto'],
                'fecha': _formatearFecha(_fechaSeleccionada),
                'tipo': plan['tipo'],
                'descripcion': nombreReal,
                'frecuencia': 'ninguna'
              });

              if (!esRecurrente) {
                final db = await DatabaseHelper.instance.database;
                String tabla = plan['tipo'] == 'egreso' ? 'gasto_fijo' : 'ingreso_fijo';
                await db.delete(tabla, where: 'id = ?', whereArgs: [plan['id']]);
              }

              Fluttertoast.showToast(msg: "Movimiento confirmado");
              _sincronizarTodo();
            },
            child: const Text("Confirmar", style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }

  void _mostrarFormularioEvento(BuildContext context) {
    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    String tipo = 'egreso';
    bool esFijo = false;
    bool crearAlerta = false;

    bool guardando = false;

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
                  // ignore: dead_code
                  onPressed: guardando ? null: () async {
                    setModalState(() => guardando = true);

                    try{
                      int montoCen = ((double.tryParse(montoCtrl.text) ?? 0) * 100).toInt();
                      String fecha = _formatearFecha(_fechaSeleccionada);
                      int? idUsuario = DatabaseHelper.instance.userId;
                      if (idUsuario == null) return;

                      if (descCtrl.text.isEmpty || montoCen <= 0) {
                        Fluttertoast.showToast(msg: "Por favor completa todos los campos correctamente.", backgroundColor: Colors.red);
                        setModalState(() => guardando = false);
                        return;
                      }

                      if (tipo == 'egreso') {
                        await DatabaseHelper.instance.insertarGastoFijo({
                          'usuario_id': idUsuario, 'nombre_gasto': descCtrl.text, 'monto': montoCen, 
                          'frecuencia': esFijo ? 'mensual' : 'unica', 'fecha_pago': fecha
                        });
                      } else {
                        await DatabaseHelper.instance.insertarIngresoFijo({
                          'usuario_id': idUsuario, 'nombre_ingreso': descCtrl.text, 'monto': montoCen, 
                          'frecuencia': esFijo ? 'mensual' : 'unica', 'fecha_cobro': fecha
                        });
                      }

                      if (crearAlerta) {
                        await DatabaseHelper.instance.insertarAlerta({'usuario_id': idUsuario, 'tipo': 'recordatorio', 'fecha_alerta': fecha, 'mensaje': 'Evento: ${descCtrl.text}'});
                        
                        DateTime ahora = DateTime.now();
                        DateTime fechaEvento;

                        if(_fechaSeleccionada.year == ahora.year &&
                        _fechaSeleccionada.month == ahora.month &&
                        _fechaSeleccionada.day == ahora.day){
                          debugPrint("Alarmita");
                          fechaEvento = ahora.add(const Duration(seconds: 10));
                        } else {
                          fechaEvento = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, _fechaSeleccionada.day, 9, 0);
                        }
                        
                        try{
                          await NotificationService().programarNotificacion(
                          DateTime.now().millisecondsSinceEpoch ~/ 1000, 
                          "Recordatorio: ${descCtrl.text}", 
                          "Evento programado para el ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}", 
                          fechaEvento
                          );
                          Fluttertoast.showToast(msg: "Alerta programada exitosamente!", toastLength: Toast.LENGTH_SHORT, backgroundColor: Colors.green, textColor: Colors.white, gravity: ToastGravity.BOTTOM);
                        }catch(e){
                          debugPrint("DEBUG: Error al programar notificación: $e");
                        }
                      }

                      if (context.mounted) Navigator.pop(context);
                      
                      await _cargarMarcadores();
                      await cargarEventos();
                    } catch(e){
                      setModalState(() => guardando = false);
                      Fluttertoast.showToast(msg: "Error al guardar evento: $e", backgroundColor: Colors.red);
                      return;
                    }
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
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: TableCalendar(
              firstDay: DateTime(2020), lastDay: DateTime(2030),
              focusedDay: _mesEnVista, currentDay: _fechaSeleccionada,
              availableCalendarFormats: const { CalendarFormat.month: 'Mes' },
              headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() { _fechaSeleccionada = selectedDay; _mesEnVista = focusedDay; });
                cargarEventos();
              },
              onPageChanged: (focusedDay) => _mesEnVista = focusedDay,
              
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  String fechaFormateada = _formatearFecha(date);
                  
                  bool tieneReal = _diasConMovimientosReales.contains(fechaFormateada);
                  bool tienePlan = _diasConPlanesRecurrentes.contains(date.day) || _diasConPlanesUnicos.contains(fechaFormateada);

                  if (tieneReal || tienePlan) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: tienePlan ? Colors.amber : const Color(0xFF004481),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Eventos del ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : _eventosDelDia.isEmpty
                ? const Center(child: Text("Día libre, sin eventos.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _eventosDelDia.length,
                    itemBuilder: (context, i) {
                      final ev = _eventosDelDia[i];
                      bool esIngreso = ev['tipo'] == 'ingreso';
                      bool esPlan = ev['esPlan'] == true;
                      double montoPesos = (ev['monto'] as int) / 100;

                      return GestureDetector(
                        onTap: esPlan ? () => _confirmarPlan(ev) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: esPlan ? Border.all(color: Colors.amber, width: 2.0) : null,
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
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: esPlan ? Colors.amber.shade900 : Colors.black87
                                ),
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
                      ));
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