import 'package:flutter/material.dart';
// import '../data/database/database_helper.dart';
import '../data/models/ingresos-egresos.dart';
import '../logic/movimiento_controller.dart';

class IngresosEgresosScreen extends StatefulWidget {
  const IngresosEgresosScreen({super.key});

  @override
  State<IngresosEgresosScreen> createState() => _IngresosEgresosScreenState();
}

class HistorialScreen extends StatelessWidget {

  final List<Movimiento> movimientos;

  const HistorialScreen(this.movimientos, {super.key});

  bool esDelMesActual(DateTime fecha) {
    DateTime now = DateTime.now();
    return fecha.month == now.month && fecha.year == now.year;
  }

  @override
  Widget build(BuildContext context) {

    var listaMes = movimientos
        .where((m) => esDelMesActual(m.fecha))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Historial del Mes")),
      body: ListView.builder(
        itemCount: listaMes.length,
        itemBuilder: (_, index) {
          var m = listaMes[index];
          return ListTile(
            title: Text(m.descripcion ?? "Sin descripción"),
            subtitle: Text(m.fecha.toString()),
            trailing: Text(
              "\$${(m.monto / 100).toStringAsFixed(2)}",
              style: TextStyle(
                color: m.tipo == "ingreso"
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IngresosEgresosScreenState extends State<IngresosEgresosScreen> {
  
  final MovimientoController _logic = MovimientoController();
  List<Movimiento> movimientos = [];
  double balanceTotal = 0.0;
  int idUsuario = 1;
  
  final Color primaryBlue = const Color(0xFF2962FF);    // Azul Principal
  final Color secondaryGreen = const Color(0xFF00C853); // Verde Secundario
  final Color criticalRed = const Color(0xFFF44336);    // Rojo Crítico
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "DebtMaster",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryBlue),
              ),
              const SizedBox(height: 32),

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

      bottomNavigationBar: _buildBottomNav(),
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
    Color color = secondaryGreen;
    if (ratio > 0.8) {
      color = criticalRed;
    } else if (ratio > 0.5) {
      color = Colors.yellow.shade700;
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFE6E8EB), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: 70, height: 70,
            child: CircularProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: Colors.lightBlue,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Salud sobre ingresos", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(ratio * 100).toStringAsFixed(1)}% utilizado", style: TextStyle(color: Colors.grey.shade600)),
            ],
          )
        ],
      ),
    );
  }

int _selectedIndex = 2; 

Widget _buildBottomNav() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -5), // Sombra sutil hacia arriba
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        // Santiago: Aquí puedes meter la lógica de navegación por index
      },
      selectedItemColor: primaryBlue,      // Azul #2962FF
      unselectedItemColor: Colors.grey.shade400,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed, // Bloquea los iconos para que no "salten"
      items: const [
        // 1. Calendario
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined, size: 26),
          activeIcon: Icon(Icons.calendar_today, size: 26),
          label: "Calendario",
        ),
        // 2. Tarjetas (Pagos TDC)
        BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined, size: 28),
          activeIcon: Icon(Icons.credit_card, size: 28),
          label: "Tarjetas",
        ),
        // 3. Billetera (Dashboard principal)
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
          activeIcon: Icon(Icons.account_balance_wallet, size: 28),
          label: "Billetera",
        ),
        // 4. Metas (Objetivos de ahorro)
        BottomNavigationBarItem(
          icon: Icon(Icons.outlined_flag, size: 28),
          activeIcon: Icon(Icons.flag, size: 28),
          label: "Metas",
        ),
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  void _mostrarHistorial() => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialScreen(movimientos)));
}