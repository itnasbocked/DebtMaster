import 'package:flutter/material.dart';
import '../logic/notification_service.dart';

class TarjetasScreen extends StatelessWidget {
  const TarjetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Módulo de Tarjetas\n(En Construcción)", 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)
            ),
            const SizedBox(height: 60),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              label: const Text(
                "Probar Notificación (10 seg)", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              onPressed: () async {
                debugPrint("--- BOTÓN PRESIONADO ---");

                DateTime fecha = DateTime.now();

                try {
                  DateTime fechaPrueba = DateTime.now().add(const Duration(seconds: 10));
                  NotificationService().programarNotificacion(
                    999,
                    "Prueba",
                    "Si ves esto, el plugin funciona",
                    fechaPrueba
                  );
                  fecha = fechaPrueba;
                } catch (e) {
                  debugPrint("ERROR EN EL SERVICIO: $e");
                }

                //SNACKBAR TEMPORAL SOLO PARA COMPROBACIÓN DE ENVÍO DE MENSAJES
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Ahora: ${DateTime.now()}\nFecha: $fecha"),
                      backgroundColor: const Color(0xFF22C55E),
                      duration: const Duration(seconds: 4),
                    )
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}