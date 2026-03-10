import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/meta_model.dart';
import '../data/database/database_helper.dart';

class MetasScreen extends StatefulWidget{
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen>{
  List <Meta> metas = [];
  final Color primaryBlue = const Color(0xFF2563EB);    // Azul Principal
  final Color secondaryGreen = const Color(0xFF6BC88E); // Verde Secundario

  final int idUsuarioActual = 1;

  @override void initState() {
    super.initState();
    _cargarMetas();
  }
}

  Future<void> _cargarMetas() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('meta', where: 'usuario_id = ?', whereArgs: [idUsuarioActual]);
    setState((){
      metas = result.map((map) => Meta.fromMap(map)).toList();
    });

  Future<void> _guardarNuevaMeta(Meta nuevaMeta) async {
    final db = await DatabaseHelper.instance.database;
    final db.insert('meta', nuevaMeta.toMap());
    _cargarMetas();
  }

  Future<void> _abonarMeta(Meta meta, int centavosAhorro) async {
    final db = await DatabaseHelper.instance.database;
    int nuevoMonto = meta.montoActual + cantidadCentavos;
    if (nuevoMonto > meta.montoObjetivo) nuevoMonto = meta.montoObjetivo; // Tope al 100%

    await db.update('meta', {'monto_actual': nuevoMonto}, where: 'id = ?', whereArgs: [meta.id]);
    _cargarMetas();
  }

  // --- INTERFAZ GRÁFICA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text("Metas", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.black, size: 30),
            onPressed: _mostrarDialogoNuevaMeta,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Objetivos activos", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: metas.length + 1, // +1 para la tarjeta de "Crear nueva"
                itemBuilder: (context, index) {
                  if (index == metas.length) return _buildBotonCrearMeta();
                  return _buildTarjetaMeta(metas[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _mostrarDialogoNuevaMeta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTarjetaMeta(MetaAhorro meta) {
    double progreso = meta.montoObjetivo == 0 ? 0 : meta.montoActual / meta.montoObjetivo;
    int porcentaje = (progreso * 100).toInt();

    return GestureDetector(
      onTap: () => _mostrarDialogoAbono(meta), // Tocar la tarjeta para añadirle dinero
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
                valueColor: AlwaysStoppedAnimation(successGreen),
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

  // --- DIÁLOGOS DE CAPTURA ---
  void _mostrarDialogoNuevaMeta() {
    TextEditingController nC = TextEditingController();
    TextEditingController mC = TextEditingController();
    TextEditingController iC = TextEditingController(text: "👾"); // Emoji por defecto

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva Meta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: iC, decoration: const InputDecoration(labelText: "Icono (Emoji)")),
            TextField(controller: nC, decoration: const InputDecoration(labelText: "Nombre (Ej: PC Gamer)")),
            TextField(controller: mC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Objetivo (\$)")),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              double monto = double.tryParse(mC.text) ?? 0;
              if (monto > 0 && nC.text.isNotEmpty) {
                _guardarNuevaMeta(MetaAhorro(
                  usuarioId: idUsuarioActual,
                  nombre: nC.text,
                  montoObjetivo: (monto * 100).round(),
                  fechaLimite: DateTime.now().add(const Duration(days: 180)), // 6 meses por defecto para MVP
                  icono: iC.text,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoAbono(MetaAhorro meta) {
    TextEditingController aC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Abonar a ${meta.nombre}"),
        content: TextField(
          controller: aC, 
          keyboardType: TextInputType.number, 
          decoration: const InputDecoration(labelText: "Cantidad a sumar (\$)", prefixText: "\$ ")
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              double abono = double.tryParse(aC.text) ?? 0;
              if (abono > 0) {
                _abonarAMeta(meta, (abono * 100).round());
                Navigator.pop(context);
              }
            },
            child: const Text("Abonar"),
          )
        ],
      ),
    );
  }
}