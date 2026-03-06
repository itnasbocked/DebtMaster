import 'package:flutter/material.dart';
import 'ingresos_egresos_screen.dart'; // Para la navegación

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // --- CONTROLADORES ---
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- PALETA DE COLORES (Sincronizada con Ingresos/Egresos) ---
  final Color primaryBlue = const Color(0xFF2962FF);
  final Color backgroundColor = const Color(0xFFF2F4F7);
  final Color labelColor = const Color(0xFF4B4F54); // Texto secundario de la guía

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO / TÍTULO ---
              Text(
                "DebtMaster",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 40),

              // --- CONTENEDOR PRINCIPAL (ESTILO CARD) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Bienvenido",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // --- INPUT USUARIO ---
                    _buildInputLabel("Usuario"),
                    const SizedBox(height: 8),
                    _buildTextField(_userController, "Tu nombre de usuario", Icons.person_outline, false),

                    const SizedBox(height: 24),

                    // --- INPUT CONTRASEÑA ---
                    _buildInputLabel("Contraseña"),
                    const SizedBox(height: 8),
                    _buildTextField(_passController, "••••••••", Icons.lock_outline, true),

                    const SizedBox(height: 32),

                    // --- BOTÓN DE ENTRADA ---
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Santiago: Aquí conectamos con la pantalla que ya terminamos
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const IngresosEgresosScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "INICIAR SESIÓN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LINK SECUNDARIO ---
                    Center(
                      child: TextButton(
                        onPressed: () {}, // Futuro: Pantalla de registro
                        child: Text(
                          "¿No tienes cuenta? Regístrate",
                          style: TextStyle(
                            color: primaryBlue.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA LIMPIEZA DE CÓDIGO ---

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: labelColor,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPass) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue.withOpacity(0.5)),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}