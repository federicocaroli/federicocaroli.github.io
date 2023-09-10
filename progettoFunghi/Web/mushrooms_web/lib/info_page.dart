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

class InfoPage extends StatelessWidget {
	const InfoPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.white,
			body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Center(
              child: Text("MushroomsWeb", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.lightGreen))
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Center(
              child: Text("Applicazione per la raccolta dati sulle specie fungine", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: Center(
              child: Text("Mappa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 20, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("È possibile visualizzare sulla mappa la posizione delle stazioni meteorologiche di cui raccogliamo i dati.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 5, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("Per ogni stazione meteorologica sono specificati: la relativa altitudine, data-ora dell'ultimo dato raccolto e i sensori disponibili.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 15, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("La mappa è interattiva, perciò è possibile spostarsi a piacimento in tutto il mondo ed ingrandire/rimpicciolire la mappa così da poter visualizzare più/meno dettagli del territorio.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: Center(
              child: Text("Dati", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 20, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("È possibile visualizzare i dati di una o più stazioni meteorologiche.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 5, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("I parametri da configurare sono due: periodio temporale di interesse e, attraverso l'apposito elenco a scomparsa, le stazioni.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 15, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("Sulla base della durata del periodo d'interesse i dati delle varie stazioni vengono raggruppati in intervalli di durata variabile.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 5, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("Periodo di durata minore od uguale a 3 giorni --> dati raggruppati in intervalli di 4 ore,", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 5, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("Periodo di durata minore od uguale a 7 giorni --> dati raggruppati in intervalli di 8 ore,", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingCenterOnScreen(context), 5, _paddingCenterOnScreen(context), 0),
            child: const Center(
              child: Text("Periodo di durata maggiore di 7 giorni --> dati raggruppati in intervalli di 24 ore.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
            )
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 40, _paddingLeftOnScreen(context), 0),
            child: const Text("Informazioni utili sui dati:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 20, _paddingLeftOnScreen(context), 0),
              child: const Text("Pioggia cumulata --> unità di misura: mm caduti nel periodo di riferimento", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Pioggia debole (1-2 mm/h; 4-8 mm/4h; 8-16 mm/8h, 24-48 mm/24h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Pioggia leggera (2-4 mm/h; 8-16 mm/4h; 16-32 mm/8h, 48-96 mm/24h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Pioggia moderata (4-6 mm/h; 16-24 mm/4h; 32-48 mm/8h, 96-144 mm/24h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Pioggia forte (6-10 mm/h; 24-40 mm/4h; 48-80 mm/8h, 144-240 mm/24h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Rovescio (10-30 mm/h; 40-120 mm/4h; 80-240 mm/8h, 240-720 mm/24h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Nubifragio (>30 mm/h; >120 mm/4h; >240 mm/8h, >720 mm/24h).", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 15, _paddingLeftOnScreen(context), 0),
              child: const Text("Temperatura dell'aria --> unità di misura: gradi celsius,", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 15, _paddingLeftOnScreen(context), 0),
              child: const Text("Umidità relativa dell'aria --> unità di misura: percentuale,", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 15, _paddingLeftOnScreen(context), 0),
              child: const Text("Velocità del vento --> unità di misura: km/h", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Vento calmo (0 km/h - 5 km/h)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Vento debole (6 km/h - 19 km/h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Vento moderato (20 km/h - 38 km/h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Vento forte (39 km/h - 61 km/h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Burrasca (62 km/h - 88 km/h),", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context) + 10, 5, _paddingLeftOnScreen(context), 0),
              child: const Text("\u2022 Tempesta (> 89 km/h).", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_paddingLeftOnScreen(context), 15, _paddingLeftOnScreen(context), 0),
            child: const Text("Direzione del vento --> unità di misura: gradi (0° - Nord, 90° - Est, 180° - Sud, 270° - Ovest).", style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          const SizedBox(height: 100)
        ]
      )
		);
	}
}