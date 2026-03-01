import 'package:flutter/material.dart';

class MetaDetalleScreen extends StatelessWidget {
  const MetaDetalleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "PC gamer 👾",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "65% completado",
                style: TextStyle(
                    color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // GRAFICA MESES
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset:
                          const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: List.generate(
                        6,
                        (index) => Column(
                          children: [
                            Container(
                              height: 100,
                              width: 18,
                              decoration:
                                  BoxDecoration(
                                color: index == 3
                                    ? const Color(
                                        0xFF22C55E)
                                    : Colors
                                        .grey.shade300,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            20),
                              ),
                            ),
                            const SizedBox(
                                height: 8),
                            const Text(
                              "Ene",
                              style:
                                  TextStyle(
                                      fontSize:
                                          12),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Aportaciones mensuales",
                style: TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: ListView(
                  children: const [
                    AporteItem(
                        mes: "Enero",
                        monto: "+\$70"),
                    AporteItem(
                        mes: "Febrero",
                        monto: "+\$70"),
                    AporteItem(
                        mes: "Marzo",
                        monto: "+\$70"),
                    AporteItem(
                        mes: "Abril",
                        monto: "+\$70"),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AporteItem extends StatelessWidget {
  final String mes;
  final String monto;

  const AporteItem(
      {super.key,
      required this.mes,
      required this.monto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(mes),
          Text(
            monto,
            style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight:
                    FontWeight.bold),
          ),
        ],
      ),
    );
  }
}