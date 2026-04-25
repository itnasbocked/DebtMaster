import 'package:dm/data/database/database_helper.dart';
import 'package:flutter/material.dart';

class TarjetasScreen extends StatefulWidget {
  const TarjetasScreen({super.key});

  @override
  State<TarjetasScreen> createState() => _TarjetasScreenState();
}

class _TarjetasScreenState extends State<TarjetasScreen> {
  double _presupuesto = 0.0;
  List<Map<String, dynamic>> _misTarjetas = [];
  String _nombreUsuario = "Cargando...";
  bool _cargando = true;
  
  int _diasParaCorte = 0;
  double _porcentajeSalud = 0.0; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  int _calcularDiasRestantes(int diaObjetivo) {
    DateTime hoy = DateTime.now();
    DateTime fechaObjetivo = DateTime(hoy.year, hoy.month, diaObjetivo);
    
    if (fechaObjetivo.isBefore(hoy)) {
      fechaObjetivo = DateTime(hoy.year, hoy.month + 1, diaObjetivo);
    }
    return fechaObjetivo.difference(hoy).inDays;
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    debugPrint("--- DB TRACE: Iniciando carga de datos... ---");
    
    try {
      DatabaseHelper db = DatabaseHelper.instance;
      final baseDatos = await db.database;

      double pres = await db.calcularPresupuestoDiarioSeguro();
      
      List<Map<String, dynamic>> tarjList = await baseDatos.query('tarjeta');

      List<Map<String, dynamic>> usuarioList = await baseDatos.query('usuario', where: 'id = 1');
      String nombreDinamico = usuarioList.isNotEmpty ? usuarioList.first['nombre'] as String : "Usuario";
      List<Map<String, dynamic>> userList = await baseDatos.query('usuario', limit: 1);
      if (userList.isNotEmpty) {
        nombreDinamico = userList.first['nombre'] ?? "Usuario";
      }

      int diasFaltantes = 0;
      if (tarjList.isNotEmpty) {
        int diaCorte = tarjList.first['corte_dia'] as int;
        DateTime hoy = DateTime.now();
        DateTime fechaCorte = DateTime(hoy.year, hoy.month, diaCorte);
        
        if (fechaCorte.isBefore(hoy)) {
          fechaCorte = DateTime(hoy.year, hoy.month + 1, diaCorte);
        }
        diasFaltantes = fechaCorte.difference(hoy).inDays;
      }

      final ingresosData = await baseDatos.rawQuery("SELECT SUM(monto) as total FROM movimiento WHERE tipo = 'ingreso'");
      double ingresosCentavos = (ingresosData.first['total'] as num?)?.toDouble() ?? 0.0;
      double ingresosPesos = ingresosCentavos / 100;

      double porcentaje = 0.0;
      if (ingresosPesos > 0) {
         double obligacionesTotales = 0.0;
         for(var t in tarjList) {
           obligacionesTotales += (t['monto_minimo'] as num).toDouble() / 100;
         }
         
         double libre = ingresosPesos - obligacionesTotales;
         if (libre < 0) libre = 0;
         
         porcentaje = libre / ingresosPesos; 
      }

      setState(() {
        _presupuesto = pres;
        _misTarjetas = tarjList;
        _diasParaCorte = diasFaltantes;
        _porcentajeSalud = porcentaje;
        _nombreUsuario = nombreDinamico;
      });

    } catch (e) {
      debugPrint("--- ERROR CRÍTICO EN CARGA: $e ---");
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarFormularioNuevaTarjeta(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final corteCtrl = TextEditingController();
    final pagoCtrl = TextEditingController();
    final montoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vincular Nueva Tarjeta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004481))),
                const SizedBox(height: 20),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Banco (Ej. Nu, Rappi, BBVA)", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: numeroCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: "Últimos 4 dígitos", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: corteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Día de Corte", border: OutlineInputBorder()))),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: pagoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Día de Pago", border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: montoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Pago para no generar intereses (\$)", border: OutlineInputBorder())),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004481), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      double montoPesos = double.tryParse(montoCtrl.text) ?? 0.0;
                      int montoCentavos = (montoPesos * 100).toInt(); 
                      
                      Map<String, dynamic> nuevaTarjeta = {
                        'usuario_id': 1, 
                        'nombre_tarjeta': nombreCtrl.text.isEmpty ? 'Desconocido' : nombreCtrl.text,
                        'numero_tarjeta': 'XXXX XXXX XXXX ${numeroCtrl.text}',
                        'tipo': 'Credito',
                        'corte_dia': int.tryParse(corteCtrl.text) ?? 1,
                        'pago_dia': int.tryParse(pagoCtrl.text) ?? 1,
                        'monto_minimo': montoCentavos
                      };

                      await DatabaseHelper.instance.insertarTarjeta(nuevaTarjeta);
                      if (context.mounted) Navigator.pop(context);
                      await _cargarDatos(); 
                    },
                    child: const Text("Guardar Tarjeta", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool esNegativo = _presupuesto <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Text("Hola $_nombreUsuario", style: const TextStyle(fontSize: 22, color: Colors.black87)),
                        const SizedBox(width: 5),
                        const Text("👋", style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text("Hoy puedes gastar....", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "\$${_presupuesto.toStringAsFixed(2)} MXN",
                            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: esNegativo ? Colors.red : const Color(0xFF4CAF50)),
                          ),
                          const SizedBox(height: 10),
                          const Text("\"Sin afectar pagos ni metas\"", style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  if (_misTarjetas.isNotEmpty) ...[
                    SizedBox(
                      height: 190,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.88),
                        itemCount: _misTarjetas.length,
                        itemBuilder: (context, index) {
                          final t = _misTarjetas[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004481),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['nombre_tarjeta'] ?? "BANCO", 
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  t['numero_tarjeta'] ?? "XXXX XXXX XXXX XXXX",
                                  style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
                                ),
                                const Spacer(),
                                Text(
                                  _nombreUsuario.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Center(
                      child: Text("👉 Desliza para ver tus otras tarjetas", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        "\"fecha de corte en $_diasParaCorte días\"", 
                        style: const TextStyle(color: Color(0xFFD9A06F), fontStyle: FontStyle.italic, fontSize: 14),
                      ),
                    ),
                  ] else ...[
                    const Center(
                      child: Text("No tienes tarjetas registradas.\nPresiona el botón '+' para agregar una.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    )
                  ],

                  const SizedBox(height: 45),

                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200, height: 200,
                          child: Stack(
                            children: [
                              Center(
                                child: SizedBox(
                                  width: 200, height: 200,
                                  child: CircularProgressIndicator(
                                    value: _porcentajeSalud, 
                                    strokeWidth: 20, 
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(_porcentajeSalud < 0.20 ? Colors.red : const Color(0xFF4CAF50)),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  "${(_porcentajeSalud * 100).toInt()}%",
                                  style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("Salud financiera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87))
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF004481),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _mostrarFormularioNuevaTarjeta(context);
        },
      ),
    );
  }
}