import 'package:flutter/material.dart';

double _paddingCenterOnScreen(BuildContext context) {
  if (MediaQuery.of(context).size.width > 960.0) {
    return 90;
  }
  else {
    return 20;
  }
}

double _paddingLeftOnScreen(BuildContext context) {
  if (MediaQuery.of(context).size.width > 960.0) {
    return 50;
  }
  else {
    return 20;
  }
}

class ChecklistPage extends StatelessWidget {
	const ChecklistPage({super.key});

  @override
	Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 640.0){
      return Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Center(
                child: Text("Equipaggiamento", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black))
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Center(
                child: Text("Tutto ciò che è utile portare quando si va a funghi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 50, 0, 30),
              child: const Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Center(
                              child: Text("Abbigliamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("1. Scarpe comode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("2. Scarponi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("3. Calze lunghe", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("4. Pantaloni lunghi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("5. Cintura", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("6. Maglietta", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("7. Maglia lunga", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("8. K-Way / Impermeabile", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("9. Giacca", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("10. Vestiti di ricambio (maglietta, felpa ...)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("11. Asciugamano", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("12. Cappello", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                          ]
                        )
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Center(
                              child: Text("Attrezzi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("1. Cellulare con mappa", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("2. Gerla", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("3. Racchette / Bastone", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("4. Uno o più coltelli", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("5. Marsupio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("6. Borse di stoffa o di rete", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("7. Carta dei sentieri", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("8. Permessi / Licenze", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("9. Accendino", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("10. Bussola con batterie", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("11. Power bank", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("12. Go pro", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("13. Borsa impermeabile per il portafoglio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("14. Cassette di plastica", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                          ]
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Center(
                              child: Text("Cura della persona", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("1. Acqua", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("2. Cibo (panini, cracker ...)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("3. Salviette igenizzanti", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("4. Amuchina", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Center(
                                child: Text("5. Scottex o fazzoletti", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                              )
                            ),
                          ],
                        )
                      )
                    ],
                  )
                ],
              ),
            )
          ]
        )
      );
    }
    else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Center(
                child: Text("Equipaggiamento", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black))
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Center(
                child: Text("Tutto ciò che è utile portare quando si va a funghi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 30, 0, 30),
              child: const Column(
                children: [
                  Center(
                    child: Text("Abbigliamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("1. Scarpe comode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("2. Scarponi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("3. Calze lunghe", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("4. Pantaloni lunghi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("5. Cintura", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("6. Maglietta", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("7. Maglia lunga", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("8. K-Way / Impermeabile", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("9. Giacca", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("10. Vestiti di ricambio (maglietta, felpa ...)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("11. Asciugamano", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("12. Cappello", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Center(
                      child: Text("Attrezzi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("1. Cellulare con mappa", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("2. Gerla", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("3. Racchette / Bastone", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("4. Uno o più coltelli", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("5. Marsupio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("6. Borse di stoffa o di rete", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("7. Carta dei sentieri", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("8. Permessi / Licenze", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("9. Accendino", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("10. Bussola con batterie", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("11. Power bank", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("12. Go pro", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("13. Borsa impermeabile per il portafoglio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("14. Cassette di plastica", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Center(
                      child: Text("Cura della persona", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("1. Acqua", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("2. Cibo (panini, cracker ...)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("3. Salviette igenizzanti", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("4. Amuchina", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Center(
                      child: Text("5. Scottex o fazzoletti", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                    )
                  ),
                ]
              )
            )
          ],
        ),
      );
    }
  }

}