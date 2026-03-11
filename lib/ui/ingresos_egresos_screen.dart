import 'package:flutter/material.dart';
// import '../data/database/database_helper.dart';
import '../data/models/ingresos-egresos_model.dart';
import '../logic/movimiento_controller.dart';

class IngresosEgresosScreen extends StatefulWidget {
  const IngresosEgresosScreen({super.key});

  @override
  State<IngresosEgresosScreen> createState() => _IngresosEgresosScreenState();
}

class HistorialScreen extends StatefulWidget {
  final List<Movimiento> movimientos;

  const HistorialScreen(this.movimientos, {super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final MovimientoController _logic = MovimientoController();
  
  late List<Movimiento> listaMutable;

  @override
  void initState() {
    super.initState();
    listaMutable = List.from(widget.movimientos);
  }

  bool esDelMesActual(DateTime fecha) {
    DateTime now = DateTime.now();
    return fecha.month == now.month && fecha.year == now.year;
  }

  int idUsuario = 1;
  List<Movimiento> movimientos = [];
  double balanceTotal = 0.0;

  Future<void> _recargarDatos() async {
    final list = await _logic.obtenerMovimientos(idUsuario);
    final balance = await _logic.formatearBalance(idUsuario);
    setState(() {
      movimientos = list;
      balanceTotal = balance;
    });
  }


 void _borrarMovimiento(int index, int idBaseDatos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar movimiento?"),
        content: const Text("Estás a punto de borrar este registro financiero. Esta acción alterará tu balance actual y no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _logic.borrarMovimiento(idBaseDatos);
              
              if (context.mounted) Navigator.pop(context);
              
              setState(() {
                listaMutable.removeAt(index);
              });
              _recargarDatos();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var listaMes = listaMutable.where((m) => esDelMesActual(m.fecha)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial del Mes"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: listaMes.isEmpty
          ? const Center(child: Text("No hay movimientos este mes."))
          : ListView.builder(
              itemCount: listaMes.length,
              itemBuilder: (_, index) {
                var m = listaMes[index];
                bool esIngreso = m.tipo == "ingreso";

                String dia = m.fecha.day.toString().padLeft(2, '0');
                String mes = m.fecha.month.toString().padLeft(2, '0');
                String anio = m.fecha.year.toString();
                String fechaLimpia = "$dia/$mes/$anio";

                return ListTile(
                  onTap: () {}, 
                  title: Text(
                    m.descripcion ?? "Sin descripción", 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(fechaLimpia),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "\$${(m.monto / 100).toStringAsFixed(2)}",
                        style: TextStyle(
                          color: esIngreso ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                        onPressed: () => _mostrarDialogoEdicion(m, index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          // Buscamos el índice original en la lista general para no borrar el equivocado
                          int originalIndex = listaMutable.indexOf(m);
                          _borrarMovimiento(originalIndex, m.id!);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  void _mostrarDialogoEdicion(Movimiento m, int index) {
    TextEditingController mC = TextEditingController(text: (m.monto / 100).toStringAsFixed(2));
    TextEditingController dC = TextEditingController(text: m.descripcion);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Movimiento"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: mC, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Nuevo Monto")
            ),
            TextField(
              controller: dC, 
              decoration: const InputDecoration(labelText: "Nueva Descripción")
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              bool exito = await _logic.actualizarMovimiento(m.id!, mC.text, dC.text);
              
              if (exito) {
                setState(() {
                  double nuevoValor = double.parse(mC.text);
                  m.monto = (nuevoValor * 100).round();
                  m.descripcion = dC.text;
                  listaMutable[index] = m;
                  _recargarDatos();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Actualizar"),
          )
        ],
      ),
    );
  }
}

class _IngresosEgresosScreenState extends State<IngresosEgresosScreen> {
  
  final MovimientoController _logic = MovimientoController();
  List<Movimiento> movimientos = [];
  double balanceTotal = 0.0;
  int idUsuario = 1;
  
  final Color primaryBlue = const Color(0xFF2563EB);    // Azul Principal
  final Color secondaryGreen = const Color(0xFF6BC88E); // Verde Secundario
  final Color criticalRed = const Color(0xFFDA3838);    // Rojo Crítico
  final Color backgroundColor = const Color(0xFFF2F4F7); // Fondo suave

  @override
  void initState() {
    super.initState();
    _recargarDatos();
  }

  Future<void> _recargarDatos() async {
    final list = await _logic.obtenerMovimientos(idUsuario);
    final balance = await _logic.formatearBalance(idUsuario);
    setState(() {
      movimientos = list;
      balanceTotal = balance;
    });
  }

  Future<void> _mostrarHistorial() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => HistorialScreen(movimientos))
    );
    _recargarDatos(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text(
              //   "Ingresos y Egresos",
              //   style: TextStyle(
              //       fontSize: 28,
              //       fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 32),

              _buildBalanceCard(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildSummaryCard("Ingresos", _calcularSuma("ingreso"), secondaryGreen, Icons.arrow_upward)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard("Egresos", _calcularSuma("egreso"), criticalRed, Icons.arrow_downward)),
                ],
              ),

              const SizedBox(height: 32),

              _buildHealthSection(),

              const SizedBox(height: 40),

              _buildActionButtons(),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Text("Balance General", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text("\$${balanceTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          Text("\$${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    double ratio = _calcularSuma("ingreso") == 0 ? 0 : (_calcularSuma("egreso") / _calcularSuma("ingreso"));
    
    // Máquina de estados para color y mensaje
    Color color;
    String estadoSalud;
    String descripcionSalud;

    if (ratio > 0.8) {
      color = criticalRed;
      estadoSalud = "Crítico";
      descripcionSalud = "Tus gastos están al límite.";
    } else if (ratio > 0.5) {
      color = Colors.yellow.shade700;
      estadoSalud = "Precaución";
      descripcionSalud = "Modera tus egresos.";
    } else {
      color = secondaryGreen;
      estadoSalud = "Excelente";
      descripcionSalud = "Finanzas bajo control.";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8EB), 
        borderRadius: BorderRadius.circular(30)
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            height: 85,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  backgroundColor: const Color(0xCC111827),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Text(
                    "${(ratio * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24), // Separación entre gráfica y texto
          
          Expanded( // Expanded evita que el texto rompa la pantalla si es muy largo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Salud: $estadoSalud", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
                const SizedBox(height: 4),
                Text(
                  descripcionSalud, 
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  double _calcularSuma(String tipo) {
    int total = movimientos.where((m) => m.tipo == tipo).fold(0, (sum, m) => sum + m.monto);
    return total / 100.0;
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.history, primaryBlue, _mostrarHistorial),
        const SizedBox(width: 32),
        _buildCircleButton(Icons.add, primaryBlue, _mostrarMenuAgregar),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(21)),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  void _mostrarMenuAgregar() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.add), title: const Text("Ingreso"), onTap: () => _abrirDialogo("ingreso")),
          ListTile(leading: const Icon(Icons.remove), title: const Text("Egreso"), onTap: () => _abrirDialogo("egreso")),
        ],
      ),
    );
  }

  void _abrirDialogo(String tipo) {
    Navigator.pop(context);
    TextEditingController mC = TextEditingController();
    TextEditingController dC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Agregar $tipo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: mC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto")),
            TextField(controller: dC, decoration: const InputDecoration(labelText: "Descripción")),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // ignore: avoid_print
              print("monto registrado: ${mC.text}");
              String res = await _logic.registrarMovimiento(
                montoRaw: mC.text, descripcion: dC.text, tipo: tipo, frecuencia: 'ninguna', usuarioId: idUsuario,
              );

              // ignore: avoid_print
              print("Resultado del backend: $res");
              await _recargarDatos();
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

}