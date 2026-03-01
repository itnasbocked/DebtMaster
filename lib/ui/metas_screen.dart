import 'package:flutter/material.dart';

class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2F6BFF),
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Metas",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Objetivos activos",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey),
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: const [
                        Text(
                          "PC gamer 👾",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        Text(
                          "65%",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Barra progreso
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 12,
                        backgroundColor:
                            Colors.grey.shade200,
                        color:
                            const Color(0xFF22C55E),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "\$6,500 / \$10,000",
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Vas excelente 👌",
                      style: TextStyle(
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Fecha límite: 25 Dic 2025",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // CREAR NUEVA META
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    "Crear nueva meta",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}