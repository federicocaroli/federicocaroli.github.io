import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect/multiselect.dart';
import 'server.dart';
import 'tab_bar.dart';

class MeteoPage extends StatefulWidget {
  const MeteoPage({
    super.key
	});

	@override
	State<MeteoPage> createState() => _MeteoPagePageState();
}

class _MeteoPagePageState extends State<MeteoPage> {
	
	TextEditingController dateInput = TextEditingController();
	int startTimestamp = -1;
	int endTimestamp = -1;
  List<String> selectedStations = [];
  List<String> availableStations = [];
  Map<String, dynamic> stationsData = {};

	@override
	void initState() {
		super.initState();
		startTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round();
		endTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round() + 86400;
		dateInput.text = 'Da ${DateFormat('dd/MM/yyyy').format(DateTime.now())} a ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'; //set the initial value of text field
    Server.getStationsInfo().then<void>((result) {
      if (mounted){
        setState(() {
          availableStations = result.keys.toList();
        });
      }
    }).catchError((error) async {
      if (error is AuthenticationException){
        Server.signOut();
        await showDialog(context: context, 
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Attenzione'),
            content: const Text(
              'Login scaduto. Effettuare nuovamente il login.'
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
        if(mounted){
          Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
        }
      }
      else{
        print(error);
        await showDialog(context: context, 
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Attenzione'),
            content: const Text(
              'Errore sconosciuto durante il caricamento delle stazioni.'
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
      }
    });
	}

  @override
  void dispose(){
    dateInput.dispose();
    super.dispose();
  }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Column(
				children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.black)),
              ),
              height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 320,
						      child:
                    TextField(
                      controller: dateInput,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today), //icon of text field
                        labelText: "Periodo" //label text of field
                      ),
                      readOnly: true,
                      //set it true, so that user will not able to edit text
                      onTap: () async {
                        DateTimeRange? pickedPeriod = await showDateRangePicker(
                          context: context,
                          locale: const Locale('it', 'IT'),
                          firstDate: DateTime(2023, 5, 1),
                          lastDate: DateTime.now(),
                          initialEntryMode: DatePickerEntryMode.calendarOnly,
                          builder: (context, child){
                            return Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 50.0),
                                  child: SizedBox(
                                    height: 600,
                                    width: 700,
                                    child: child,
                                  ),
                                ),
                              ],
                            );
                          }
                        );

                        if (pickedPeriod != null && startTimestamp != (pickedPeriod.start.millisecondsSinceEpoch/1000).round() && endTimestamp != ((pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400)) {
                          String formattedDate = 'Da ${DateFormat('dd/MM/yyyy').format(pickedPeriod.start)} a ${DateFormat('dd/MM/yyyy').format(pickedPeriod.end)}';
                          if (mounted){
                            setState(() {
                              dateInput.text = formattedDate;
                              startTimestamp = (pickedPeriod.start.millisecondsSinceEpoch/1000).round();
                              endTimestamp = (pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400;
                            });
                          }
                        } 
                      }
                    )
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 500,
                  child: DropDownMultiSelect(
                      options: availableStations,
                      selectedValues: selectedStations,
                      onChanged: (list){
                        if (mounted){
                          setState(() {
                            selectedStations = list;
                          });
                        }
                      },
                      whenEmpty: 'Seleziona le stazioni',
                    ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 250,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    onPressed: (){
                      if (selectedStations.isNotEmpty){
                        Server.getStationsData(startTimestamp, endTimestamp, selectedStations).then((result) {
                          if (mounted){
                            setState(() {
                              stationsData = result;
                            });
                          }
                        }).catchError((error) async {
                          if (error is AuthenticationException){
                            Server.signOut();
                            await showDialog(context: context, 
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: const Text('Attenzione'),
                                content: const Text(
                                  'Login scaduto. Effettuare nuovamente il login.'
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      textStyle: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              );
                            });
                            if(mounted){
                              Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                            }
                          }
                          else{
                            print(error);
                            await showDialog(context: context, 
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: const Text('Attenzione'),
                                content: const Text(
                                  'Errore scoccuro durante il caricamento dei dati.'
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      textStyle: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              );
                            });
                          }
                        });
                      }
                    },
                    child: const Text("Cerca", style: TextStyle(color: Colors.white, fontSize: 20))
                  )
                )
                ]
              ),
            ),
            Expanded(
              child: TabbarStations(stationsData: stationsData),
            )
				],
			),
		);
	}
}
